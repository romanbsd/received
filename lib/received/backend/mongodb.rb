require 'mongo'

module Received
  module Backend
    class Mongodb < Base

      # Initialize MongoDB storage backend
      #
      # @param [Hash] params
      # @option params [String] host
      # @option params [String] database
      # @option params [String] collection
      def initialize(params)
        @db = Mongo::Connection.new(params['host']).db(params['database'])
        @coll = @db.collection(params['collection'])
      end

      # Store mail in MongoDB
      #
      # @param [Hash] mail
      def store(mail)
        @coll.save(mail.merge({:ts => Time.now.to_i}), :safe => true)
      end
    end
  end
end
