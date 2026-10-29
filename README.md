# claude-usage-bar

Shows your Claude Code **5-hour** and **weekly** usage limits as bars, plus a countdown until your **prompt cache** goes cold.

```
5h ━━━━━━━━━━ 5% ↻1h23m  ·  week ━━━━━━━━━━ 42% ↻22h53m  ·  cache ━━━━━━━━━━ 48m31s
```

- Green / yellow / red at 70% and 90%; `↻` = time until that window resets
- `cache` counts down from Claude's last reply and shows `cold` when expired, so you know if the next message is a cheap cache hit

Two flavours:

## Band above the prompt (recommended)

A Claude Code plugin. In a Claude Code session:

```
/plugin install usage-band --marketplace shrijayan/claude-usage-bar
```

Answer `y` to add the marketplace, pick a scope, done. Or from a shell:

```sh
claude plugin install usage-band --marketplace shrijayan/claude-usage-bar
```

Cache TTL defaults to 60 minutes; switch with `/cache-ttl 5` or `/cache-ttl 60`.

**Updating:** `/plugin marketplace update claude-usage-bar`, then restart Claude Code.

## Status line (alternative)


Needs `jq` and `bash`.

```sh
curl -fsSL https://raw.githubusercontent.com/shrijayan/claude-usage-bar/main/install.sh | bash
```

Restart Claude Code. Your previous status line is backed up and restored on uninstall:

```sh
curl -fsSL https://raw.githubusercontent.com/shrijayan/claude-usage-bar/main/install.sh | bash -s -- --uninstall
```

### Status line config

Set env vars before launching `claude`:

| Var | Default | |
|---|---|---|
| `CUB_WIDTH` | `10` | bar width in characters |
| `CUB_CACHE_TTL` | auto | cache TTL in seconds; auto-detected (1h or 5m) from the last cache write, falls back to `300` |

## Notes

- 5h/weekly data comes from the `rate_limits` field Claude Code passes to status lines. It's only present for Claude.ai subscribers (Pro/Max) after the first response in a session.
- The cache timer is an estimate based on the last assistant message timestamp in the transcript.

## License

MIT
