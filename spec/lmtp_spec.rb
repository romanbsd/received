require 'spec_helper'
require 'logger'

describe Received::LMTP do
  let(:conn) { mock(:conn, :logger => Logger.new(STDERR)) }
  let(:proto) { Received::LMTP.new(conn) }

  before do
    conn.should_receive(:send_data).with("220 localhost LMTP server ready\r\n")
    conn.logger.debug "*** Starting test ***"
    proto.start!
  end

  describe "Full flow" do
    let(:body) { "Subject: spec\r\nspec\r\n" }

    def begin_flow!
      ["LHLO", "MAIL FROM:<spec1@example.com>", "RCPT TO:<spec2@example.com>",
        "RCPT TO:<spec3@example.com>", "DATA", "#{body}.", "QUIT"].each do |line|
        conn.logger.debug "client: #{line}"
        proto.on_data(line + "\r\n")
      end
    end

    def common_expectations!
      conn.should_receive(:send_data).with("250-localhost\r\n")
      conn.should_receive(:send_data).with("250-8BITMIME\r\n250 PIPELINING\r\n")
      conn.should_receive(:send_data).with("250 OK\r\n").exactly(3).times
      conn.should_receive(:send_data).with("354 End data with <CR><LF>.<CR><LF>\r\n")
    end

    it "receives mail" do
      common_expectations!
      conn.should_receive(:send_data).with("250 OK\r\n").exactly(2).times
      conn.should_receive(:send_data).with("221 Bye\r\n")
      conn.should_receive(:mail_received).with({
        :from => 'spec1@example.com',
        :rcpt => ['spec2@example.com', 'spec3@example.com'],
        :body => body
      }).and_return(true)
      conn.should_receive(:close_connection_after_writing)

      begin_flow!
    end


    it "returns error when it cannot save email" do
      common_expectations!
      conn.should_receive(:mail_received).once.and_return(false)
      conn.should_receive(:send_data).with(/451/).exactly(2).times
      conn.should_receive(:send_data).with("221 Bye\r\n")
      conn.should_receive(:close_connection_after_writing)

      begin_flow!
    end
  end

  it "parses multiline" do
    conn.should_receive(:send_data).with("250-localhost\r\n")
    conn.should_receive(:send_data).with("250-8BITMIME\r\n250 PIPELINING\r\n")
    conn.should_receive(:send_data).with("250 OK\r\n")
    proto.on_data("LHLO\r\nMAIL FROM:<spec@example.com>\r\n")
  end

  it "buffers commands up to CR/LF" do
    conn.should_receive(:send_data).with("250-localhost\r\n")
    conn.should_receive(:send_data).with("250-8BITMIME\r\n250 PIPELINING\r\n")
    conn.should_receive(:send_data).with("250 OK\r\n")
    proto.on_data("LHLO\r\nMAIL FROM")
    proto.on_data(":<spec@example.com>\r\n")
  end

  it "passes CR/LF through" do
    body = "Subject: test\r\n\r\nTest\r\n"
    conn.stub!(:send_data)
    proto.on_data("LHLO\r\nMAIL FROM:<spec1@example.com>\r\nRCPT TO:<spec2@example.com>\r\nDATA\r\n")
    proto.on_data(body)
    conn.should_receive(:mail_received) do |r|
      r[:body].should == body
    end
    proto.on_data(".\r\n")
  end

  it "allows empty FROM" do
    conn.stub(:send_data)
    conn.stub(:close_connection_after_writing)
    conn.should_receive(:mail_received) do |mail|
      puts "RECEIVED     '#{mail.inspect}'"
      mail[:from].should be_empty
    end

    ["LHLO", "MAIL FROM:<>", "RCPT TO:<spec2@example.com>",
      "RCPT TO:<spec3@example.com>", "DATA", "testing\r\n.", "QUIT"].each do |line|
      proto.on_data(line + "\r\n")
    end

  end
end
