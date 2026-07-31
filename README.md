# ask-rails-harness-mcp

MCP server for Rails app introspection. Exposes all [ask-rails-harness](https://github.com/ask-rb/ask-rails-harness) tools over the [Model Context Protocol](https://modelcontextprotocol.io/).

Coding agents like Claude Code, Cursor, or any MCP-compatible client can connect to inspect your Rails schema, query your database, read models, and more — all through the same tools ask-rails-harness uses internally.

## Installation

```bash
bundle add ask-rails-harness-mcp
```

## Usage

### Option 1: stdio (local development — recommended)

Run from your Rails app root:

```bash
cd my-rails-app
ask-rails-harness-mcp
```

This boots your Rails app and starts an MCP stdio server. Configure in your agent's MCP config:

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

### Option 2: HTTP endpoint (remote/production)

Mount in `config/routes.rb` behind your existing auth:

```ruby
Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    post "ask/mcp", to: "ask/rails/mcp#handle"
  end
end
```

Then configure any MCP-compatible agent:

```json
{
  "mcp": {
    "servers": {
      "ask-rails-harness-mcp": {
        "type": "http",
        "url": "https://myapp.com/ask/mcp"
      }
    }
  }
}
```

The agent discovers 9 tools automatically:

| Tool | What it does |
|---|---|
| `schema_graph` | Full schema introspection — all models, tables, columns, associations, validations |
| `query_database` | Read-only SQL queries with safety guards |
| `read_model` | Introspect a single ActiveRecord model |
| `route_inspector` | Parsed route table with filters |
| `read_log` | Read Rails log files with level/search filtering |
| `search_codebase` | Full-text grep search |
| `read_file` | Read any file from `Rails.root` |
| `run_command` | Run shell commands in the app root |
| `read_routes` | Read the raw `config/routes.rb` |

### Authentication

The MCP endpoint uses the same `Ask::Rails::Harness::Auth` system as the chat UI:

```ruby
Ask::Rails::Harness::Auth.check = -> {
  redirect_to main_app.login_path unless current_user&.admin?
}
```

### Safety

All ask-rails-harness safety features apply automatically:
- **Permissions** — access modes (`:read_only`, `:ask_before_changes`, `:full_access`)
- **Command allowlists** — `allowed_commands` / `denied_commands` for `RunCommand`
- **Write guards** — `INSERT`/`UPDATE`/`DELETE` blocked by `QueryDatabase`
- **Audit log** — every tool call recorded in `ask_audit_logs`

## Development

```bash
bundle exec rake test
```

## License

MIT
