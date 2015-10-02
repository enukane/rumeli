require "time"

class PluginDHCPGetAddress
  TYPE="dhcp-get-address"

  LEASE_INFO_PATH="/var/lib/dhcp/dhclient.leases"

  def initialize(config)
    @ifname = config[:ifname] || "wlan0"
    @dhcp_info = {
      :address     => "",
      :netmask     => "",
      :routers     => [],
      :nameserver  => [],
      :expire      => "",
    }
  end

  def execute
    system("dhclient #{@ifname} 2>/dev/null")
    now = Time.now
    File.open(LEASE_INFO_PATH) do |f|
      while line = f.gets
        case line
        when /interface "(.*)";$/
          @dhcp_info[:interface] = $1
        when /fixed-address (.*);$/
          addr = $1
          @dhcp_info[:address] = addr
        when /option subnet-mask (.*);$/
          netmask = $1
          @dhcp_info[:netmask] = netmask
        when /option routers (.*);$/
          routers = $1.split(", ")
          @dhcp_info[:routers] = routers
        when /option domain-name-servers (.*);$/
          nameservers = $1.split(", ")
          @dhcp_info[:nameservers] = nameservers
        when /expire \d+ (.*);$/
          expire = Time.parse($1)
          @dhcp_info[:expire] = expire
        end
      end
    end

    if Time.now - @dhcp_info[:expire] > 0
      @dhcp_info = {}
    end
    return @dhcp_info
  end

  def report
    {
      :type => TYPE,
    }.merge(@dhcp_info)
  end

  def cleanup
    system("killall dhclient")
  end
end

if __FILE__ == $0
  dhcptest = PluginDHCPGetAddress.new({:ifname => "wlan2"})
  p dhcptest.execute
  p dhcptest.report
end
