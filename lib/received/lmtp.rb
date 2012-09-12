module Received
  # RFC2033
  class LMTP

    def initialize(conn)
      @conn = conn
      @state = :start
      @buf = ''
    end

    def on_data(data)
      @buf += data
      while line = @buf.slice!(/.*\r\n/)
        line.chomp! unless @state == :data
        event(line)
      end
    end

    def start!
      event(nil)
    end

    private
    def reset!
      @buf = ''
      @from = nil
      @rcpt = []
      @body = []
    end

    def event(ev)
      @conn.logger.debug {"state was: #{@state.inspect}"}
      @state = case @state
      when :start
        reset!
        banner
        :banner_sent
      when :banner_sent
        if ev.start_with?('LHLO')
          lhlo_response
          extensions
          :lhlo_received
        else
          error
        end
      when :lhlo_received
        if ev =~ /^MAIL FROM:<?([^<>]*)/
          @from = $1
          ok
          :mail_from_received
        else
          error
        end
      when :mail_from_received
        if ev =~ /^RCPT TO:<?([^<>]*)/
          @rcpt << $1
          ok
          :rcpt_to_received
        else
          error
        end
      when :rcpt_to_received
        if ev =~ /^RCPT TO:<?([^<>]*)/
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
          mail = {:from => @from, :rcpt => @rcpt, :body => @body.join.force_encoding('BINARY')}
          if @conn.mail_received(mail)
            @rcpt.size.times {ok}
          else
            @rcpt.size.times {error_in_processing}
          end
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
      emit "354 End data with <CR><LF>.<CR><LF>"
    end

    def closing_connection
      emit "221 Bye"
      @conn.close_connection_after_writing
    end

    # FIXME: RFC2033 requires ENHANCEDSTATUSCODES,
    # but it's not used in Postfix
    def extensions
      emit "250-8BITMIME\r\n250 PIPELINING"
    end

    def ok
      emit "250 OK"
    end

    def error
      emit "500 command unrecognized"
    end

    def error_in_processing
      emit "451 Requested action aborted: local error in processing"
    end

    def emit(str)
      @conn.send_data "#{str}\r\n"
      # return nil, so there won't be implicit state transition
      nil
    end
  end
end
