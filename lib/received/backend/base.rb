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

      def notify_observers(*args)
        self.class.notify_observers(*args)
      end

      class << self
        def observers
          @@observers ||= []
        end

        def add_observer(observer)
          observers.push(observer)
        end

        def remove_observer(observer)
          observers.delete(observer)
        end

        def notify_observers(method, payload)
          observers.each do |observer|
            if observer.respond_to?(method)
              observer.send(method, payload) rescue nil
            end
          end
        end
      end

    end
  end
end
