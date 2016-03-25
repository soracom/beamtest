require 'socket'
require 'digest/sha2'
gs = TCPServer.open(1234)
addr = gs.addr
addr.shift
printf("server is on %s\n", addr.join(':'))
psk = 'topsecret'

while true
  Thread.start(gs.accept) do |s|
    print(s, " is accepted\n")
    greeting = s.gets
    if greeting =~ /^(im.i.+\ timestamp=\d+);signature=([0-9a-f]+)/ # 署名済接続の場合
      string_to_sign = $1
      signature = $2
      calculated_signature = Digest::SHA256.hexdigest "topsecret"+string_to_sign
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
	puts reply
	s.write reply
      else
        p greeting
        p string_to_sign
        p signature
        p calculated_signature
      	s.write("ERROR: The request signature we calculated does not match the signature you provided.\n")
	sleep 3
        s.close
      end
    elsif greeting =~ /^im.i=(\d+)/ # IMSIヘッダのみの場合
      reply = "Hello Soracom Beam Client! : #{greeting.chomp}\n"
      puts reply
      s.write reply
    else
      s.write($_)
    end
    while s.gets
      s.write($_)
    end
    print(s, " is gone\n")
    s.close
  end
end
