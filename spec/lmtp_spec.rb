require 'spec_helper'
require 'logger'

describe Received::LMTP do
  before :each do
    @mock = mock 'conn'
    @mock.should_receive(:send_data).with("220 localhost LMTP server ready\r\n")
    logger = Logger.new($stderr)
    @mock.stub!(:logger).and_return(logger)
    @mock.logger.debug "*** Starting test ***"
    @proto = Received::LMTP.new(@mock)
    @proto.start!
  end

  describe "Full flow" do
    let(:body) { "Subject: spec\r\nspec\r\n" }

    def begin_flow!
      ["LHLO", "MAIL FROM:<spec1@example.com>", "RCPT TO:<spec2@example.com>",
        "RCPT TO:<spec3@example.com>", "DATA", "#{body}.", "QUIT"].each do |line|
        @mock.logger.debug "client: #{line}"
        @proto.on_data(line + "\r\n")
      end
    end

    def common_expectations!
      @mock.should_receive(:send_data).with("250-localhost\r\n")
      @mock.should_receive(:send_data).with("250-8BITMIME\r\n250 PIPELINING\r\n")
      @mock.should_receive(:send_data).with("250 OK\r\n").exactly(3).times
      @mock.should_receive(:send_data).with("354 End data with <CR><LF>.<CR><LF>\r\n")
    end

    it "receives mail" do
      common_expectations!
      @mock.should_receive(:send_data).with("250 OK\r\n").exactly(2).times
      @mock.should_receive(:send_data).with("221 Bye\r\n")
      @mock.should_receive(:mail_received).with({
        :from => 'spec1@example.com',
        :rcpt => ['spec2@example.com', 'spec3@example.com'],
        :body => body
      }).and_return(true)
      @mock.should_receive(:close_connection_after_writing)

      begin_flow!
    end


    it "returns error when it cannot save email" do
      common_expectations!
      @mock.should_receive(:mail_received).once.and_return(false)
      @mock.should_receive(:send_data).with(/451/).exactly(2).times
      @mock.should_receive(:send_data).with("221 Bye\r\n")
      @mock.should_receive(:close_connection_after_writing)

      begin_flow!
    end
  end

  it "parses multiline" do
    @mock.should_receive(:send_data).with("250-localhost\r\n")
    @mock.should_receive(:send_data).with("250-8BITMIME\r\n250 PIPELINING\r\n")
    @mock.should_receive(:send_data).with("250 OK\r\n")
    @proto.on_data("LHLO\r\nMAIL FROM:<spec@example.com>\r\n")
  end

  it "buffers commands up to CR/LF" do
    @mock.should_receive(:send_data).with("250-localhost\r\n")
    @mock.should_receive(:send_data).with("250-8BITMIME\r\n250 PIPELINING\r\n")
    @mock.should_receive(:send_data).with("250 OK\r\n")
    @proto.on_data("LHLO\r\nMAIL FROM")
    @proto.on_data(":<spec@example.com>\r\n")
  end

  it "passes CR/LF through" do
    body = "Subject: test\r\n\r\nTest\r\n"
    @mock.stub!(:send_data)
    @proto.on_data("LHLO\r\nMAIL FROM:<spec1@example.com>\r\nRCPT TO:<spec2@example.com>\r\nDATA\r\n")
    @proto.on_data(body)
    @mock.should_receive(:mail_received) do |r|
      r[:body].should == body
    end
    @proto.on_data(".\r\n")
  end
end
