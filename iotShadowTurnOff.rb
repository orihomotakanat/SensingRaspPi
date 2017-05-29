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

  def turnOffAircon
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      puts "waiting turnoffCommand..."
      client.subscribe(@topicTurnedOff)
      client.get #ここでturnOn.sh
    end #MQTT end
  end #def turnOffAircon end

end #class RasPiIotShadow end


#Following are processed codes
sensingWithRaspi = RasPiIotShadow.new('/dev/i2c-1')

Process.daemon
#turnOffAircon process
loop do
    sensingWithRaspi.turnOffAircon
    puts "Turn Off"#exec .sh comand (airconOff)
end
