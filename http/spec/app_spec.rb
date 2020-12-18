require File.expand_path '../spec_helper.rb', __FILE__

RSpec.shared_context "with signature", shared_context: :metadata do
  let(:imsi) { '440101234567890' }
  let(:imei) { nil }
  let(:sim_id) { nil }
  let(:msisdn) { nil }
  let(:timestamp) { '1608251959862' }
  let(:signature) { 'a91b7388793953166d6433ba5fbb79c2bf16ecab7d99732233830793b5f8eb8c' }
  let(:signature_version) { '20151001' }

  before(:example) do
    header "X_SORACOM_IMSI", imsi
    header "X_SORACOM_IMEI", imei
    header "X_SORACOM_SIM_ID", sim_id
    header "X_SORACOM_MSISDN", msisdn
    header "X_SORACOM_TIMESTAMP", timestamp
    header "X_SORACOM_SIGNATURE", signature
    header "X_SORACOM_SIGNATURE_VERSION", signature_version
  end
end

RSpec.shared_context "without signature", shared_context: :metadata do
  let(:imsi) { '440101234567890' }
  let(:imei) { nil }
  let(:sim_id) { nil }
  let(:msisdn) { nil }

  before(:example) do
    header "X_SORACOM_IMSI", imsi
    header "X_SORACOM_IMEI", imei
    header "X_SORACOM_SIM_ID", sim_id
    header "X_SORACOM_MSISDN", msisdn
  end
end

RSpec.configure do |rspec|
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
  rspec.include_context "with signature", include_shared: true
end

RSpec.describe "GET '/' method" do
  before(:example) do
    header "CONTENT_TYPE", "text/plain"
  end

  context "without signature" do
    include_context "without signature"

    it "should render SIM information with text" do
      get '/'
      expect(last_response.status).to eql(200)
      expect(last_response.body).to include("Hello SORACOM Beam Client")
      expect(last_response.body).to include("IMSI:#{imsi} !")
    end
  end

  context "with signature" do
    include_context "with signature"

    context "when signature is valid" do
      it "should render IMSI" do
        get '/'
        expect(last_response.status).to eql(200)
        expect(last_response.body).to include("Match!")
        expect(last_response.body).to include("Hello SORACOM Beam Client")
        expect(last_response.body).to include("IMSI:#{imsi} !")
      end

      context "when SIM ID is provided instead of IMSI" do
        let(:imsi) { nil }
        let(:sim_id) { '8981100024620429680' }
        let(:signature) { '64abe743664eda299ee157e6d7f4562bd73c6513e3cfacd7b2e53eca8bf8bd32' }

        it "should render SIM ID" do
          get '/'
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include("Match!")
          expect(last_response.body).to include("Hello SORACOM Beam Client")
          expect(last_response.body).to include("SIM ID:#{sim_id} !")
        end
      end

      context "when IMEI is provided instead of IMSI" do
        let(:imsi) { nil }
        let(:imei) { '123456789012345' }
        let(:signature) { '457aa6fffe564a2ae5147d7402a4b1b835ac5c783b17d2ac038cb18c3baeb15b' }

        it "should render IMEI" do
          get '/'
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include("Match!")
          expect(last_response.body).to include("Hello SORACOM Beam Client")
          expect(last_response.body).to include("IMEI:#{imei} !")
        end
      end

      context "when MSISDN is provided instead of IMSI" do
        let(:imsi) { nil }
        let(:msisdn) { '8180123456780000' }
        let(:signature) { 'ead18332fbd42cc445caa06005a960899792b1b9f00ffbdab9c9618bc4d57f63' }

        it "should render MSISDN" do
          get '/'
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include("Match!")
          expect(last_response.body).to include("Hello SORACOM Beam Client")
          expect(last_response.body).to include("MSISDN:#{msisdn} !")
        end
      end

      context "when IMSI/IMEI/SIM ID/MSISDN are provided" do
        let(:imei) { '123456789012345' }
        let(:sim_id) { '8981100024620429680' }
        let(:msisdn) { '8180123456780000' }
        let(:signature) { 'b30ae55dfed567cf5580f60760e0b761b62424587681ce6e77342825aeb1f6af' }

        it "should render MSISDN" do
          get '/'
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include("Match!")
          expect(last_response.body).to include("Hello SORACOM Beam Client")
          expect(last_response.body).to include("IMSI:#{imsi}")
          expect(last_response.body).to include("SIM ID:#{sim_id}")
          expect(last_response.body).to include("IMEI:#{imei}")
          expect(last_response.body).to include("MSISDN:#{msisdn}")
        end
      end
    end

    context "when signature is invalid" do
      let(:signature) { "wrong" }

      it "should return 403" do
        get '/'
        expect(last_response.status).to eql(403)
        expect(last_response.body).to include("Does not match...")
      end
    end

    context "when signature version is missing" do
      let(:signature_version) { nil }

      it "should return 403" do
        get '/'
        expect(last_response.status).to eql(403)
        expect(last_response.body).to include("x-soracom-signature-version header is missing")
      end
    end

    context "when timestamp is missing" do
      let(:timestamp) { nil }

      it "should return 403" do
        get '/'
        expect(last_response.status).to eql(403)
        expect(last_response.body).to include("Does not match...")
      end
    end
  end
