export type Limit = { kind: string; percentUsed: number; resetsAt?: string }

declare module 'claude-code' {
  interface PluginState {
    'usage-band': {
      limits: Limit[]
      lastCallAt: number
      ttlMinutes: number
      now: number
    }
  }
}
