module Lighthouse
  require "json"

  class PluginContext
    def initialize(config, target, context)
      @context = {}
      @report = {}
      @config = config
    end
    def get(key)
      @context(key)
    end

    def set(key, val)
      @context[key] = val
    end
  end

  class BasePlugin
    def initialize(context, param)
      @context = context
      @param = param
      setup
    end

    def setup
      raise "setup must be implemented"
    end

    def execute
      raise "execute must be implemented"
    end

    def cleanup
      # not necessary
    end

    def cleanup_all
      # not necessary
    end
  end

  class PluginSleep
    def setup
      @sleep_interval = @param["sleep_interval"] || 5
    end

    def execute
      before = Time.now
      sleep(@sleep_interval)
      after = Time.now
      diff = after - before

      return {"slept_time" => diff}
    end

    def cleanup
      # nothing
    end

    def cleanup_all
      # nothing
    end
  end

  class PluginConnect
    def setup
      @target = @context
    end
  end

end
