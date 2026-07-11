# Atoll Codex Usage

An independent macOS menu-bar extension that displays Codex's 5-hour and
weekly used quota in an Atoll Live Activity.

## Requirements

- macOS 13 or later
- Atoll with third-party extensions and extension live activities enabled
- A logged-in Codex CLI (`codex login`)

## Build and run

```sh
bash build.sh
open build/AtollCodexUsage.app
```

On first launch, approve the extension in Atoll. The app reads the Codex CLI
access token from `~/.codex/auth.json` only to make a request to
`chatgpt.com/backend-api/wham/usage`; it never persists, logs, or refreshes
that token. The refresh interval is five minutes.

The endpoint and JSON shape are not a public OpenAI API. If they change, the
app keeps the last successful display and reports the refresh failure in its
menu-bar menu.

## Troubleshooting

If the app launches but does not appear in Atoll Settings -> Extensions, restart
Atoll and launch this app again. Atoll must successfully register its XPC Mach
service (`com.ebullioscopic.Atoll.xpc`) before third-party apps can request
authorization.

On macOS App Sandbox builds, Atoll's main app entitlement must include:

```xml
<key>com.apple.security.temporary-exception.mach-register.global-name</key>
<array>
    <string>com.ebullioscopic.Atoll.xpc</string>
</array>
```

This repository's `DynamicIsland/DynamicIsland.entitlements` has been updated
with that key. Rebuild and reinstall Atoll from source if your installed Atoll
logs `listener failed to activate: xpc_error=[1: Operation not permitted]`.

## Tests

```sh
swift run AtollCodexUsageCoreTests
```

The Codex usage parsing was derived from [CodexIsland](https://github.com/ericjypark/codex-island), which is MIT licensed.
