require "open3"
require_relative "sender"

if Process.uid != 0
  p "root priviledge required"
  exit 1
end

system("ip link set wlan2 down")

NETNS_NAME="lh"
unless system("ip netns add #{NETNS_NAME}")
  p "netns exists! delete"
  system("ip netns delete #{NETNS_NAME}")
  system("ip netns add #{NETNS_NAME}")
  sleep 3
end

# open receiver

stdin, stdout, stderr, th = *Open3.popen3(
  "ip netns exec #{NETNS_NAME} ruby receiver.rb")

p "SND: executed receiver"
sleep 10

snd = Sender.new(NETNS_NAME)
p "SND: start sending interface"
p "SND: dev = #{snd.interface_dev}, phy = #{snd.interface_phy}"
p "SND: pid = #{snd.lighthouse_pid}"
p "SND: send interface"

ifname = snd.pass_interface
p "passed interface"

done = snd.confirm_pass

p "SND: done? => #{done}"

ifname = "wlan2"
essid = "TESTNet"
bssid = "00:00:00:00:03:24"
security = "wpa-psk-aes"
passphrase = "password"
dir = "/tmp"

system("ip netns exec #{NETNS_NAME} ruby lighthouse.rb -i #{ifname} -e #{essid} -b #{bssid} -s #{security} -p #{passphrase} -c lighthouse.conf -d /tmp")



# cleanup
system("ip netns delete #{NETNS_NAME}")
system("ip link set #{ifname} down")
