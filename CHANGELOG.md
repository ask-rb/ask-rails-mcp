## [0.2.0] — 2026-07-23

### Added

- **stdio transport** — `Ask::Rails::MCP.start` boots the Rails app and starts a stdio MCP server. Run `ask-rails-mcp` from your Rails app root.
- **`bin/ask-rails-mcp`** — CLI entry point for local development. No web server needed.

## [0.1.0] — 2026-07-23

### Added

- **MCP endpoint** — Mount an MCP server in your Rails app that exposes all ask-rails tools (SchemaGraph, QueryDatabase, ReadModel, RouteInspector, ReadLog, SearchCodebase, ReadFile, RunCommand, ReadRoutes) over the Model Context Protocol.
- **JSON-RPC handler** — `Ask::Rails::MCP.handle` processes MCP messages (`initialize`, `tools/list`, `tools/call`, `ping`) and returns proper JSON-RPC responses.
- **Tool definitions** — All 9 tools are automatically registered with their names, descriptions, and JSON Schema input definitions.
- **Auth** — The MCP endpoint respects `Ask::Rails::Auth.check` for authentication.

### Usage

Mount in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Protect behind your auth
  authenticate :user, ->(u) { u.admin? } do
    post "ask/mcp", to: "ask/rails/mcp#handle"
  end
end
```
