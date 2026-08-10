# ask-rails-harness-mcp

[![Gem Version](https://badge.fury.io/rb/ask-rails-harness-mcp.svg)](https://badge.fury.io/rb/ask-rails-harness-mcp)

MCP server for Rails app introspection. Exposes all [ask-rails-harness](https://github.com/ask-rb/ask-rails-harness) tools over the [Model Context Protocol](https://modelcontextprotocol.io/), so coding agents like Claude Code and Cursor can inspect your Rails schema, query your database, read models, and more.

## Installation

```bash
bundle add ask-rails-harness-mcp
```

## Quick Start

Add the gem to your Rails app, then run the server from the app root via Bundler — this pins gem versions to the app's `Gemfile.lock`, which is required (loading the harness against the newest installed gems can activate conflicting versions and abort the boot):

```bash
bundle add ask-rails-harness-mcp
bundle exec ask-rails-harness-mcp
```

Configure it in your agent's MCP config, pointing `cwd` at your Rails app root (add `timeoutMs` if the app is slow to boot):

```json
{
  "mcp": {
    "servers": {
      "ask-rails-harness-mcp": {
        "type": "stdio",
        "command": "bundle",
        "args": ["exec", "ask-rails-harness-mcp"],
        "cwd": "/path/to/my-rails-app",
        "timeoutMs": 60000
      }
    }
  }
}
```

stdio is the only shipped transport.

## Tools

The agent discovers 7 tools:

| Tool | What it does |
|---|---|
| `schema_graph` | Full schema introspection: models, tables, columns, associations |
| `query_database` | Read-only SQL queries with safety guards |
| `read_model` | Introspect a single ActiveRecord model |
| `route_inspector` | Parsed route table with filters |
| `read_log` | Read log files with level/search filtering |
| `run_command` | Run shell commands in the app root |
| `run_tests` | Structured test results with failure reruns (minitest/rspec) |

The six generic tools come from `ask-ruby-harness` (usable in any Ruby
project — see the [Ruby Harness MCP guide](https://ask-rb.github.io/ask-docs/ruby/mcp));
`route_inspector` is Rails-native.

## Essential API

`Ask::Rails::MCP` exposes four entry points:

- `start`: start the stdio server (what the `ask-rails-harness-mcp` binary runs)
- `handle(json_string)`: handle a raw JSON-RPC message string
- `process_message(msg)`: handle a parsed JSON-RPC message hash
- `tools`: the harness tools as MCP tool instances

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
