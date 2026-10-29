# claude-usage-bar

A tiny Claude Code status line with **bars** for your 5-hour and weekly usage limits, plus a countdown until your **prompt cache** goes cold.

```
5h ████░░░░░░ 42% ↻2h1m  │  wk █████████░ 91% ↻3d11h  │  cache ███████░░░ 3m32s
```

- Green / yellow / red at 70% and 90%
- `↻` = time until that window resets
- `cache` counts down from your last Claude reply (prompt cache TTL); turns `cold` when expired, so you know whether the next message will be a cheap cache hit

## Install

Needs `jq` and `bash`.

```sh
curl -fsSL https://raw.githubusercontent.com/shrijayan/claude-usage-bar/main/install.sh | bash
```

Restart Claude Code. Your previous status line is backed up and restored on uninstall:

```sh
curl -fsSL https://raw.githubusercontent.com/shrijayan/claude-usage-bar/main/install.sh | bash -s -- --uninstall
```

## Config

Set env vars before launching `claude`:

| Var | Default | |
|---|---|---|
| `CUB_WIDTH` | `10` | bar width in characters |
| `CUB_CACHE_TTL` | `300` | cache TTL in seconds (use `3600` if you use 1-hour caching) |

## Notes

- 5h/weekly data comes from the `rate_limits` field Claude Code passes to status lines. It's only present for Claude.ai subscribers (Pro/Max) after the first response in a session.
- The cache timer is an estimate based on the last assistant message timestamp in the transcript.

## License

MIT
