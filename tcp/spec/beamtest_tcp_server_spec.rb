require 'socket'

require File.expand_path '../spec_helper.rb', __FILE__
require File.expand_path '../../beamtest_tcp_server.rb', __FILE__

PORT = 1234

RSpec.describe "TCP server" do
  let(:imsi) { "440101234567890" }
  let(:timestamp) { "1608251959862" }
  let(:signature) { "9b7c3587a10b94453127aa614bac55ca0d953f4a98f428a086114f67120a850b" }

  before(:example) do
    @server = BeamtestTcpServer.new()
    Thread.new { @server.start() }
    @socket = TCPSocket.open("localhost", PORT)
  end

  after(:example) do
    @server.stop()
  end

  it "echo back message" do
    @socket.puts("Hello, world")
    @socket.close_write
    expect(@socket.read).to eql("Hello, world\n")
  end

  it "return authorized message with a valid signature" do
    @socket.puts("imsi=#{imsi} timestamp=#{timestamp};signature=#{signature}")
    @socket.close_write
    expect(@socket.read).to include("Hello Authorized Soracom Beam Client! :imsi=440101234567890 timestamp=1608251959862\n")
  end

  it "return authorized message with an invalid signature" do
    @socket.puts("imsi=#{imsi} timestamp=#{timestamp};signature=deadbeafcafebabe")
    @socket.close_write
    expect(@socket.read).to eql("ERROR: The request signature we calculated does not match the signature you provided.\n")
  end

  it "return message without a signature" do
    @socket.puts("imsi=#{imsi} timestamp=#{timestamp}")
    @socket.close_write
    expect(@socket.read).to eql("Hello Soracom Beam Client! : imsi=440101234567890 timestamp=1608251959862\n")
  end
end
