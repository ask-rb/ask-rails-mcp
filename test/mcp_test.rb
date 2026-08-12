# frozen_string_literal: true

require_relative "test_helper"
require "json"

class McpTest < Minitest::Test
  def setup
    Ask::Rails::MCP.reset!
  end

  # --- Tools registry ---

  def test_tools_are_loaded
    tools = Ask::Rails::MCP.tools
    assert_kind_of Array, tools
    refute_empty tools, "Should have at least one tool"
  end

  def test_tools_include_schema_graph
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "schema_graph"
  end

  def test_tools_include_query_database
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "query_database"
  end

  def test_tools_include_read_model
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "read_model"
  end

  def test_tools_include_route_inspector
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "route_inspector"
  end

  def test_tools_include_read_log
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "read_log"
  end

  def test_tools_include_run_tests
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "run_tests"
  end

  def test_tools_include_run_command
    names = Ask::Rails::MCP.tools.map(&:name)
    assert_includes names, "run_command"
  end

  def test_tool_server_defines_all_tools
    defs = Ask::Rails::MCP.tool_server.definitions
    assert_equal 7, defs.length, "Should define all 7 ask-rails-harness tools"

    def_names = defs.map { |d| d[:name] }
    %w[schema_graph query_database read_model route_inspector read_log
       run_command run_tests].each do |name|
      assert_includes def_names, name, "Missing tool: #{name}"
    end
  end

  def test_tool_definitions_have_descriptions
    Ask::Rails::MCP.tool_server.definitions.each do |d|
      refute_empty d[:description], "Tool #{d[:name]} should have a description"
      assert_kind_of Hash, d[:inputSchema], "Tool #{d[:name]} should have inputSchema"
    end
  end

  # --- MCP Protocol: initialize ---

  def test_initialize_response
    msg = {
      "jsonrpc" => "2.0",
      "method" => "initialize",
      "params" => { "protocolVersion" => "2025-06-18" },
      "id" => 1
    }
    result = handle(msg)

    assert_equal "2.0", result["jsonrpc"]
    assert_equal 1, result["id"]
    assert result.key?("result")
    assert result["result"].key?("protocolVersion")
    assert result["result"].key?("capabilities")
    assert result["result"].key?("serverInfo")
    assert_equal "ask-rails-harness-mcp", result["result"]["serverInfo"]["name"]
  end

  # --- MCP Protocol: tools/list ---

  def test_tools_list
    # Must initialize first
    handle("jsonrpc" => "2.0", "method" => "initialize", "params" => {}, "id" => 1)
    handle("jsonrpc" => "2.0", "method" => "notifications/initialized", "params" => {})

    result = handle("jsonrpc" => "2.0", "method" => "tools/list", "id" => 2)

    assert_equal 2, result["id"]
    assert result.key?("result")
    tools = result["result"]["tools"]
    assert_kind_of Array, tools
    assert_operator tools.length, :>=, 7, "Should have at least 7 tools"

    tool_names = tools.map { |t| t["name"] }
    assert_includes tool_names, "schema_graph"
  end

  # --- MCP Protocol: tools/call ---

  def test_tools_call_schema_graph
    handle("jsonrpc" => "2.0", "method" => "initialize", "id" => 1)
    handle("jsonrpc" => "2.0", "method" => "notifications/initialized", "params" => {})

    result = handle(
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => { "name" => "schema_graph", "arguments" => { "detail" => "models" } },
      "id" => 3
    )

    assert_equal 3, result["id"]
    assert result.key?("result")
    refute result["result"]["isError"], "schema_graph should succeed"
  end

  def test_tools_call_query_database_rejects_write
    handle("jsonrpc" => "2.0", "method" => "initialize", "id" => 1)
    handle("jsonrpc" => "2.0", "method" => "notifications/initialized", "params" => {})

    result = handle(
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => { "name" => "query_database", "arguments" => { "sql" => "DROP TABLE users" } },
      "id" => 4
    )

    assert result["result"]["isError"], "Write queries should be rejected"
    assert_includes result["result"]["content"][0]["text"], "rejected"
  end

  def test_tools_call_read_model_not_found
    handle("jsonrpc" => "2.0", "method" => "initialize", "id" => 1)
    handle("jsonrpc" => "2.0", "method" => "notifications/initialized", "params" => {})

    result = handle(
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => { "name" => "read_model", "arguments" => { "name" => "NonExistentModel" } },
      "id" => 5
    )

    assert result["result"]["isError"], "Missing model should return error"
  end

  def test_tools_call_unknown_tool
    handle("jsonrpc" => "2.0", "method" => "initialize", "id" => 1)
    handle("jsonrpc" => "2.0", "method" => "notifications/initialized", "params" => {})

    result = handle(
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => { "name" => "nonexistent_tool_xyz" },
      "id" => 6
    )

    assert result["result"]["isError"]
    assert_includes result["result"]["content"][0]["text"], "not found"
  end

  # --- MCP Protocol: ping ---

  def test_ping
    msg = { "jsonrpc" => "2.0", "method" => "ping", "id" => 7 }
    result = handle(msg)
    assert_equal 7, result["id"]
    assert_equal({}, result["result"])
  end

  # --- MCP Protocol: unknown method ---

  def test_unknown_method
    msg = { "jsonrpc" => "2.0", "method" => "unknown_method_xyz", "id" => 8 }
    result = handle(msg)
    assert_equal 8, result["id"]
    assert result.key?("error")
    assert_equal(-32601, result["error"]["code"])
  end

  # --- MCP Protocol: malformed JSON ---

  def test_parse_error
    result = ask_rails_mcp_handle(nil)
    assert result.key?("error")
    assert_equal(-32700, result["error"]["code"])
  end

  private

  def handle(msg)
    ask_rails_mcp_handle(JSON.generate(msg))
  end

  def ask_rails_mcp_handle(json_string)
    result = nil
    error = nil
    begin
      result = Ask::Rails::MCP.handle(json_string)
    rescue => e
      error = e
    end
    return { "error" => { "code" => -32700, "message" => error.message } } if error
    result
  end
end
