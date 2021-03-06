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

    #iOS
    @receiveiOS = iotconfig["iotShadowConfig"]["receiveiOS"]
    @topiciOS = iotconfig["iotShadowConfig"]["topiciOS"]
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

    @temp = (temp * 1.007e-2 - 40.0).round(2)
    @humidity  = (hum * 6.10e-3).round(2)
    outputjson = JSON.generate({"temp" => @temp, "humidity" => @humidity})
    return outputjson
  end #def fetch_humidity_temperature end

  #Output data to iosApp via AWSIoT
  def toiOS
    inputData = fetchData
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.subscribe(@receiveiOS)
      client.get
      client.publish(@topiciOS, inputData) #publish room-temperature to AWSIoT
    end #MQTT end
  end #def toiOS

end #class RasPiIotShadow end


#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new('/dev/i2c-1')

Process.daemon
loop do
    puts sensingWithRaspi.fetchData
    sensingWithRaspi.toiOS
end
