$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Prepend local ask-rb gem paths (prefer local over installed)
ask_rb_root = File.expand_path("../..", __dir__)
%w[ask-core ask-tools ask-tools-shell ask-schema ask-auth ask-instrumentation ask-llm-providers ask-agent ask-rails-harness ask-mcp ask-rails-harness-mcp].each do |gem|
  lib = File.join(ask_rb_root, gem, "lib")
  $LOAD_PATH.unshift lib if File.directory?(lib)
end

# Stub a minimal Rails environment for tools that need it
require "rails"
require "active_support"

module Rails
  class << self
    def root
      Pathname.new("/tmp")
    end
    def env
      @env ||= ActiveSupport::StringInquirer.new("test")
    end
    def env=(environment)
      @env = ActiveSupport::StringInquirer.new(environment.to_s)
    end
  end
end

require "ask-rails-harness-mcp"
require "minitest/autorun"
require "mocha/minitest"
