package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import org.springframework.stereotype.Service

enum class GameStatus { IN_PROGRESS, WON, OVER }

data class GameState(
    val id: UUID,
    val grid: List<List<Int>>,
    val score: Int,
    val status: GameStatus,
)

class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")

/**
 * Owns the running games. The rules themselves live in the engine module;
 * this class only decides what happens around a move.
 */
@Service
class GameService {
    // Demo storage: games live in memory only and are lost on restart.
    private val boards = ConcurrentHashMap<UUID, Board>()

    fun create(): GameState {
        val id = UUID.randomUUID()
        val board = Board.newGame()
        boards[id] = board
        return stateOf(id, board)
    }

    fun find(id: UUID): GameState = stateOf(id, boardFor(id))

    fun move(id: UUID, direction: Direction): GameState {
        val board = boardFor(id)
        // Board is not thread-safe; two requests for the same game must not interleave.
        synchronized(board) {
            val changed = board.move(direction)

            // Place a new tile.
            board.spawnRandom()

            return stateOf(id, board)
        }
    }

    private fun boardFor(id: UUID): Board = boards[id] ?: throw GameNotFoundException(id)

    private fun stateOf(id: UUID, board: Board): GameState {
        val status = when {
            board.isGameOver() -> GameStatus.OVER
            board.hasWon() -> GameStatus.WON
            else -> GameStatus.IN_PROGRESS
        }
        return GameState(id, board.grid, board.score, status)
    }
}
