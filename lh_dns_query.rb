require "dnsruby"

class PluginDNSQuery
  TYPE="dns-query"

  def initialize(config)
    @names = config[:names]
    @names_report = {}
  end

  def execute
    @names_report = {}

    resolv = Dnsruby::Resolver.new
    resolv.do_caching = false
    resolv.dnssec = false

    @names.each do |name|
      @names_report[name] = []
      begin
        msg = resolv.query(name, Dnsruby::Types::A)
      rescue
        next
      end
      msg.answer.each do |record|
        @names_report[name] << record.address.to_s
      end
    end
    return @names_report
  end

  def report
    {
      :type => TYPE,
    }.merge(@names_report)
  end

  def cleanup
  end
end

if __FILE__ == $0
  querytest = PluginDNSQuery.new({:names => [
    "www.iij.ad.jp",
    "www.glenda9.org",
    "8.8.8.8",
    "ww.i.a.j"
  ]})

  p querytest.execute
  p querytest.report
end
