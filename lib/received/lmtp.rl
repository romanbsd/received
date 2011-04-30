module Received
  class LMTP
=begin
    %%{
      machine LMTP;
      access state->;

      action ready {
        send_data "220 localhost LMTP server ready\r\n"
      }

      action lhlo_reply {
        send_data("250-localhost\r\n")
      }

      action send_error {
        send_data("")
      }

      lmtp = "L";

      Proto = (
        start: (
          lmtp -> lmtp_reply
        ),
        lmtp_reply: (
        )
      ) >initialize;
    }%%
=end
    def initialize(conn)
      @conn = conn
#      %% write data;
    end

    def scan(data)
#      %% write init;
#      %% write exec;
    end

    def send_data(data)
      @conn.send_data(data)
    end
  end
end