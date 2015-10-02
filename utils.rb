
class Utils
  REG_BSSID=/^(?<bssid>..:..:..:..:..:..) /
  REG_ESSID=/^SSID: (.*)$/


  def self.list_iw_phy
    io = IO.popen("sudo iw phy | grep Wiphy")
    data = io.read
    io.close

    return data.split(/^Wiphy /).map{|str| str.strip}.select{|str| str.match(/^phy\d+$/) }
  end

  def self.get_first_iw_phy
    return self.list_iw_phy[0]
  end

  def self.list_iw_dev
    io = IO.popen("sudo iw dev | grep Interface")
    data = io.read
    io.close
    return data.split(/Interface /).map{|str| str.strip}.select{|str| str.match(/^wlan\d$/)}
  end

  def self.get_first_iw_dev
    return self.list_iw_dev[0]
  end

  def self.scan(ifname)
    ary = []

    system("ip link set #{ifname} up")
    io = IO.popen("iw #{ifname} scan")
    data = io.read
    io.close

    ary = data.split(/^BSS /).map{|str| str.split(/[\r\n]/)}.map{|ary|
      found_bssid = nil
      found_essid = nil
      ary.each do |line|
        line = line.strip
        case line
        when REG_BSSID
          found_bssid = $1
        when REG_ESSID
          found_essid = $1
        end
      end

      if found_bssid != nil && found_essid != nil
        {
          :essid => found_essid,
          :bssid => found_bssid,
        }
      else
        nil
      end
    }.compact

    return ary
  end
end
