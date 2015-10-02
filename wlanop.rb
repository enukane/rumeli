require 'optparse'
require 'erb'

class WLANOp
  PATH_PREFIX="conf"
  CTRL_PATH="/tmp/lighthouse.wpa_supplicant"
  SECURITY_NONE="none"
  SECURITY_WEP="wep"
  SECURITY_WPA_PSK_AES="wpa-psk-aes"
  SECURITY_WPA_PSK_TKIP="wpa-psk-tkip"
  SECURITY_WPA_EAP_AES="wpa-eap-aes"
  SECURITY_WPA_EAP_TKIP="wpa-eap-tkip"

  # wpa_supplicant param
  WPA_PSK="WPA-PSK"
  PW_TKIP="TKIP"
  PW_AES="CCMP"
  GROUP_TKIP="TKIP"
  GROUP_AES="CCMP"
  TEMPLATE_PSK=<<"TEMPLATE_END"
ctrl_interface=#{CTRL_PATH}
network={
proto=WPA WPA2
key_mgmt=<%= @sup_key_mgmt %>
pairwise=<%= @sup_pairwise %>
group=<%= @sup_group %>
ssid="<%= @sup_ssid %>"
<% if @sup_bssid %>
bssid=<%= @sup_bssid %>
<% end %>
psk="<%= @sup_psk %>"
}
TEMPLATE_END

  BGEXEC="-B"

  def self.default_options
    {
      :ifname     => "wlan0",
      :essid      => "TESTSSID",
      :bssid      => nil,
      :security   => SECURITY_WPA_PSK_AES,
      :passphrase => nil,
      :foreground => false,
      :dir        => "/tmp"
    }
  end

  def initialize opt={}
    @ifname = opt[:ifname]
    @essid = opt[:essid]
    @bssid = opt[:bssid]
    @security = opt[:security]
    @pass = opt[:passphrase]
    @use_fg = opt[:foreground]
    @dir = opt[:dir] || "/tmp"

    @sup_key_mgmt = nil
    @sup_pairwise = nil
    @sup_group = nil
    @sup_ssid = nil
    @sup_psk = nil

  end

  def validate_and_set
    if @ifname == nil or @essid == nil or @security == nil
      raise "ERROR: requires IFNAME and ESSID and SECURITY to be valid"
    end
    case @security
    when SECURITY_NONE
      # ok
      # when SECURITY_WEP
      #   if @pass == nil or (@pass.length != 5 and @pass.length == 13)
      #     raise "ERROR: #{SECURITY_WEP} requires valid pass ('#{@pass}')"
      #   end
    when SECURITY_WPA_PSK_AES, SECURITY_WPA_PSK_TKIP
      if @pass == nil or (@pass.length < 8 or @pass.length > 63)
        raise "ERROR: #{@security} requires valid passphrase ('#{@pass}')"
      end
      @sup_key_mgmt=WPA_PSK
      @sup_pairwise = @security == SECURITY_WPA_PSK_AES ? PW_AES : PW_TKIP
      @sup_group = @security == SECURITY_WPA_PSK_AES ? GROUP_AES : GROUP_TKIP
      @sup_ssid = @essid
      @sup_bssid = @bssid
      @sup_psk = @pass
    else
      raise "ERROR: #{@security} not supported"
    end
  end

  def use_foreground val
    @use_fg = val == true
  end

  def connect
    validate_and_set
    @path = generate_config_file()
    do_connect(@path)
  end

  def disconnect
  end

  def connected?
    io = IO.popen("wpa_cli -p /tmp/lighthouse.wpa_supplicant status | grep wpa_state")
    data = io.read
    io.close
    if data.match(/^wpa_state=COMPLETED$/)
      return true
    else
      return false
    end
  end

  def generate_config_file()
    basename = generate_config_basename(@ifname)
    config = ""

    case @security
    when SECURITY_NONE
      # do noghint
    when SECURITY_WPA_PSK_AES, SECURITY_WPA_PSK_TKIP
      erb = ERB.new(TEMPLATE_PSK)
      config = erb.result(binding)
    else
      raise "ERROR: #{@security} not supported"
    end
    return write_config_file(basename, config)
  rescue => e
    print "ERROR: failed to generate_config_file (#{e})\n"
    raise ""
  end

  def write_config_file(basename, config)
    unless Dir.exists?(@dir)
      raise "ERROR: cannot save config file (regular file exists!!!)" if File.exists?(@dir)
      Dir.mkdir(@dir)
    end
    path = generate_config_path(basename)
    File.open(path, "w") do |file|
      file.write config
    end
    return path
  end

  def generate_config_basename(ifname)
    return "wpa_supplicant.#{ifname}.conf"
  end

  def generate_config_path(basename)
    return "#{@dir}/#{basename}"
  end

  def do_connect(path)

    case @security
    when SECURITY_NONE
      do_exec("iwconfig #{@ifname} key open")
      do_exec("ifconfig #{@ifname} up")
    when SECURITY_WPA_PSK_AES, SECURITY_WPA_PSK_TKIP
      bg = @use_fg == true ? "": BGEXEC
      do_exec("wpa_supplicant -Dwext -i #{@ifname} -c #{path} #{bg} -P /var/run/wpa_supplicant.#{@ifname}.pid 2>/dev/null")
    else
      raise "DO_CONNECT: #{@security} not supported"
    end

    return true
  end

  def do_exec command
    print "EXECUTE > #{command}\n"
    system(command)
  end
end

if __FILE__ == $0

  opt = OptionParser.new
  OPTS=WLANOp.default_options

  opt.on('-i', "--interface [IFNAME=wlan0]", "interface to connect") {|v|
    OPTS[:ifname] = v
  }

  opt.on('-e', "--essid [ESSID]", "ESSID(SSID) to connect") {|v|
    OPTS[:essid] = v
  }

  opt.on('-b', "--bssid [BSSID=XX:XX:XX:XX:XX:XX]", "BSSID to connect") {|v|
    OPTS[:bssid] = v
  }

  opt.on('-s', "--security [Security=wpa-psk-aes,wpa-psk-tkip]", "Supported security mode") {|v|
    OPTS[:security] = v
  }

  opt.on('-p', "--passphrase [passphrase=XXXXX]", "passphrase used to connect") {|v|
    OPTS[:passphrase] = v
  }

  opt.on('-f', "--foreground", "execute wpa_supplicant in foreground") {|v|
    OPTS[:foreground] = true
  }

  opt.on('-d', "--directory [config directory]", "config directory for wpa_supplicant") {|v|
    OPTS[:dir] = v
  }

  opt.on('-D', "--disconnect") {|v|
    OPTS[:disconnect] = true
  }

  opt.on('-h', "--help", "this help") {|v|
    usage nil
  }

  (class<<self;self;end).module_eval do
    define_method(:usage) do |msg|
      puts opt.to_s
      puts "error: #{msg}" if msg
      exit 1
    end
  end

  begin
    rest = opt.parse(ARGV)
    if rest.length != 0
      usage nil
    end
  rescue
    usage $!.to_s
  end

  wlanop = WLANOp.new(OPTS)

  if OPTS[:disconnect]
    wlanop.disconnect()
  else
    wlanop.connect()
    sleep 10
  end

  exit(wlanop.connected? ^ OPTS[:disconnect] ? 1 : 0)
end
