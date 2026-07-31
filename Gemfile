source "https://rubygems.org"

gemspec

# Local development — use local paths for ask-rb gems
ask_rb_root = File.expand_path("..", __dir__)
%w[ask-core ask-tools ask-tools-shell ask-schema ask-auth ask-instrumentation ask-llm-providers ask-agent ask-rails-harness ask-mcp].each do |gem_name|
  gem gem_name, path: File.join(ask_rb_root, gem_name)
end

group :test do
  gem "minitest", "~> 5.25"
  gem "rake", "~> 13.0"
  gem "mocha", "~> 2.0"
end
