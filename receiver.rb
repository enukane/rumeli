require "pidfile"

require_relative "utils"

class Receiver
  PIDFILE_DIR="/var/run"
  PIDFILE_NAME="lighthouse.pid"
  DEFAULT_WLANIF="wlan0"
  def initialize
    @pf = PidFile.new(:piddir => PIDFILE_DIR,
                      :pidfile => PIDFILE_NAME)
    @done = false
  end

  def wait_interface(ifname=DEFAULT_WLANIF, timeout=30)
    found = false
    count = 0

    while Utils.get_first_iw_dev != ifname
      if count > timeout
        break
      end
      sleep 1
      count += 1
    end
    found = true if Utils.get_first_iw_dev == ifname
    return found
  end
end

if __FILE__ == $0
  rcv = Receiver.new

  p "RCV: start receiving"
  found = rcv.wait_interface("wlan2")
  p "done? => #{found}"
end
