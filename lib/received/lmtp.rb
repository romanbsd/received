module Received
  # RFC2033
  class LMTP

    # conn should respond_to send_data and body_received
    def initialize(conn)
      @conn = conn
      @line = ''
      reset!
    end

    def on_data(data)
      @buf += data
      while line = @buf.slice!(/.+\r\n/)
        line.chomp! unless @state == :data
        event(line)
      end
    end

    def reset!
      @state = :start
      @buf = ''
      @from = nil
      @rcpt = []
      event(nil)
    end

    private
    def event(ev)
      @conn.logger.debug {"state was: #{@state.inspect}"}
      @state = case @state
      when :start
        @body = []
        banner
        :banner_sent
      when :banner_sent
        if ev.start_with?('LHLO')
          lhlo_response
          :lhlo_received
        else
          error
        end
      when :lhlo_received
        if ev =~ /MAIL FROM:<?([^>]+)/
          @from = $1
          ok
          :mail_from_received
        else
          error
        end
      when :mail_from_received
        if ev =~ /RCPT TO:<?([^>]+)/
          @rcpt << $1
          ok
          :rcpt_to_received
        else
          error
        end
      when :rcpt_to_received
        if ev =~ /RCPT TO:<?([^>]+)/
          @rcpt << $1
          ok
        elsif ev == "DATA"
          start_mail_input
          :data
        else
          error
        end
      when :data
        if ev == ".\r\n"
          ok
          mail = {:from => @from, :rcpt => @rcpt, :body => @body.join}
          @conn.mail_received(mail)
          :data_received
        else
          @body << ev
          :data
        end
      when :data_received
        if ev == "QUIT"
          closing_connection
          :start
        else
          error
        end
      else
        raise "Where am I? (#{@state.inspect})"
      end || @state
      @conn.logger.debug {"state now: #{@state.inspect}"}
    end

    def banner
      emit "220 localhost LMTP server ready"
    end

    def lhlo_response
      emit "250-localhost"
    end

    def start_mail_input
      emit "354 Start mail input; end with <CRLF>.<CRLF>"
    end

    def closing_connection
      emit "452 localhost closing connection"
      @conn.close_connection(true)
    end

    def ok
      emit "250 OK"
    end

    def error
      emit "500 command unrecognized"
    end

    def emit(str)
      @conn.send_data "#{str}\r\n"
      # return nil, so there won't be implicit state transition
      nil
    end
  end
end