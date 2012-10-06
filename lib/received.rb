module Received
  def self.logger=(l)
    @logger = l
  end

  def self.logger
    @logger
  end
end

require 'received/backend/base'
require 'received/server'