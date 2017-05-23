require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

class RasPiIotS3
  def initialize(path, address = 0x27)
    #AWSIoT Read yaml
    iotconfig = YAML.load_file("iot.yml")
    @host = iotconfig["iotS3Config"]["host"]
    @topic = iotconfig["iotS3Config"]["topic"]
    @port = iotconfig["iotS3Config"]["port"]
    @certificate_path = iotconfig["iotS3Config"]["certificatePath"]
    @private_key_path = iotconfig["iotS3Config"]["privateKeyPath"]
    @root_ca_path = iotconfig["iotS3Config"]["rootCaPath"]
    @thing = iotconfig["iotS3Config"]["thing"]
    #i2c
    @device = I2C.create(path)
    @address = address
  end

  #fetch Humidity & Temperature with i2c device
  def fetch_humidity_temperature
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    time = Time.now.getlocal
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    temperature = temp * 1.007e-2 - 40.0

    #return "time=#{time}","status=#{status}", "Humidity=#{hum* 6.10e-3}", "Temperature=#{temp * 1.007e-2 - 40.0}","\n"
    return "{\"time\":\"#{time}\",\"temp\":\"#{temperature}\"}"
  end

  #Output data to AWSIoT
  def outputData
    inputData = fetch_humidity_temperature
    MQTT::Client.connect(host:@host, port: 8883, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.publish(@topic, inputData)
    end
  end
end
  #Setting of output "iotTempLog_${timestamp()}.csv"

#Following are processed codes
sensingWithRaspi = RasPiIotS3.new('/dev/i2c-1')

loop do
  puts sensingWithRaspi.fetch_humidity_temperature
  sensingWithRaspi.outputData
  sleep(3)
end
