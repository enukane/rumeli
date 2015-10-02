require_relative "utils"

class PluginWlanScan
  TYPE="wlan-scan"

  def initialize(config)
    @ifname = config[:ifname] || "wlan0"
    @essid = config[:essid]
    @bssid = config[:bssid]

    @found = false
    @found_set = []
  end

  def execute
    list = Utils.scan(@ifname)
    match_list = list.select{|item|
      if @bssid == nil
        (item[:essid] == @essid)
      else
        (item[:essid] == @essid and item[:bssid] == @bssid)
      end
    }

    @found = true if match_list.length > 0
    @found_set = match_list
    return @found
  end

  def report
    {
      :type => TYPE,
      :found => @found_set,
    }
  end

  def cleanup
  end
end

if __FILE__ == $0
  scantest = PluginWlanScan.new({
    :ifname  => "wlan2",
    :essid   => "TESTNet",
    :bssid   => "00:00:00:00:03:24",
  })

  p scantest.execute
  p scantest.report
end