end

RSpec.describe "POST '/' method" do
  before(:example) do
    header "CONTENT_TYPE", "application/json"
  end

  let(:body) { '{"payload": "dGVzdA=="}' } # dGVzdA== is 'test' (BASE64 encoded)

  context "without signature" do
    include_context "without signature"

    it "should render SIM information with text" do
      post '/', body
      expect(last_response.status).to eql(200)
      expect(last_response.body).to include('Success:')
      expect(last_response.body).to include('{"payload"=>"dGVzdA=="} => test')
    end
  end

  context "with signature" do
    include_context "with signature"

    context "when signature is valid" do
      it "should render SIM information with text" do
        post '/', body
        expect(last_response.status).to eql(200)
        expect(last_response.body).to include('Access Authorized:')
        expect(last_response.body).to include('{"payload"=>"dGVzdA=="} => test')
      end

      context "when SIM ID is provided instead of IMSI" do
        let(:imsi) { nil }
        let(:sim_id) { '8981100024620429680' }
        let(:signature) { '64abe743664eda299ee157e6d7f4562bd73c6513e3cfacd7b2e53eca8bf8bd32' }

        it "should authorize a request" do
          post '/', body
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include('Access Authorized:')
          expect(last_response.body).to include('{"payload"=>"dGVzdA=="} => test')
        end
      end

      context "when IMEI is provided instead of IMSI" do
        let(:imsi) { nil }
        let(:imei) { '123456789012345' }
        let(:signature) { '457aa6fffe564a2ae5147d7402a4b1b835ac5c783b17d2ac038cb18c3baeb15b' }

        it "should authorize a request" do
          post '/', body
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include('Access Authorized:')
          expect(last_response.body).to include('{"payload"=>"dGVzdA=="} => test')
        end
      end

      context "when MSISDN is provided instead of IMSI" do
        let(:imsi) { nil }
        let(:msisdn) { '8180123456780000' }
        let(:signature) { 'ead18332fbd42cc445caa06005a960899792b1b9f00ffbdab9c9618bc4d57f63' }

        it "should authorize a request" do
          post '/', body
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include('Access Authorized:')
          expect(last_response.body).to include('{"payload"=>"dGVzdA=="} => test')
        end
      end

      context "when IMSI/IMEI/SIM ID/MSISDN are provided" do
        let(:imei) { '123456789012345' }
        let(:sim_id) { '8981100024620429680' }
        let(:msisdn) { '8180123456780000' }
        let(:signature) { 'b30ae55dfed567cf5580f60760e0b761b62424587681ce6e77342825aeb1f6af' }

        it "should authorize a request" do
          post '/', body
          expect(last_response.status).to eql(200)
          expect(last_response.body).to include('Access Authorized:')
          expect(last_response.body).to include('{"payload"=>"dGVzdA=="} => test')
        end
      end
    end

    context "when signature is invalid" do
      let(:signature) { "wrong" }

      it "should return 403" do
        post '/', body
        expect(last_response.status).to eql(403)
        expect(last_response.body).to include("Does not match...")
      end
    end

    context "when signature version is missing" do
      let(:signature_version) { nil }

      it "should return 403" do
        post '/', body
        expect(last_response.status).to eql(403)
        expect(last_response.body).to include("x-soracom-signature-version header is missing")
      end
    end

    context "when timestamp is missing" do
      let(:timestamp) { nil }

      it "should return 403" do
        post '/', body
        expect(last_response.status).to eql(403)
        expect(last_response.body).to include("Does not match...")
      end
    end
  end
end

RSpec.describe "GET /healthcheck" do
  it "should return OK" do
    get '/healthcheck'
    expect(last_response.status).to eql(200)
    expect(last_response.body).to eql("OK")
  end
end

RSpec.describe "GET /dumpenv" do
  let(:imsi) { "440101234567890" }
  it "should return HTTP header" do
    header 'X_SORACOM_IMSI', imsi
    get '/dumpenv'
    expect(last_response.status).to eql(200)
    expect(last_response.body).to include("HTTP_X_SORACOM_IMSI=#{imsi}")
  end
end

RSpec.describe "POST /dumpenv" do
  let(:imsi) { "440101234567890" }
  it "should return HTTP header" do
    header 'X_SORACOM_IMSI', imsi
    post '/dumpenv'
    expect(last_response.status).to eql(200)
    expect(last_response.body).to include("HTTP_X_SORACOM_IMSI=#{imsi}")
  end
end
