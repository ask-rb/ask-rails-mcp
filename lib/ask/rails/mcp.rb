# frozen_string_literal: true

require "ask/rails"
require "ask/mcp"
require_relative "mcp/version"

module Ask
  module Rails
    module MCP
      PROTOCOL_VERSION = "2025-06-18"

      class << self
        # All ask-rails tools wrapped as MCP tool instances.
        def tools
          @tools ||= Ask::Rails::CORE_RAILS_TOOLS.map(&:new)
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
              "name" => "ask-rails-mcp",
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

        # Get or clear the cache (useful in tests).
        def reset!
          @tools = nil
          @tool_server = nil
          @initialized = false
        end

        private

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
