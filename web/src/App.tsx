import { useCallback, useEffect, useState } from 'react'
import { createGame, move } from './api'
import type { Game } from './api'
import { Board } from './Board'
import { toDirection } from './keys'

const STATUS_MESSAGE: Record<Game['status'], string> = {
  IN_PROGRESS: 'Use the arrow keys or WASD.',
  WON: 'You reached 2048! Keep going or start a new game.',
  OVER: 'Game over.',
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : 'Unexpected error'
}

export function App() {
  const [game, setGame] = useState<Game | null>(null)
  const [error, setError] = useState<string | null>(null)

  const startGame = useCallback(() => {
    createGame()
      .then((created) => {
        setGame(created)
        setError(null)
      })
      .catch((cause: unknown) => setError(messageOf(cause)))
  }, [])

  useEffect(() => {
    startGame()
  }, [startGame])

  useEffect(() => {
    if (game === null || game.status === 'OVER') {
      return
    }

    const onKeyDown = (event: KeyboardEvent) => {
      const direction = toDirection(event.key)
      if (direction === null) {
        return
      }
      // Arrow keys would otherwise scroll the page.
      event.preventDefault()
      move(game.id, direction)
        .then(setGame)
        .catch((cause: unknown) => setError(messageOf(cause)))
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [game])

  return (
    <main className="app">
      <header className="app-header">
        <h1>2048</h1>
        <p className="score">score: {game?.score ?? 0}</p>
        <button type="button" onClick={startGame}>
          New game
        </button>
      </header>

      {error !== null && (
        <p className="error" role="alert">
          {error}
        </p>
      )}

      {game !== null && (
        <>
          <Board grid={game.grid} />
          <p className="status">{STATUS_MESSAGE[game.status]}</p>
        </>
      )}
    </main>
  )
}
