require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

class RasPiIotShadow
  def initialize
    #AWSIoT Read yaml
    iotconfig = YAML.load_file("iotShadow.yml")
    @host = iotconfig["iotShadowTestConfig"]["host"]
    @topic = iotconfig["iotShadowTestConfig"]["topic"]
    @port = iotconfig["iotShadowTestConfig"]["port"]
    @certificate_path = iotconfig["iotShadowTestConfig"]["certificatePath"]
    @private_key_path = iotconfig["iotShadowTestConfig"]["privateKeyPath"]
    @root_ca_path = iotconfig["iotShadowTestConfig"]["rootCaPath"]
    @thing = iotconfig["iotShadowTestConfig"]["thing"]

    @messageHello = "Hello"
    @messageWorld = "World"
  end

  #fetch Humidity & Temperature with i2c device
  def pubMessageTest
    outputjson = "Turn on Aircon"#JSON.generate({"Ruby" => @messageHello, "Swift" => @messageWorld})
    return outputjson
  end

#Output data to AWSIoT
  def outputData
    inputData = pubMessageTest
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
    client.publish(@topic, inputData)
    end
  end
end
  #Setting of output "iotTempLog_${timestamp()}.csv"

#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new

#loop do
  puts sensingWithRaspi.pubMessageTest
  sensingWithRaspi.outputData

#end
