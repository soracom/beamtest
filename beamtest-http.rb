require 'sinatra'
require 'json'
require 'pp'
require 'digest/sha2'
require 'base64'

set :bind, '0.0.0.0'

# シグネチャの検証ロジック
def verify_signature(env, secret = 'topsecret')
  headers = env.select{|k,v| k=~/HTTP_X_SORACOM/}.map do |k, v|
    "#{k}=#{v}"
  end.join("\n")
  if env['HTTP_X_SORACOM_SIGNATURE_VERSION'] == '20150901'
    string_to_sign = request.env.select{|k,v| k=~/HTTP_X_SORACOM/ && !(k=~/HTTP_X_SORACOM_SIGNATURE/)}
      .map{|k,v| "#{k}=#{v}"}.sort().join()
  elsif env['HTTP_X_SORACOM_SIGNATURE_VERSION'] == '20151001'
    string_to_sign = request.env.select{|k,v| k=~/HTTP_X_SORACOM/ && !(k=~/HTTP_X_SORACOM_SIGNATURE/)}
      .map{|k,v| "#{k.sub(/HTTP_/,'').gsub(/_/,'-').downcase()}=#{v}"}.sort().join()
  end
  calculated_signature = Digest::SHA256.hexdigest secret + string_to_sign
  result = (calculated_signature == env['HTTP_X_SORACOM_SIGNATURE'])
  log = <<EOS
= Signature Verification =
Pre shared key = #{secret}

stringToSign:
#{string_to_sign}

calculated_signature:
SHA256('#{secret}'+stringToSign) = #{calculated_signature}

provided_signature:
#{env['HTTP_X_SORACOM_SIGNATURE']}

signature:
#{(result)? 'Match!':'Does not match...'}
EOS
  return { result: result, log: log }
end

# 普通にブラウザなどでアクセスした場合
get '/' do
  puts request.env.map{|k,v| "#{k}=#{v}\n"}.join
  user_agent = request.env['HTTP_USER_AGENT'] || 'curl'
  template = user_agent.match(/curl/i)? :curl : :dump
  if user_agent.match(/curl/i)
    content_type 'text/plain;charset=utf8'
  end
  if request.env['HTTP_X_SORACOM_IMSI']
    log=""
    result=200
    if request.env['HTTP_X_SORACOM_SIGNATURE']
      res = verify_signature request.env, (params[:secret] || "topsecret")
      puts res[:log]
      log = res[:log]
      result = res[:result]
    end
    puts "Hello SORACOM Beam Client IMSI:#{request.env['HTTP_X_SORACOM_IMSI']}"
    status 403 if result == false
    erb template, locals: { greet: "Hello SORACOM Beam Client #{request.env['HTTP_X_SORACOM_IMSI']} !", env: request.env, verify_log: log}
  else
    puts 'Hello unknown client ...'
    erb template, locals: { greet: 'Hello Unknown Client...', env: request.env, verify_log:'' }
  end
end

# データがポストされた場合
post '/' do
  puts request.env.map{|k,v| "#{k}=#{v}\n"}.join
  data = (request.env['CONTENT_TYPE'] == 'application/json')? JSON.parse(request.body.read) : request.body.read
  pp data
  if data['payload']
    output = "#{data} => #{Base64.decode64 data['payload']}"
  else
    output = "#{data}"
  end
  user_agent = request.env['HTTP_USER_AGENT'] || 'curl'
  if user_agent.match(/curl/i)
    content_type 'text/plain;charset=utf8'
  end

  if request.env['HTTP_X_SORACOM_IMSI']
    if request.env['HTTP_X_SORACOM_SIGNATURE']
      res = verify_signature request.env
      puts res[:log]
      if res[:result]
        return "Access Authorized: #{output}"
      else
        status 403
        return "Access Denied: Invalid Signature\n#{res[:log]}"
      end
    end
    puts "Hello SORACOM Beam Client IMSI:#{request.env['HTTP_X_SORACOM_IMSI']}"
  end
  "Success: #{output}"
end

get '/dumpenv*' do
  request.env.select{|k,v| k=~/HTTP_/}.map{|k,v| "#{k}=#{v}\n"}.join
end
post '/dumpenv*' do
  request.env.select{|k,v| k=~/HTTP_/}.map{|k,v| "#{k}=#{v}\n"}.join
end
