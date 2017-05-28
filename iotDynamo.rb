require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

class RasPiIot
  def initialize(path, address = 0x27)
    #AWSIoT Read yaml
    iotconfig = YAML.load_file("iot.yml")
    @host = iotconfig["iotConfig"]["host"]
    @topic = iotconfig["iotConfig"]["topic"]
    @port = iotconfig["iotConfig"]["port"]
    @certificate_path = iotconfig["iotConfig"]["certificatePath"]
    @private_key_path = iotconfig["iotConfig"]["privateKeyPath"]
    @root_ca_path = iotconfig["iotConfig"]["rootCaPath"]
    @thing = iotconfig["iotConfig"]["thing"]
    #i2c
    @device = I2C.create(path)
    @address = address

    @time = 0
    @temp = 0
  end

  #fetch Humidity & Temperature with i2c device
  def fetch_humidity_temperature
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    @time = Time.now.to_i
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    @temp = temp * 1.007e-2 - 40.0
    outputjson = JSON.generate({"time" => @time, "temp" => @temp})
    #return "time=#{time}","status=#{status}", "Humidity=#{hum* 6.10e-3}", "Temperature=#{temp * 1.007e-2 - 40.0}","\n"
    #return "{\"time\":\"#{time}\",\"temp\":\"#{temperature}\"}"
    return outputjson
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
sensingWithRaspi = RasPiIot.new('/dev/i2c-1')

Process.daemon

loop do
  puts sensingWithRaspi.fetch_humidity_temperature
  sensingWithRaspi.outputData
  sleep(180)
end
