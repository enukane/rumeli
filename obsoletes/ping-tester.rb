require "net/ping"

addr = 'www.ii.ad.jp'
pinger = Net::Ping::External.new(addr)
p pinger.ping?
p pinger.duration
