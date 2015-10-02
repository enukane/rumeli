require "json"
require "time"
require_relative "lh_scan"
require_relative "lh_connect"
require_relative "lh_dhcp_get_address"
require_relative "lh_ping"
require_relative "lh_dns_query"
require_relative "lh_speed"
require_relative "wlanop"

# this must run in netns

class Tester
  def self.default_options
    {
      :config     => "/etc/lighthouse.conf",
      :ifname     => "wlan0",
      :essid      => "",
      :bssid      => nil,
      :security   => WLANOp::SECURITY_WPA_PSK_AES,
      :passphrase => "",
    }
  end

  def initialize(opt)
    @config_path = opt[:config]
    @ifname = opt[:ifname]
    @essid = opt[:essid]
    @bssid = opt[:bssid]
    @security = opt[:security]
    @passphrase = opt[:passphrase]

    @config = read_config(@config_path).merge(opt)

    @plugins = setup_plugins
  end

  def execute
    @plugins.each do |plugin|
      begin
        p "PLUGIN: execute => #{plugin.class::TYPE}"
        plugin.execute
      rescue => e
        p "PLUGIN: execution failed => #{e}"
      end
    end

    summary = merge_report(@plugins.map{|plugin|
      plugin.report
    })

    save_summary(summary)

    summarys = pop_cached_summarys()
    p "PLUGIN: found #{summarys.length} pending summary"

    summarys.each do |summary|
      begin
        send_summary(summary)
        clear_summary(summary)
        p "PLUGIN: send & cleared summary (#{summary_path(summary)})"
      rescue => e
        p "PLUGIN: send summary failed : #{e} #{summary}"
      end
    end

  rescue => e
    p "PLUGIN: failed in => #{e}"
  ensure
    @plugins.each do |plugin|
      plugin.cleanup
    end
  end

  def setup_plugins
    # we want this to be pluggable!
    [
      PluginWlanScan.new(@config),
      PluginWlanConnect.new(@config),
      PluginDHCPGetAddress.new(@config),
      PluginPing.new(@config),
      PluginDNSQuery.new(@config),
      PluginCurlSpeed.new(@config),
    ]
  end

  def read_config(path)
    data = nil
    File.open(path) do |f|
      data = JSON.parse(f.read, {:symbolize_names => true})
    end

    # XXX: do config validation here

    return data
  end

  def merge_report(reports)
    summary = reports.map{|report|
      type = report[:type]
      Hash[report.map{|k,v|
        if k == :type
          nil
        else
          ["#{type.to_s}_#{k.to_s}".to_sym, v]
        end
      }]
    }.flatten.inject({}){|sum, item| sum.merge(item)}

    summary[:essid] = @essid
    summary[:bssid] = @bssid
    summary[:date] = Time.now
    summary[:timestamp] = Time.now.to_i
    summary[:uptime] = uptime

    return summary
  end

  def save_summary(summary)
    dir = @config[:cache]
    unless Dir.exists?(dir)
      begin
        Dir.mkdir(dir)
      rescue
        raise "#{dir} is already exists and not directory"
      end
    end

    path = "#{dir}/#{summary_path(summary)}"
    File.open(path, "w") do |f|
      f.write(JSON.dump(summary))
    end
  end

  def pop_cached_summarys()
    dir = @config[:cache]
    paths = Dir.entries(dir).sort.select{|str|
      str.match(/^summary_.*\.log$/)}.map{|str| dir + "/" + str}
    summarys = paths.map{|path|
      summary = nil
      begin
        File.open(path) do |f|
          summary = JSON.parse(f.read, {:symbolize_names => true})
          summary[:date] = Time.parse(summary[:date])
        end
      rescue
        sumamry = nil
      end
      summary
    }.compact
  end

  def send_summary(summary)
    p "SENDING: summary #{summary}"
  end

  def clear_summary(summary)
    path = "#{@config[:cache]}/#{summary_path(summary)}"
    if File.exists?(path)
      File.delete(path)
    else
      p "CLEAR: path is gone #{path}"
      # let it go
    end
  rescue => e
    p "CLEAR: path can't be deleted #{path}"
    return
  end

  def uptime
    IO.read('/proc/uptime').split[0].to_i
  end

  def summary_path(summary)
    if summary[:date]
      "summary_#{summary[:date].strftime("%Y%m%d%H%M%S")}.log"
    else
      "dummy"
    end
  end
end


if __FILE__ == $0
  opt = OptionParser.new
  OPTS=Tester.default_options

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

  opt.on('-c', "--config-file [config]", "config file path") {|v|
    OPTS[:config] = v
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


  tester = Tester.new(OPTS)

  p "execute"
  tester.execute()
end
