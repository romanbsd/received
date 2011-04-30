require 'eventmachine'
require 'received/lmtp'

module Received
  class Connection < EM::Connection

    def initialize(server, backend)
      @server, @backend = server, backend
      @proto = LMTP.new(self)
    end

    def post_init
      logger.debug "new connection"
      @proto.start!
    end

    def receive_data(data)
      logger.debug {"receiving data: #{data.inspect}"}
      @proto.on_data(data)
    end

    def send_data(data)
      logger.debug {"sending data: #{data.inspect}"}
      super
    end

    # Client disconnected
    def unbind
      logger.debug "connection closed"
      @server.remove_connection(self)
    end

    # Callback, called by protocol handler
    #
    # @param [Hash] mail
    # @option mail [String] :from
    # @option mail [Array] :rcpt
    # @option mail [String] :body
    def mail_received(mail)
      begin
        @backend.store(mail)
        logger.info "stored mail from: #{mail[:from]}"
      rescue Exception => e
        logger.error "saving failed with: #{e.message}"
      end
    end

    def logger
      @server.logger
    end
  end
end
