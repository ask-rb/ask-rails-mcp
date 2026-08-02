# ask-rails-harness-mcp

[![Gem Version](https://badge.fury.io/rb/ask-rails-harness-mcp.svg)](https://badge.fury.io/rb/ask-rails-harness-mcp)

MCP server for Rails app introspection. Exposes all [ask-rails-harness](https://github.com/ask-rb/ask-rails-harness) tools over the [Model Context Protocol](https://modelcontextprotocol.io/), so coding agents like Claude Code and Cursor can inspect your Rails schema, query your database, read models, and more.

## Installation

```bash
bundle add ask-rails-harness-mcp
```

## Quick Start

Run from your Rails app root. The server boots your app and speaks MCP over stdio (stdin/stdout):

```bash
cd my-rails-app
ask-rails-harness-mcp
```

Configure it in your agent's MCP config:

```json
{
  "mcp": {
    "servers": {
      "ask-rails-harness-mcp": {
        "type": "stdio",
        "command": "ask-rails-harness-mcp",
        "args": []
      }
    }
  }
}
```

stdio is the only shipped transport.

## Tools

The agent discovers 9 tools:

| Tool | What it does |
|---|---|
| `schema_graph` | Full schema introspection: models, tables, columns, associations |
| `query_database` | Read-only SQL queries with safety guards |
| `read_model` | Introspect a single ActiveRecord model |
| `route_inspector` | Parsed route table with filters |
| `read_log` | Read Rails log files with level/search filtering |
| `search_codebase` | Full-text grep search |
| `read_file` | Read any file from `Rails.root` |
| `run_command` | Run shell commands in the app root |
| `read_routes` | Read the raw `config/routes.rb` |

## Essential API

`Ask::Rails::MCP` exposes four entry points:

- `start`: start the stdio server (what the `ask-rails-harness-mcp` binary runs)
- `handle(json_string)`: handle a raw JSON-RPC message string
- `process_message(msg)`: handle a parsed JSON-RPC message hash
- `tools`: the 9 harness tools as MCP tool instances

To serve MCP from your own endpoint, parse the request body and return the response hash:

```ruby
render json: Ask::Rails::MCP.process_message(JSON.parse(request.body.read))
```

All ask-rails-harness safety features apply: environment permission modes, `allowed_commands`/`denied_commands`, read-only query guards, and audit logging of every tool call.

## Full documentation

The full ask-rb documentation lives at https://ask-rb.github.io/ask-docs. [Rails MCP](https://ask-rb.github.io/ask-docs/rails/mcp) covers ask-rails-harness-mcp in depth. API reference: https://ask-rb.github.io/ask-docs/reference/api.

## Development

```bash
bundle exec rake test
```

## License

MIT
