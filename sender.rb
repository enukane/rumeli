require "pidfile"

require_relative "utils"
require_relative "receiver"

class Sender
  def initialize(netns="lh")
    @netns = netns
    @dev = interface_dev()
    @phy = interface_phy()
  end

  def pass_interface
    unless system("sudo iw phy #{@phy} set netns #{lighthouse_pid}")
      p "failed to pass interface"
      #raise "Failed to pass interface"
    end
    return @dev
  end

  def confirm_pass
    return system("sudo ip netns exec #{@netns} ip link show #{@dev}> /dev/null 2>&1")
  end

  def interface_dev
    return Utils.get_first_iw_dev
  end

  def interface_phy
    return Utils.get_first_iw_phy
  end

  def lighthouse_pid
    pid = nil
    File.open("#{Receiver::PIDFILE_DIR}/#{Receiver::PIDFILE_NAME}") do |f|
      pid = f.read.to_i
    end
    return pid
  end

end


if __FILE__ == $0
  snd = Sender.new
  p "SND: start sending interface"
  p "SND: dev = #{snd.interface_dev}, phy = #{snd.interface_phy}"
  p "SND: pid = #{snd.lighthouse_pid}"
  p "SND: send interface"
  ifname = snd.pass_interface
  p "SND: acknowledge pass to receiver(#{ifname})"
  done = snd.confirm_pass
  p "SND: done? => #{done}"
end
