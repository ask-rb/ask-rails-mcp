# frozen_string_literal: true

require_relative "lib/ask/rails/mcp/version"

Gem::Specification.new do |spec|
  spec.name = "ask-rails-mcp"
  spec.version = Ask::Rails::MCP::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "MCP server for Rails app introspection — exposes ask-rails tools over the Model Context Protocol"
  spec.description = <<~DESC
    Mount an MCP endpoint in your Rails app that exposes SchemaGraph, QueryDatabase,
    ReadModel, RouteInspector, and all other ask-rails tools as MCP tools.
    Coding agents like Claude Code, Cursor, or any MCP-compatible client can
    connect to inspect your schema, query your database, read models, and more.
  DESC

  spec.homepage = "https://github.com/ask-rb/ask-rails-mcp"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ask-rails", ">= 0.10"
  spec.add_dependency "ask-mcp", ">= 0.1"
  spec.add_dependency "rails", ">= 7.1"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "mocha", "~> 2.0"
end
