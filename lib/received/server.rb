#require 'active_support/core_ext/string/inflections'
require 'eventmachine'
require 'received/connection'

module Received
  class Server
    attr_reader :logger, :options

    def initialize(options)
      @options = options
      @logger = options[:logger] || Logger.new($stderr)
      @connections = []
      # For how long the server will wait for connections to finish
      @grace_period = options[:grace_period] || 10
      create_backend
    end

    def serve!
      EventMachine.run { start }
    end

    def start
      unless options[:unix_socket] or options[:port]
        raise "No port or UNIX socket path were provided"
      end
      set_title
      if host = options[:unix_socket]
        port = nil
      else
        host = options[:host] || '127.0.0.1'
        port = options[:port]
      end
      logger.info "Starting server on #{host}#{port ? ":" + port.to_s : ''}"
      @signature = EventMachine.start_server(host, port, Received::Connection, self, @backend) do |conn|
        add_connection(conn)
      end
    end

    def stop
      return if stopping?
      logger.info "Stopping server"
      EventMachine.stop_server(@signature)
      @stopped_at = Time.now
      unless wait_for_connections_and_stop
        # Still some connections running, schedule a check later
        EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
      end
    end

    # Checks whether the server is in stopping mode
    def stopping?
      !!@stopped_at
    end

    # Checks if the server is processing any connections
    def idle?
      @connections.empty?
    end

    def remove_connection(conn)
      @connections.delete(conn)
      set_title
    end

    private

    # Sets the process title as seen in ps
    def set_title
      $0 = "received (#{@connections.size} connections)"
    end

    # Whether grace period is over
    def grace_ended?
      Time.now - @stopped_at > @grace_period
    end

    def wait_for_connections_and_stop
      if idle? or grace_ended?
        EventMachine.stop
        true
      else
        puts "Waiting for #{@connections.size} connection(s) to finish ..."
        false
      end
    end

    def add_connection(conn)
      @connections << conn
      set_title
    end

    def create_backend
      backend = options[:backend].to_s
      require 'received/backend/' + backend
      #klass = ('Received::Backend::' + backend.camelize).constantize
      klass = eval('Received::Backend::' + backend.capitalize)
      env = ENV['RAILS_ENV'] || 'production'
      config = YAML.load(File.read(options[:config]))[env]
      @backend = klass.new(config)
    end

  end
end