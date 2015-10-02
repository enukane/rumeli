require "pidfile"

require_relative "channel"
require_relative "utils"

# must be run in netns

class Receiver
  PIDFILE_DIR="/var/run"
  PIDFILE_NAME="lighthouse.pid"
  DEFAULT_WLANIF="wlan0"
  def initialize
    @pf = PidFile.new(:piddir => PIDFILE_DIR,
                      :pidfile => PIDFILE_NAME)
    @done = false
  end

  def run
    @sock = UDPSocketChannel.new()
    @sock.register_recv_handler(Proc.new{|msg|
      recv_handler(msg)
    })

    @sock.start

    while !@done
    end

    sleep 5
    @sock.stop
  end

  def recv_handler msg
    p msg
    case msg["method"]
    when "pass_interface"
      check_interface(msg["interface"])
    when "done"
      done
    end
  end

  def check_interface(ifname=DEFAULT_WLANIF)
    p "ifname => #{ifname}"
    if Utils.get_first_iw_dev == ifname
      return {:code => "ok", :interface => ifname}
    else
      return {:code => "ng", :interface => Utils.get_first_iw_dev}
    end
  end

  def done
    @done = true
    return {:code => "ok"}
  end
end

if __FILE__ == $0
  rcv = Receiver.new
  p "RCV: start running receiver"
  rcv.run
  p "done passing"
end
