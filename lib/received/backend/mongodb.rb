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
        db = Mongo::Connection.new(params['host']).db(params['database'])
        @coll = db.collection(params['collection'])
      end

      # Store mail in MongoDB
      #
      # @param [Hash] mail
      # @return [ObjectId] object_id
      def store(mail)
        mail = mail.merge(:ts => Time.now.to_i, :body => BSON::Binary.new(mail[:body]))
        @coll.insert(mail, :safe => {:fsync => true}).tap do |result|
          notify_observers(:after_save, result) if result
        end
      end
    end
  end
end
