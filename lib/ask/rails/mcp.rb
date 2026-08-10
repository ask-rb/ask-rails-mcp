# frozen_string_literal: true

require "ask/rails/harness"
require "ask/mcp"
require_relative "mcp/version"

module Ask
  module Rails
    module MCP
      PROTOCOL_VERSION = "2025-06-18"

      class << self
        # All ask-rails-harness tools wrapped as MCP tool instances.
        def tools
          @tools ||= Ask::Rails::Harness::CORE_RAILS_TOOLS.map(&:new)
        end

        # Tool server adapter that dispatches tools/call requests.
        def tool_server
          @tool_server ||= Ask::MCP::Adapters::ToolServer.new(tools)
        end

        # Handle a raw JSON-RPC message string.
        # Returns a Hash suitable for JSON serialization.
        def handle(json_string)
          msg = JSON.parse(json_string)
          process_message(msg)
        rescue JSON::ParserError => e
          error_response(nil, -32700, "Parse error: #{e.message}")
        end

        # Handle a parsed JSON-RPC message hash.
        def process_message(msg)
          method_name = msg["method"]
          id = msg["id"]
          params = msg["params"] || {}
          has_id = msg.key?("id")

          case method_name
          when "initialize"
            handle_initialize(id, params)
          when "notifications/initialized"
            @initialized = true
            nil  # Notification — no response
          when "tools/list"
            @initialized ? handle_tools_list(id) : error_response(id, -32000, "Server not initialized")
          when "tools/call"
            @initialized ? handle_tool_call(id, params) : error_response(id, -32000, "Server not initialized")
          when "ping"
            has_id ? success_response(id, {}) : nil
          else
            has_id ? error_response(id, -32601, "Method not found: #{method_name}") : nil
          end
        end

        # Process an initialize request.
        def handle_initialize(id, params)
          @initialized = true
          client_version = params["protocolVersion"] || PROTOCOL_VERSION
          success_response(id, {
            "protocolVersion" => client_version,
            "capabilities" => { "tools" => {} },
            "serverInfo" => {
              "name" => "ask-rails-harness-mcp",
              "version" => Ask::Rails::MCP::VERSION
            }
          })
        end

        # Process a tools/list request.
        def handle_tools_list(id)
          defs = tool_server.definitions
          success_response(id, { tools: defs })
        end

        # Process a tools/call request.
        def handle_tool_call(id, params)
          tool_name = params["name"]
          arguments = params["arguments"] || {}

          result = tool_server.call(tool_name, arguments)
          success_response(id, result)
        end

        # Start the MCP stdio server, auto-loading the Rails app.
        #
        #   $ ask-rails-harness-mcp
        #
        # The server will listen for JSON-RPC messages on stdin and write
        # responses to stdout — the standard MCP stdio transport. Register
        # this executable as an MCP server in your client configuration:
        #
        #   "mcp": {
        #     "servers": {
        #       "ask-rails-harness-mcp": {
        #         "type": "stdio",
        #         "command": "ask-rails-harness-mcp",
        #         "args": []
        #       }
        #     }
        #   }
        def start
          load_rails_app_quietly
          silence_stdout_loggers

          Ask::MCP::Server.start_stdio(
            name: "ask-rails-harness-mcp",
            tools: tools,
            capabilities: { tools: {} },
            debug: ENV["DEBUG"] == "1"
          )
        end

        # Get or clear the cache (useful in tests).
        def reset!
          @tools = nil
          @tool_server = nil
          @initialized = false
        end

        private

        # Boot the app with stdout pointed at stderr: Rails/OTel loggers
        # default to STDOUT in development, and boot-time output would
        # corrupt the JSON-RPC stream the server writes to stdout.
        def load_rails_app_quietly
          real_stdout = STDOUT.dup
          STDOUT.reopen(STDERR)
          begin
            load_rails_app
          ensure
            STDOUT.reopen(real_stdout)
          end
        end

        # Point app loggers at stderr so tool calls (AR queries, shell
        # commands, ...) can't interleave with JSON-RPC responses.
        def silence_stdout_loggers
          require "logger"
          $stderr.sync = true
          stderr_logger = ::Logger.new($stderr)
          stderr_logger.level = ::Logger::INFO
          if defined?(OpenTelemetry) && OpenTelemetry.respond_to?(:logger=)
            OpenTelemetry.logger = stderr_logger
          end
          return unless defined?(Rails)

          Rails.logger = stderr_logger if Rails.respond_to?(:logger=)
          ActiveRecord::Base.logger = stderr_logger if defined?(ActiveRecord::Base)
        end

        def load_rails_app
          return if defined?(::Rails) && ::Rails.application
          require File.expand_path("config/environment")
        rescue LoadError => e
          warn "ask-rails-harness-mcp: failed to boot the Rails app: #{e.message}"
          warn "Run it from your Rails app root with the gem in the Gemfile (bundle add ask-rails-harness-mcp)."
          exit 1
        end

        def success_response(id, result)
          { "jsonrpc" => "2.0", "id" => id, "result" => deep_stringify_keys(result) }
        end

        def error_response(id, code, message)
          { "jsonrpc" => "2.0", "id" => id, "error" => { "code" => code, "message" => message } }
        end

        def deep_stringify_keys(obj)
          case obj
          when Hash then obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify_keys(v) }
          when Array then obj.map { |v| deep_stringify_keys(v) }
          else obj
          end
        end
      end
    end
  end
end
