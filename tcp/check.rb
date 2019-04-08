#!/usr/bin/ruby
STDOUT.sync = true
require "socket"
sock = TCPSocket.open("127.0.0.1", 1234)
sock.write("PING\n")
while sock.gets
  puts $_
  break if($_ == "PING\n")
end
sock.close