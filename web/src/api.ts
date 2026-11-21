export type Direction = 'UP' | 'DOWN' | 'LEFT' | 'RIGHT'

export type GameStatus = 'IN_PROGRESS' | 'WON' | 'OVER'

export interface Game {
  id: string
  grid: number[][]
  score: number
  status: GameStatus
}

interface ApiResponse<T> {
  data: T
}

interface ApiError {
  error?: { code: string; message: string }
}

async function errorMessage(response: Response): Promise<string> {
  const fallback = `Request failed with status ${response.status}`
  try {
    const body = (await response.json()) as ApiError
    return body.error?.message ?? fallback
  } catch {
    // The dev proxy answers with a non-JSON body when the API is not running.
    return fallback
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`/api/v1${path}`, init)
  if (!response.ok) {
    throw new Error(await errorMessage(response))
  }
  const body = (await response.json()) as ApiResponse<T>
  return body.data
}

export function createGame(): Promise<Game> {
  return request<Game>('/games', { method: 'POST' })
}

export function move(gameId: string, direction: Direction): Promise<Game> {
  return request<Game>(`/games/${encodeURIComponent(gameId)}/moves`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ direction }),
  })
}
