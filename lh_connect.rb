require_relative "wlanop"

class PluginWlanConnect
  TYPE="wlan-connect"

  def initialize(config)
    @ifname = config[:ifname] || "wlan0"
    @essid = config[:essid] || ""
    @bssid = config[:bssid]
    @security = config[:security]
    @passphrase = config[:passphrase]
    @connected = false
    @wlanop = WLANOp.new({
      :ifname     => @ifname,
      :essid      => @essid,
      :bssid      => @bssid,
      :security   => @security,
      :passphrase => @passphrase,
    })
  end

  def execute
    @wlanop.connect()
    sleep 10

    @connected = @wlanop.connected?()
  end

  def report
    {
      :type => TYPE,
      :connect => @connected
    }
  end

  def cleanup
    @wlanop.disconnect()
    system("killall wpa_supplicant")
  end
end

if __FILE__ == $0
  wlantest = PluginWlanConnect.new({
    :ifname      => "wlan2",
    :essid       => "TESTNet",
    :bssid       => "00:00:00:00:03:24",
    :security    => "wpa-psk-aes",
    :passphrase  => "password",
  })

  p wlantest.execute
  p wlantest.report
end
