require 'i2c'

class Hih6130Sensor

  def initialize(path, address = 0x27)
    @device = I2C.create(path)
    @address = address
  end

  def fetch_humidity_temperature
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    return "status=#{status}", "Humidity=#{hum* 6.10e-3}", "Temperature=#{temp * 1.007e-2 - 40.0}","\n"
  end

end

sensor = Hih6130Sensor.new('/dev/i2c-1')

loop do
  puts sensor.fetch_humidity_temperature
  sleep(2)
end
