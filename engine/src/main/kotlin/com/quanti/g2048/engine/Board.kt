package com.quanti.g2048.engine

import kotlin.random.Random

/** Side length of the (square) board. */
const val SIZE = 4

enum class Direction { UP, DOWN, LEFT, RIGHT }

/**
 * Slides and merges a single line towards index 0 (the "left"), in place.
 * Returns the score gained from merges this move.
 * Kept as a top-level function so it can be unit-tested in isolation.
 */
fun slideLineLeft(line: IntArray): Int {
    // 1) Compact: push all non-zero tiles to the front, keeping their order.
    val out = IntArray(SIZE)
    var count = 0
    for (value in line) {
        if (value != 0) {
            out[count++] = value
        }
    }

    // 2) Merge equal neighbours, scanning left to right.
    var gained = 0
    var i = 0
    while (i + 1 < count) {
        if (out[i] == out[i + 1]) {
            out[i] *= 2
            gained += out[i]

            // Remove the consumed tile by shifting the tail left by one.
            for (k in i + 1 until count - 1) {
                out[k] = out[k + 1]
            }
            out[count - 1] = 0
            count--
            // NOTE: index `i` is intentionally not advanced here.
        } else {
            i++
        }
    }

    out.copyInto(line)
    return gained
}

/**
 * Pure game state + rules for 2048. No I/O lives here, which is what makes
 * the class straightforward to unit-test.
 *
 * Builds a board from an explicit grid, so the state is fully deterministic.
 * Use [Board.newGame] for a board seeded with two random tiles.
 */
class Board(
    grid: List<List<Int>>,
    score: Int = 0,
    private val random: Random = Random.Default,
) {
    private val cells: Array<IntArray>

    var score: Int = score
        private set

    init {
        require(grid.size == SIZE && grid.all { it.size == SIZE }) {
            "Grid must be $SIZE x $SIZE"
        }
        cells = Array(SIZE) { row -> IntArray(SIZE) { col -> grid[row][col] } }
    }

    val grid: List<List<Int>>
        get() = cells.map { it.toList() }

    fun at(row: Int, col: Int): Int = cells[row][col]

    /**
     * Applies a move in the given direction.
     * Returns true if the board actually changed.
     */
    fun move(direction: Direction): Boolean {
        val before = grid
        var gained = 0

        // NOTE: the four branches below are near-identical. They extract a line
        // (row or column, possibly reversed), slide it left, then write it back.
        when (direction) {
            Direction.LEFT -> {
                for (row in 0 until SIZE) {
                    val line = cells[row].copyOf()
                    gained += slideLineLeft(line)
                    cells[row] = line
                }
            }
            Direction.RIGHT -> {
                for (row in 0 until SIZE) {
                    val line = IntArray(SIZE)
                    for (col in 0 until SIZE) {
                        line[col] = cells[row][SIZE - 1 - col]
                    }
                    gained += slideLineLeft(line)
                    for (col in 0 until SIZE) {
                        cells[row][SIZE - 1 - col] = line[col]
                    }
                }
            }
            Direction.UP -> {
                for (col in 0 until SIZE) {
                    val line = IntArray(SIZE)
                    for (row in 0 until SIZE) {
                        line[row] = cells[row][col]
                    }
                    gained += slideLineLeft(line)
                    for (row in 0 until SIZE) {
                        cells[row][col] = line[row]
                    }
                }
            }
            Direction.DOWN -> {
                for (col in 0 until SIZE) {
                    val line = IntArray(SIZE)
                    for (row in 0 until SIZE) {
                        line[row] = cells[SIZE - 1 - row][col]
                    }
                    gained += slideLineLeft(line)
                    for (row in 0 until SIZE) {
                        cells[SIZE - 1 - row][col] = line[row]
                    }
                }
            }
        }

        score += gained
        return grid != before
    }

    /**
     * Spawns a single tile (2 with 90% probability, otherwise 4) in a random
     * empty cell. Returns false if the board was already full.
     */
    fun spawnRandom(): Boolean {
        val empties = mutableListOf<Pair<Int, Int>>()
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                if (cells[row][col] == 0) {
                    empties += row to col
                }
            }
        }
        if (empties.isEmpty()) {
            return false
        }

        val (row, col) = empties[random.nextInt(empties.size)]
        cells[row][col] = if (random.nextInt(10) == 0) 4 else 2
        return true
    }

    fun isGameOver(): Boolean {
        // A board is "over" only when no move is possible. For now we just look
        // for an empty cell.
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                if (cells[row][col] == 0) {
                    return false
                }
            }
        }
        return true
    }

    /** True once any tile reaches [WIN_VALUE]. */
    fun hasWon(): Boolean = cells.any { row -> row.any { it >= WIN_VALUE } }

    companion object {
        const val WIN_VALUE = 2048

        /** Starts an empty board and seeds it with two random tiles. */
        fun newGame(random: Random = Random.Default): Board {
            val board = Board(List(SIZE) { List(SIZE) { 0 } }, random = random)
            board.spawnRandom()
            board.spawnRandom()
            return board
        }
    }
}
