require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'
require 'timeout'

class RasPiIotShadow
  attr_accessor :airconmode
  def initialize(path, address = 0x27, airconmode= 0)
    #i2c
    @device = I2C.create(path)
    @address = address
    @time = 0
    @temp = 0
    @humidity = 0

    #airconSetting
    @setTemp = 20
    @airconmode = airconmode #TunrnedOnAircon -> 1, TurnedOffAircon -> 0

    iotconfig = YAML.load_file("iot.yml")
    #toKinesis and tempChecker
    @host = iotconfig["iotShadowConfig"]["host"]
    @topic = iotconfig["iotShadowConfig"]["topic"]
    @port = iotconfig["iotShadowConfig"]["port"]
    @certificate_path = iotconfig["iotShadowConfig"]["certificatePath"]
    @private_key_path = iotconfig["iotShadowConfig"]["privateKeyPath"]
    @root_ca_path = iotconfig["iotShadowConfig"]["rootCaPath"]
    @thing = iotconfig["iotShadowConfig"]["thing"]

    #turnOnAircon and turnOffAircon
    @topicTurnedOn = iotconfig["airconConfig"]["topicOn"]
    @topicTurnedOff = iotconfig["airconConfig"]["topicOff"]
  end

  #fetch Humidity & Temperature with i2c device
  def dataChecker
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    @time = Time.now.to_i
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    @temp = temp * 1.007e-2 - 40.0
    @humidity  = hum * 6.10e-3

    if @temp <= @setTemp
      puts @airconmode = 0 #puts: For debug
    end #if @temp... end

    jsonToKinesis = JSON.generate({"datetime" => @time, "temp" => @temp, "humidity" => @humidity, "airconmode" => @airconmode})
    return jsonToKinesis
  end #def fetch_humidity_temperature end

  def airconmodeGetter
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.subscribe(@topic) #subscribe message of airconmode
      topic, @airconmode= client.get
      puts @airconmode
    end #MQTT end
  end #airconmodeGetter end

  #Output data to KinesisStream via AWSIoT
  def toKinesis
    inputData = dataChecker
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.publish(@topic, inputData) #publish room-temperature to AWSIoT
    end #MQTT end
  end #def toKinesis end

end #class RasPiIotShadow end


#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new('/dev/i2c-1')

#Process.daemon
#dataChecker and toKinesis process
loop do
  begin 
    Timeout.timeout(1) do #wait 1 sec nad if false -> call rescue
      sensingWithRaspi.airconmodeGetter
      puts "Received airconmode" + sensingWithRaspi.airconmode
    end
  rescue Timeout::Error
    puts "dataChecker" + sensingWithRaspi.dataChecker
    sensingWithRaspi.toKinesis
    puts "Lets go Kinesis"
  end
end
