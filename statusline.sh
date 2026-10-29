#!/usr/bin/env bash
# claude-usage-bar: 5h / weekly usage bars + prompt-cache countdown for Claude Code.
# Env: CUB_WIDTH (bar width, default 10), CUB_CACHE_TTL (seconds; default auto-detect, else 300).
input=$(cat)
W=${CUB_WIDTH:-10}
TTL=${CUB_CACHE_TTL:-300}
NOW=$(date +%s)

# Last assistant message time from the transcript = last cache write/read.
# TTL is auto-detected from the most recent cache write (1h vs 5m) unless CUB_CACHE_TTL is set.
tp=$(jq -r '.transcript_path // empty' <<<"$input")
last=0
if [ -n "$tp" ] && [ -f "$tp" ]; then
  read -r last ttl_seen < <(tail -n 400 "$tp" | jq -rs '
    [.[] | select(.type=="assistant" and .timestamp)] as $a
    | ($a | last | .timestamp // empty | sub("\\.[0-9]+";"") | fromdateiso8601) as $t
    | ([$a[] | .message.usage.cache_creation // empty
        | if (.ephemeral_1h_input_tokens // 0) > 0 then 3600
          elif (.ephemeral_5m_input_tokens // 0) > 0 then 300 else empty end] | last // 0) as $ttl
    | "\($t) \($ttl)"' 2>/dev/null) || true
fi
if [ -z "${CUB_CACHE_TTL:-}" ] && [ "${ttl_seen:-0}" -gt 0 ] 2>/dev/null; then TTL=$ttl_seen; fi

jq -rj --argjson w "$W" --argjson ttl "$TTL" --argjson now "$NOW" --argjson last "${last:-0}" '
  def color(p): if p >= 90 then "\u001b[31m" elif p >= 70 then "\u001b[33m" else "\u001b[32m" end;
  def barc(p; c): (p | if . > 100 then 100 elif . < 0 then 0 else . end) as $p
    | (($p * $w / 100) | round) as $f
    | c + ("█" * $f) + "\u001b[2m" + ("░" * ($w - $f)) + "\u001b[0m";
  def bar(p): barc(p; color(p));
  def dur(s): if s >= 86400 then "\(s/86400|floor)d\(s%86400/3600|floor)h"
              elif s >= 3600 then "\(s/3600|floor)h\(s%3600/60|floor)m"
              else "\(s/60|floor)m\(s%60|floor)s" end;
  def win(name; o): if o then
      "\(name) \(bar(o.used_percentage)) \(o.used_percentage|round)% ↻\(dur((o.resets_at - $now) | if . < 0 then 0 else . end))"
    else empty end;
  def cache: if $last > 0 then ($last + $ttl - $now) as $r
      | if $r > 0 then
          (if $r < 60 then "\u001b[31m" elif $r < 120 then "\u001b[33m" else "\u001b[36m" end) as $c
          | "cache \(barc(100 * $r / $ttl; $c)) \(dur($r))"
        else "cache \u001b[2mcold\u001b[0m" end
    else empty end;
  [ win("5h"; .rate_limits.five_hour), win("wk"; .rate_limits.seven_day), cache ]
  | join("  │  ")
' <<<"$input"
