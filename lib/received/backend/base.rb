module Received
  module Backend
    class Base
      # Stores the data
      #
      # @abstract
      # @param [Hash] mail
      # @option mail [String] :from
      # @option mail [Array] :rcpt
      # @option mail [String] :body
      def store(mail)
        raise NotImplementedError
      end
    end
  end
end
