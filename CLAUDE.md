# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tauper is a multiplayer chemistry quiz game built with Elixir and Phoenix LiveView. Players answer questions about chemical elements (symbols, names, and valences) in real-time, competing for points based on speed and accuracy.

## Development Commands

### Setup
```bash
mix deps.get          # Install dependencies
mix setup             # Run setup alias
```

### Development Server
```bash
mix phx.server        # Start Phoenix server on localhost:4000
```

Development tools available at:
- LiveDashboard: http://localhost:4000/dashboard
- Swoosh mailbox preview: http://localhost:4000/dev/mailbox

### Testing
```bash
mix test              # Run all tests
```

### Translations
```bash
mix gettext.extract --merge    # Extract and merge translation strings
```

### Deployment
```bash
fly deploy            # Deploy to fly.io
```

### Assets
```bash
mix assets.deploy     # Build and minify assets for production
```

## Architecture

### Game State Management

The application uses OTP principles with a dynamic supervisor to manage concurrent game sessions:

- **Registry** (`game_registry`): Named registry for game process lookup by game code
- **Tauper.Games.Supervisor**: DynamicSupervisor that spawns individual game server processes
- **Tauper.Games.Server**: GenServer managing individual game state, including:
  - Question generation and progression
  - Player scoring with time-based points
  - Game status transitions (`:not_started`, `:started`, `:paused`, `:game_over`)
  - Timer-based question countdowns (broadcasts `:tick` every second)

Each game runs as an isolated GenServer process registered with a unique 3-digit code.

### LiveView Flow

Two main LiveView modules handle the user experience:

1. **TauperWeb.GameLive.Show** (`/games/:code`): Game lobby view
2. **TauperWeb.GameLive.Play** (`/games/play/:code`): Active gameplay view with real-time updates

Both use `on_mount` hooks for session validation and game state initialization.

### Real-time Communication

- **Phoenix.PubSub**: Broadcasts game events to all connected players
- **Phoenix.Presence**: Tracks active players per game, prevents duplicate player names
- **Events broadcasted**:
  - `game_status_changed`: Game state transitions
  - `question_tick`: Countdown timer updates
  - `question_answered`: Answer submission updates
  - `presence_diff`: Player join/leave events

### Question System

Questions are generated from `Tauper.Games.Tables.EducemFar` periodic table data with three types:
- `"symbol"`: Given element name, find symbol
- `"name"`: Given symbol, find element name
- `"valences"`: Given element name, list valence states

Questions are shuffled and filtered by:
- Number of questions (default: 20)
- Question types (configurable subset)
- Element groups (1-18, configurable)

### Scoring

- Points awarded based on remaining time when answering correctly (1-20 seconds = 1-20 points)
- Each player can only answer each question once
- Game auto-pauses when all active players have answered
- Podium calculated by summing all question scores per player

### Session Management

Custom plugs handle user state:
- **TauperWeb.Plugs.Locale**: Manages i18n locale selection
- **TauperWeb.Plugs.SessionToAssignPlug**: Transfers session data to connection assigns

## Project Structure

```
lib/tauper/
├── application.ex              # OTP application entry point
├── games.ex                    # Context module - public API for game operations
├── games/
│   ├── server.ex               # GenServer managing individual game state
│   ├── supervisor.ex           # DynamicSupervisor for game processes
│   └── tables/
│       └── educemfar_table.ex  # Periodic table data source
└── email/                      # Email functionality (score reports)

lib/tauper_web/
├── router.ex                   # Route definitions
├── endpoint.ex                 # Phoenix endpoint
├── channels/
│   └── presence.ex             # Player presence tracking
├── controllers/
│   ├── game_controller.ex      # Game CRUD and join actions
│   └── page_controller.ex      # Landing page
├── live/
│   └── game_live/
│       ├── show.ex             # Game lobby LiveView
│       ├── play.ex             # Active game LiveView
│       └── component.ex        # Shared components
├── plugs/                      # Custom plugs for session/locale
└── templates/                  # EEx templates
```

## Internationalization

Uses Gettext with translations in `priv/gettext/`:
- `ca/` - Catalan
- `en/` - English

Questions are localized via `gettext/1` calls in `Tauper.Games.Server.build_sentence/1`.

## Dependencies Notes

- No database - game state is entirely in-memory via GenServer processes
- Phoenix LiveView 0.17.5 for real-time UI updates
- Bcrypt for password hashing (if auth added later)
- Swoosh + Phoenix.Swoosh for email functionality
- esbuild for asset compilation
