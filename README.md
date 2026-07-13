# Atoll Codex Usage

An independent macOS menu-bar extension that displays Codex's 5-hour and
weekly remaining quota in an Atoll notch tab. It talks to Atoll through Atoll's
local JSON-RPC WebSocket server on port 9020.

## Requirements

- macOS 13 or later
- Atoll with third-party extensions and extension notch tabs enabled
- Atoll's RPC server listening on localhost port 9020
- A logged-in Codex CLI (`codex login`)

## Install

Download the ZIP for your Mac from the
[latest GitHub Release](https://github.com/liyuan07/Atoll-Codex-Usage-Extention/releases/latest):

- `arm64` for Apple Silicon Macs with an M-series chip

Unzip it, move `AtollCodexUsage.app` to Applications, then right-click the app
and choose Open on first launch. Release builds are ad-hoc signed, not notarized
with an Apple Developer certificate.

## Build and run

```sh
bash build.sh
open build/AtollCodexUsage.app
```

On first launch, the extension registers itself with Atoll over RPC and should
appear under Atoll Settings -> Extensions. Open or hover Atoll's notch and use
the Codex extension tab to view the quota panel. The panel is a compact
visual dashboard with segmented quota bars; click the dots or use left/right
arrow keys after focusing the panel to switch views. The app reads the Codex
CLI access token from `~/.codex/auth.json` only to make a request to
`chatgpt.com/backend-api/wham/usage`; it never persists, logs, or refreshes
that token. The refresh interval is five minutes.

If macOS rejects that request in `URLSession` because of a local TLS setup, the
app retries via the system `curl`; the bearer token is passed through standard
input rather than a command-line argument.

The current Codex usage response exposes 5-hour and weekly quota windows only.
The second dashboard page supplements those quota windows with actual local
Codex CLI token throughput for rolling 5-hour, 24-hour, and 7-day periods. It
reads only recent `~/.codex/sessions/**/rollout-*.jsonl` token-count records;
those logs never leave the Mac.

Atoll's current RPC plugin surface exposes a dedicated extension notch tab. It
does not let plugins inject content into the built-in Home tab or choose the
global tab-strip alignment.

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

Maintainers can publish a release by pushing a semantic version tag such as
`v0.1.0`. GitHub Actions builds the Apple Silicon version, creates a SHA-256
checksum, and attaches both files to the GitHub Release automatically.

The Codex usage parsing was derived from [CodexIsland](https://github.com/ericjypark/codex-island), which is MIT licensed.
