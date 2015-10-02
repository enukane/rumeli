require "time"

fpath = "/var/lib/dhcp/dhclient.leases"

dhcp_info = {}
File.open(fpath) do |f|
  while line = f.gets
    case line
    when /interface "(.*)";$/
      dhcp_info = {}
      dhcp_info["interface"] = $1
    when /fixed-address (.*);$/
      addr = $1
      p "address is #{addr}"
      dhcp_info["address"] = addr
    when /option subnet-mask (.*);$/
      netmask = $1
      p "netmask is #{netmask}"
      dhcp_info["netmask"] = netmask
    when /option routers (.*);$/
      routers = $1.split(", ")
      p "routers is #{routers}"
      dhcp_info["routers"] = routers
    when /option domain-name-servers (.*);$/
      nameservers = $1.split(", ")
      p "nameservers is #{nameservers}"
      dhcp_info["nameservers"] = nameservers
    when /expire \d+ (.*);$/
      expire = Time.parse($1)
      p "expire is #{expire}"
      dhcp_info["expire"] = expire
    end
  end
end

p dhcp_info

p Time.now - dhcp_info["expire"]
