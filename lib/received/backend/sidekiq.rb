require 'charlock_holmes'
require 'json'
require 'redis'
require 'securerandom'

module Received
  module Backend
    class Sidekiq < Base

      # Initialize Sidekiq storage backend
      #
      # @param [Hash] params
      # @option params [String] redis_url
      # @option params [String] namespace
      # @option params [String] sentinels
      # @option params [String] queue
      # @option params [String] worker
      def initialize(params)
        @queue = params.fetch('queue', 'default')
        @namespace = params['namespace']
        @worker = params['worker']

        @client = ::Redis.new({
          url: params.fetch('redis_url', 'redis://localhost:6379'),
          sentinels: params['sentinels'],
        }.compact)
      end

      # Store mail in Redis
      #
      # @param [Hash] mail
      # @return [String] job id
      def store(mail)
        item = item_for(mail[:body])

        @client.lpush(queue_key, JSON.generate(item))
        notify_observers(:after_save, item)

        item['jid']
      end

      protected

      def queue_key
        [@namespace, 'queue', @queue].compact.join(':')
      end

      def item_for(message)
        {
          'class'       => @worker,
          'args'        => [utf8_encode_message(message)],
          'queue'       => @queue,
          'jid'         => SecureRandom.hex(12),
          'retry'       => false,
          'enqueued_at' => Time.now.to_f,
        }
      end

      def utf8_encode_message(message)
        message = message.dup

        message.force_encoding('UTF-8')
        return message if message.valid_encoding?

        detection = CharlockHolmes::EncodingDetector.detect(message)
        return message unless detection && detection[:encoding]

        # Convert non-UTF-8 body UTF-8 so it can be dumped as JSON.
        CharlockHolmes::Converter.convert(message, detection[:encoding], 'UTF-8')
      end
    end
  end
end
