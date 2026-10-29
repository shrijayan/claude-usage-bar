import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Limit } from '../types'

const limits = atom({ plugin: 'usage-band', key: 'limits' } as const, [] as Limit[])
const lastCallAt = atom({ plugin: 'usage-band', key: 'lastCallAt' } as const, 0)
const ttlMinutes = atom({ plugin: 'usage-band', key: 'ttlMinutes' } as const, 60)
const now = atom({ plugin: 'usage-band', key: 'now' } as const, 0)

const WIDTH = 10

const color = (pct: number) => (pct >= 90 ? 'red' : pct >= 70 ? 'yellow' : 'green')

const dur = (ms: number) => {
  const s = Math.max(0, Math.floor(ms / 1000))
  if (s >= 86400) return `${Math.floor(s / 86400)}d${Math.floor((s % 86400) / 3600)}h`
  if (s >= 3600) return `${Math.floor(s / 3600)}h${Math.floor((s % 3600) / 60)}m`
  return `${Math.floor(s / 60)}m${String(s % 60).padStart(2, '0')}s`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'cache-ttl', description: 'Set the prompt-cache TTL the usage band counts down: 5 or 60 minutes' })
    const { rateLimits } = await $.session.usage()
    await update($, limits, () => rateLimits)
    const t0 = await $.clock.now()
    await update($, now, () => t0)
    $.clock.every(1000, async () => {
      const t = await $.clock.now()
      await update($, now, () => t)
    })

    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    await update($, limits, () => e.rateLimits)

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const t = await $.clock.now()
    await update($, lastCallAt, () => t)

    return next(e)
  })

  on('command.run', { command: 'cache-ttl' }, async ($, e) => {
    const minutes = Number(e.args.trim())
    if (minutes !== 5 && minutes !== 60) return { text: 'Usage: /cache-ttl 5 | 60' }
    await update($, ttlMinutes, () => minutes)

    return { text: `Cache countdown set to ${minutes} minutes.` }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const t = await read($, now)
    const windows = await read($, limits)
    const last = await read($, lastCallAt)
    const ttl = (await read($, ttlMinutes)) * 60_000
    if (e.props.hasSurvey || (windows.length === 0 && last === 0)) return next(e)

    const { Box, Text } = $.ui.resolve(e)

    const bar = (pct: number, fill: string) => {
      const n = Math.round((Math.min(100, Math.max(0, pct)) / 100) * WIDTH)
      return (
        <Text>
          <Text color={fill}>{'━'.repeat(n)}</Text>
          <Text dimColor>{'━'.repeat(WIDTH - n)}</Text>
        </Text>
      )
    }

    const sep = <Text dimColor>{'  ·  '}</Text>
    const items = []

    for (const [kind, label] of [['five_hour', '5h'], ['seven_day', 'week']] as const) {
      const w = windows.find(x => x.kind === kind)
      if (!w) continue
      const pct = Math.round(w.percentUsed)
      const resets = w.resetsAt ? dur(Date.parse(w.resetsAt) - t) : ''
      items.push(
        <Text key={kind}>
          <Text bold>{label} </Text>
          {bar(pct, color(pct))}
          <Text color={color(pct)} bold>{` ${pct}%`}</Text>
          <Text dimColor>{resets ? ` ↻${resets}` : ''}</Text>
        </Text>,
      )
    }

    if (last > 0) {
      const left = last + ttl - t
      const fill = left < 60_000 ? 'red' : left < ttl / 5 ? 'yellow' : 'cyan'
      items.push(
        <Text key="cache">
          <Text bold>cache </Text>
          {left > 0 ? bar((100 * left) / ttl, fill) : <Text dimColor>{'━'.repeat(WIDTH)}</Text>}
          <Text color={left > 0 ? fill : undefined} dimColor={left <= 0} bold={left > 0}>
            {left > 0 ? ` ${dur(left)}` : ' cold'}
          </Text>
        </Text>,
      )
    }

    return (
      <Box marginTop={1}>
        {items.flatMap((item, i) => (i === 0 ? [item] : [<Text key={`s${i}`}>{sep}</Text>, item]))}
      </Box>
    )
  })
}
