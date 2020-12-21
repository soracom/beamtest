require 'socket'
require 'digest/sha2'
require 'logger'

STDOUT.sync = true
DEBUG = false

class MyLogger
  def initialize()
    @logger = Logger.new(STDOUT)
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{severity}] #{msg}\n"
    end
  end

  def log(level, peeraddr, message)
    if peeraddr.nil?
      @logger.log(level, "#{message}")
    else
      @logger.log(level, "#{peeraddr.to_s} #{message}")
    end
  end
end

gs = TCPServer.open(1234)
addr = gs.addr
addr.shift
psk = 'topsecret'
logger = MyLogger.new()
logger.log(Logger::INFO, nil, "server is on #{addr.join(':')}")


while true
  Thread.start(gs.accept) do |s|
    logger = MyLogger.new()

    peeraddr = s.peeraddr
    logger.log(Logger::INFO, peeraddr, "is accepted")
    greeting = s.gets
    logger.log(Logger::DEBUG, peeraddr, greeting.dump)
    if greeting =~ /^(.+\ timestamp=\d+);signature=([0-9a-f]+)/ # 署名済接続の場合
      string_to_sign = $1
      signature = $2
      calculated_signature = Digest::SHA256.hexdigest psk+string_to_sign
      if calculated_signature == signature
        reply = verifylog = <<EOS
--- SIGNATURE VERIFICATION
#{greeting}
string_to_sign: #{string_to_sign}
calculated_signature: sha256(string_to_sign) = #{calculated_signature}
provided_signature: #{signature}
---
Hello Authorized Soracom Beam Client! :#{string_to_sign}
EOS
        logger.log(Logger::INFO, peeraddr, reply)
        s.write reply
      else
        logger.log(Logger::INFO, peeraddr, greeting.dump)
        logger.log(Logger::INFO, peeraddr, string_to_sign.dump)
        logger.log(Logger::INFO, peeraddr, signature.dump)
        logger.log(Logger::INFO, peeraddr, calculated_signature.dump)
      	s.write("ERROR: The request signature we calculated does not match the signature you provided.\n")
        sleep 3
        s.close
      end
    elsif greeting =~ /^(imei=undefined\s)?[A-Za-z]+=(\d+)/ # 署名がない場合
      reply = "Hello Soracom Beam Client! : #{greeting.chomp}\n"
      logger.log(Logger::INFO, peeraddr, reply.chomp)
      s.write reply
    else
      s.write($_)
    end
    while s.gets
      logger.log(Logger::DEBUG, peeraddr, $_.dump)
      s.write($_)
    end
    logger.log(Logger::INFO, peeraddr, "is gone")
    s.close
  end
end
