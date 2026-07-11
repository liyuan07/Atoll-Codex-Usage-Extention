# Atoll Codex Usage

An independent macOS menu-bar extension that displays Codex's 5-hour and
weekly remaining quota in an Atoll notch tab. It talks to Atoll through Atoll's
local JSON-RPC WebSocket server on port 9020.

## Requirements

- macOS 13 or later
- Atoll with third-party extensions and extension notch tabs enabled
- Atoll's RPC server listening on localhost port 9020
- A logged-in Codex CLI (`codex login`)

## Build and run

```sh
bash build.sh
open build/AtollCodexUsage.app
```

On first launch, the extension registers itself with Atoll over RPC and should
appear under Atoll Settings -> Extensions. Open or hover Atoll's notch and use
the Codex extension tab to view the quota panel. The app reads the Codex CLI
access token from `~/.codex/auth.json` only to make a request to
`chatgpt.com/backend-api/wham/usage`; it never persists, logs, or refreshes
that token. The refresh interval is five minutes.

The endpoint and JSON shape are not a public OpenAI API. If they change, the
app keeps the last successful display and reports the refresh failure in its
menu-bar menu.

## Troubleshooting

If the app launches but does not appear in Atoll Settings -> Extensions, first
confirm Atoll's RPC server is running:

```sh
lsof -nP -iTCP:9020 -sTCP:LISTEN
```

If nothing is listening, restart Atoll and make sure third-party extensions are
enabled. Some Atoll builds fail to start the older XPC Mach service with
`Operation not permitted`; this app intentionally uses Atoll's RPC server
instead of that XPC path.

## Tests

```sh
swift run AtollCodexUsageCoreTests
```

The Codex usage parsing was derived from [CodexIsland](https://github.com/ericjypark/codex-island), which is MIT licensed.
