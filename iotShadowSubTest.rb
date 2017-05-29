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


#Output data to AWSIoT
  def outputData
    inputDataOn = "Send on"
    inputDataOff = "Send Off"
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
    #client.publish(@topic, inputData)
    client.publish(@topicOff, inputDataOn)
    client.publish(@topicOn, inputDataOff)
    puts "Waiting 5 sec"
    sleep(5)
    puts client.subscribe(@topicOff)
    puts client.subscribe(@topicOn)
    puts client.get
    end
  end
end


#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new

loop do
sensingWithRaspi.outputData
end
