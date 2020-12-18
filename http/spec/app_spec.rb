require File.expand_path '../spec_helper.rb', __FILE__

RSpec.shared_context "with signature", shared_context: :metadata do
  let(:imsi) { '440101234567890' }
  let(:timestamp) { '1608251959862' }
  let(:signature) { 'a91b7388793953166d6433ba5fbb79c2bf16ecab7d99732233830793b5f8eb8c' }
  let(:signature_version) { '20151001' }

  before(:example) do
    header "X_SORACOM_IMSI", imsi
    header "X_SORACOM_TIMESTAMP", timestamp
    header "X_SORACOM_SIGNATURE", signature
    header "X_SORACOM_SIGNATURE_VERSION", signature_version
  end
end

RSpec.shared_context "without signature", shared_context: :metadata do
  let(:imsi) { '440101234567890' }

  before(:example) do
    header "X_SORACOM_IMSI", imsi
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
      it "should render SIM information with text" do
        get '/'
        expect(last_response.status).to eql(200)
        expect(last_response.body).to include("Match!")
        expect(last_response.body).to include("Hello SORACOM Beam Client")
        expect(last_response.body).to include("IMSI:#{imsi} !")
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