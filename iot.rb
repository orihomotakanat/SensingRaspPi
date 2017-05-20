# require 'dht-sensor-ffi'
require 'aws_iot_device'
require 'i2c'
# require 'optparse'
require 'json'
require 'pp'
require 'date'



class RasPiIot
  def initialize(path, address = 0x27)
    #AWSIoT
    @host = "region.amazonaws.com"
    @port = 8883
    @certificate_path = "certificate.pem.crt"
    @private_key_path = "private.pem.key"
    @root_ca_path     = "root-CA.crt"
    @thing = "thing's name"

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
    return "{\"Items\":{\"time\":\"#{time}\",\"temp\":\"#{temperature}\"}}"
  end

  #Output data to AWSIoT
  def outputData
    my_shadow_client = AwsIotDevice::MqttShadowClient::ShadowClient.new
    my_shadow_client.configure_endpoint(@host, @port)
    my_shadow_client.configure_credentials(@root_ca_path, @private_key_path, @certificate_path)
    my_shadow_client.create_shadow_handler_with_name(@thing, true)

    my_shadow_client.connect


=begin
    filter_callback = Proc.new do |message|
      puts "Executing the specific callback for topic: #{message.topic}\n##########################################\\n"
    end

    delta_callback = Proc.new do |delta|
      message = JSON.parse(delta.payload)
      puts "Catching a new message : #{message["state"]["message"]}\n##########################################\n"
    end


    my_shadow_client.register_delta_callback(delta_callback)

    while true
      pp temp_and_humi = generate_json
      my_shadow_client.update_shadow(temp_and_humi, filter_callback, 5)

      sleep(2)
    end
=end

    inputData = fetch_humidity_temperature
    my_shadow_client.update_shadow(inputData)

    my_shadow_client.disconnect
  end

end


#Following are processed codes
sensingWithRaspi = RasPiIot.new('/dev/i2c-1')

loop do
  puts sensingWithRaspi.fetch_humidity_temperature
  sensingWithRaspi.outputData
  sleep(2)
end
