require 'fileutils'

def signalGetter(filename)
  startReceiveCommand = "bto_advanced_USBIR_cmd -r" #受信開始
  stopReceiveCommand = "bto_advanced_USBIR_cmd -s" #受信停止
  saveCommand = "bto_advanced_USBIR_cmd -g | tee #{filename}" #受信した信号を保存
  givePermCommand = "chmod +x #{filename}"

  startReceive = system(startReceiveCommand)
  sleep(5)
  stopReceive = system(stopReceiveCommand)
  save = system(saveCommand)
end

signalGetter("xxx.txt") #turnOn.txt or turnOff.txt
