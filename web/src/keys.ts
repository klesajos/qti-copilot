import type { Direction } from './api'

const KEY_TO_DIRECTION: Record<string, Direction> = {
  ArrowUp: 'UP',
  ArrowDown: 'DOWN',
  ArrowLeft: 'LEFT',
  ArrowRight: 'RIGHT',
  w: 'UP',
  s: 'DOWN',
  a: 'LEFT',
  d: 'RIGHT',
}

/** Maps a `KeyboardEvent.key` (arrows or WASD) to a move, or null for any other key. */
export function toDirection(key: string): Direction | null {
  return KEY_TO_DIRECTION[key] ?? KEY_TO_DIRECTION[key.toLowerCase()] ?? null
}
