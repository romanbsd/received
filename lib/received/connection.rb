require 'eventmachine'
require 'received/lmtp'

module Received
  class Connection < EM::Connection

    def initialize(server, backend)
      @server, @backend = server, backend
#      @buffer = []
      @proto = LMTP.new(self)
    end

    def post_init
      logger.debug "new connection"
    end

    def receive_data(data)
      logger.debug {"receiving data: #{data.size}"}
      @proto.on_data(data)
      #@buffer << data
    end

    # Client disconnected
    def unbind
      logger.debug "connection closed"
      # begin
      #   unless @server.stopping?
      #     @backend.store(@buffer.join)
      #     logger.info "saved"
      #   end
      # rescue Exception => e
      #   logger.error "saving failed with: #{e.message}"
      # end
      # @buffer = []
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
      rescue Exception => e
        logger.error "saving failed with: #{e.message}"
      end
    end

    def logger
      @server.logger
    end
  end
end