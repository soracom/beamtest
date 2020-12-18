require 'sinatra'
require 'json'
require 'pp'
require 'digest/sha2'
require 'base64'
require 'logger'

set :bind, '0.0.0.0'
STDOUT.sync = true
DEBUG = false
logger = Logger.new(STDOUT)
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{severity}] #{msg}\n"
end
if DEBUG
  logger.level = Logger::DEBUG
else
  logger.level = Logger::INFO
end

# シグネチャの検証ロジック
def verify_signature(env, secret = 'topsecret')
  result = false
  message = []
  headers = request.env.select{|k,v| k=~/HTTP_X_SORACOM/}.map{ |k, v| "#{k}=#{v}" }.join("\n")
  if env['HTTP_X_SORACOM_SIGNATURE_VERSION'] == '20150901' # It has been removed from beam-proxy.
    string_to_sign = request.env.select{|k,v| k=~/HTTP_X_SORACOM/ && !(k=~/HTTP_X_SORACOM_SIGNATURE/)}
      .map{|k,v| "#{k}=#{v}"}.sort().join()
  elsif env['HTTP_X_SORACOM_SIGNATURE_VERSION'] == '20151001'
    string_to_sign = request.env.select{|k,v| k=~/HTTP_X_SORACOM/ && !(k=~/HTTP_X_SORACOM_SIGNATURE/)}
      .map{|k,v| "#{k.sub(/HTTP_/,'').gsub(/_/,'-').downcase()}=#{v}"}.sort().join()
  else
    message << "x-soracom-signature-version header is missing"
  end
  if string_to_sign != nil && string_to_sign.size > 0
    calculated_signature = Digest::SHA256.hexdigest secret + string_to_sign
  else
    message << "String to sign does not exist"
  end
  if calculated_signature
    result = (calculated_signature == env['HTTP_X_SORACOM_SIGNATURE'])
    logger.debug calculated_signature if result == false
    message << (result ? "Match!" : "Does not match...")
  end
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
#{message.join("\n")}
EOS
  return { result: result, log: log }
end

# 普通にブラウザなどでアクセスした場合
get '/' do
  logger.debug request.env.map{|k,v| "#{k}=#{v}\n"}.sort.join
  user_agent = request.env['HTTP_USER_AGENT'] || 'curl'
  template = user_agent.match(/curl/i)? :curl : :dump
  if user_agent.match(/curl/i)
    content_type 'text/plain;charset=utf8'
  end
  if request.env['HTTP_X_SORACOM_IMSI'] || request.env['HTTP_X_SORACOM_IMEI'] || request.env['HTTP_X_SORACOM_SIM_ID'] || request.env['HTTP_X_SORACOM_MSISDN']
    log=""
    result=200
    if request.env['HTTP_X_SORACOM_SIGNATURE']
      res = verify_signature request.env, (params[:secret] || "topsecret")
      logger.debug res[:log]
      log = res[:log]
      result = res[:result]
    end
    greetings = "Hello SORACOM Beam Client"
    if request.env['HTTP_X_SORACOM_IMSI']
      greetings += " IMSI:#{request.env['HTTP_X_SORACOM_IMSI']}"
    end
    if request.env['HTTP_X_SORACOM_SIM_ID']
      greetings += " SIM ID:#{request.env['HTTP_X_SORACOM_SIM_ID']}"
    end
    if request.env['HTTP_X_SORACOM_MSISDN']
      greetings += " MSISDN:#{request.env['HTTP_X_SORACOM_MSISDN']}"
    end
    if request.env['HTTP_X_SORACOM_IMEI']
      greetings += " IMEI:#{request.env['HTTP_X_SORACOM_IMEI']}"
    end
    greetings += " !"
    logger.debug greetings
    status 403 if result == false
    erb template, locals: { greet: greetings, env: request.env, verify_log: log}
  else
    logger.debug 'Hello unknown client ...'
    erb template, locals: { greet: 'Hello Unknown Client...', env: request.env, verify_log:'' }
  end
end

# データがポストされた場合
post '/' do
  logger.debug request.env.map{|k,v| "#{k}=#{v}\n"}.sort.join
  data = (request.env['CONTENT_TYPE'] == 'application/json')? JSON.parse(request.body.read) : request.body.read
  logger.debug data
  if data['payload']
    output = "#{data} => #{Base64.decode64 data['payload']}"
  else
    output = "#{data}"
  end
  user_agent = request.env['HTTP_USER_AGENT'] || 'curl'
  if user_agent.match(/curl/i)
    content_type 'text/plain;charset=utf8'
  end

  if request.env['HTTP_X_SORACOM_IMSI'] || request.env['HTTP_X_SORACOM_IMEI'] || request.env['HTTP_X_SORACOM_SIM_ID'] || request.env['HTTP_X_SORACOM_MSISDN']
    if request.env['HTTP_X_SORACOM_SIGNATURE']
      res = verify_signature request.env
      logger.debug res[:log]
      if res[:result]
        return "Access Authorized: #{output}"
      else
        status 403
        return "Access Denied: Invalid Signature\n#{res[:log]}"
      end
    end
    greetings = "Hello SORACOM Beam Client"
    if request.env['HTTP_X_SORACOM_IMSI']
      greetings += " IMSI:#{request.env['HTTP_X_SORACOM_IMSI']}"
    end
    if request.env['HTTP_X_SORACOM_SIM_ID']
      greetings += " SIM ID:#{request.env['HTTP_X_SORACOM_SIM_ID']}"
    end
    if request.env['HTTP_X_SORACOM_MSISDN']
      greetings += " MSISDN:#{request.env['HTTP_X_SORACOM_MSISDN']}"
    end
    if request.env['HTTP_X_SORACOM_IMEI']
      greetings += " IMEI:#{request.env['HTTP_X_SORACOM_IMEI']}"
    end
    logger.debug greetings
  end
  "Success: #{output}"
end

get '/dumpenv*' do
  request.env.select{|k,v| k=~/HTTP_/}.map{|k,v| "#{k}=#{v}\n"}.sort.join
end

post '/dumpenv*' do
  request.env.select{|k,v| k=~/HTTP_/}.map{|k,v| "#{k}=#{v}\n"}.sort.join
end

get '/healthcheck' do
  'OK'
end
