module Received
  module Backend
    class Base
      # Stores the data
      #
      # @abstract
      # @param [String] data
      def store(data)
        raise NotImplementedError
      end
    end
  end
end