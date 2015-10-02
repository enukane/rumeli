require "net/ping"

class PluginPing
  TYPE="ping"

  def initialize(config)
    @addrs = config[:addrs]
    @ping_result = {}
  end

  def execute
    @ping_result = {}
    @addrs.each do |addr|
      begin
        pinger = Net::Ping::External.new(addr)
        pinged = pinger.ping?
        @ping_result[addr] = {
          :ping => pinged,
          :rtt  => pinger.duration
        }
      rescue
        @ping_result[addr] = {
          :ping => false,
          :rtt  => 0,
        }
      end
    end
    @ping_result
  end

  def report
    {
      :type => TYPE
    }.merge(@ping_result)
  end

  def cleanup
  end
end

if __FILE__ == $0
  pingtest = PluginPing.new({:addrs =>
                             [
                               "192.168.0.1",
                               "8.8.8.8",
                               "0.0.0.0",
                               "www.iij.ad.jp",
                               "ww.ii.a.j",
                             ]
  })

  p pingtest.execute
  p pingtest.report
end


