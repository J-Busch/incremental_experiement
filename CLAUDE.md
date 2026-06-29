# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.5 incremental game experiment ("Incremental Experiement"). Uses the Forward Plus renderer. Entry point is `scenes/main.tscn`.

## Running the Project

Open and run via the Godot 4.5 editor. There is no CLI build or test command — all development happens through the editor UI or via the GDAI MCP plugin (see below).

## GDAI MCP Plugin

The project has the [GDAI MCP plugin](https://gdaimcp.com/) installed (`addons/gdai-mcp-plugin-godot/`, v0.3.2). This plugin exposes an MCP server that allows an AI assistant to directly control the Godot editor: create/edit scenes and nodes, read debugger output, get/set node properties, search the filesystem, and simulate input. The runtime is autoloaded as `GDAIMCPRuntime`.

When the Godot editor is open and the plugin is active, prefer using the MCP tools (`gdai-mcp` server) to create and modify scenes and scripts rather than writing files by hand.

## Architecture

### Phase System

The game alternates between two phases — **shop** and **world** — managed via a signal on the `GameManager` autoload:

- `autoloads/game_manager.gd` — singleton holding global state (`currency: int`) and emitting `phase_changed(new_phase: StringName)` when `go_to_shop()` or `go_to_world()` is called.
- `scenes/main.gd` — root scene; connects to `GameManager.phase_changed` and swaps the active child scene between `shop.tscn` and `game_world.tscn` by freeing the old one and instantiating the new one.
- `scenes/shop.gd` — shop phase UI; reads `GameManager.currency` on ready, calls `GameManager.go_to_world()` when the proceed button is pressed.
- `scenes/game_world.gd` — world phase UI; runs a `PhaseTimer` node, shows a countdown, calls `GameManager.go_to_shop()` on timeout.

### Adding New Game State

All persistent/global game state belongs in `GameManager`. Phase-specific UI state lives in the respective scene script.

## GDScript Conventions

- Scripts use GDScript (`.gd` files); attach them to nodes via the editor or via MCP tools.
- Communicate between nodes using signals rather than direct references where possible; use `GameManager` signals for cross-phase events.
- Use `res://` paths for all project-internal resource references.
- Child nodes are accessed via `$NodeName` shorthand (e.g. `$VBoxContainer/CurrencyLabel`).
