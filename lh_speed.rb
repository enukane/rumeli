require "open3"
class PluginCurlSpeed
  TYPE="curl-speed"
  def initialize(config)
    @url = config[:url]
    @speed = 0
  end

  def execute
    stdin, stdout, stderr, th = *Open3.popen3(
      "curl #{@url} -o /dev/null -w \"%{speed_download}\n\" 2>/dev/null"
    )
    th.join
    @speed = stdout.read.to_f
    return @speed
  end

  def report
    {
      :type => TYPE,
      :speed => @speed
    }
  end

  def cleanup
  end
end

if __FILE__ == $0
  speedtest = PluginCurlSpeed.new(
    { :url => "http://www.google.com" }
  )
  p speedtest.execute
  p speedtest.report
end
