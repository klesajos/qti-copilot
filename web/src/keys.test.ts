import { describe, expect, it } from 'vitest'
import { toDirection } from './keys'

describe('toDirection', () => {
  it('maps an arrow key to its direction', () => {
    expect(toDirection('ArrowLeft')).toBe('LEFT')
  })

  it('maps a WASD key to its direction', () => {
    expect(toDirection('w')).toBe('UP')
  })

  it('ignores the case of a WASD key', () => {
    expect(toDirection('D')).toBe('RIGHT')
  })

  it('returns null for a key that is not a move', () => {
    expect(toDirection('Enter')).toBeNull()
  })
})
