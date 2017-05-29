require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

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
  def fetchData
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    @time = Time.now.to_i
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    @temp = temp * 1.007e-2 - 40.0
    @humidity  = hum * 6.10e-3
    outputjson = JSON.generate({"datetime" => @time, "temp" => @temp, "airconmode" => @airconmode})
    #return "time=#{time}","status=#{status}", "Humidity=#{hum* 6.10e-3}", "Temperature=#{temp * 1.007e-2 - 40.0}","\n"
    return outputjson
  end #def fetch_humidity_temperature end

  def dataChecker
    checkedTemp = JSON.parse
    if checkedTemp <= @setTemp 
      @airconmode = 0
    end
  end #def dataChecker

  #Output data to KinesisStream via AWSIoT
  def toKinesis
    inputData = fetchData
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.publish(@topic, inputData) #publish room-temperature to AWSIoT
    end #MQTT end
  end #def toKinesis end

  def turnOnAircon
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      puts "waiting turnonCommand.."
      client.subscribe(@topicTurnedOn)
      client.get #ここでturnOn.sh
      client.publish(@topicTurnedOn, "TurnOn") #For Debug
      @airconmode = 1
    end #MQTT end
  end #def turnOnAircon end

  def turnOffAircon
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      puts "waiting turnoffCommand..."
      client.subscribe(@topicTurnedOff)
      client.get #ここでturnOn.sh
      client.publish(@topicTurnedOff, "TurnOff") #For Debug
    @airconmode = 0
    end #MQTT end
  end #def turnOffAircon end

end #class RasPiIotShadow end


#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new('/dev/i2c-1')
=begin
  loop do
  if sensingWithRaspi.airconmode == 1
    puts "I'm pid2"
  end
  end
=end
  #turnOnAircon process
  loop do
    puts sensingWithRaspi.airconmode
    sensingWithRaspi.turnOnAircon
    puts sensingWithRaspi.airconmode = 1
  end
  #turnOffAircon process
  loop do
    puts sensingWithRaspi.airconmode
    sensingWithRaspi.turnOffAircon
    puts sensingWithRaspi.airconmode = 0
  end

=begin
#dataChecker and toKinesis process
loop do
  sensingWithRaspi.dataChecker
  puts sensingWithRaspi.airconmode
  sensingWithRaspi.toKinesis
end
=end
