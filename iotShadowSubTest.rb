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

    @topicOn = iotconfig["iotAirconTestCongig"]["topicOn"]
    @topicOff = iotconfig["iotAirconTestCongig"]["topicOff"]

    @messageHello = "Hello"
    @messageWorld = "World"
  end

  #fetch Humidity & Temperature with i2c device
  def pubMessageTest
    outputjson = "Turn off Aircon"#JSON.generate({"Ruby" => @messageHello, "Swift" => @messageWorld})
    return outputjson
  end

#Output data to AWSIoT
  def outputData
    inputData = pubMessageTest
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
    #client.publish(@topic, inputData)
    client.publish(@topicOff, inputData)
    client.subscribe(@topicOff)
    puts client.get
    end
  end
end


#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new


puts sensingWithRaspi.pubMessageTest
sensingWithRaspi.outputData
