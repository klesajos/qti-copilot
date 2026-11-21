package com.quanti.g2048.engine

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class BoardTest {

    /** Convenience: run slideLineLeft on a line and return the result. */
    private fun slid(vararg line: Int): List<Int> {
        val copy = line.copyOf()
        slideLineLeft(copy)
        return copy.toList()
    }

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    // -----------------------------------------------------------------------
    // slideLineLeft — the heart of the game.
    // -----------------------------------------------------------------------

    @Test
    fun `empty line stays empty`() {
        assertEquals(listOf(0, 0, 0, 0), slid(0, 0, 0, 0))
    }

    @Test
    fun `tiles compact towards the left without merging`() {
        assertEquals(listOf(2, 4, 0, 0), slid(0, 2, 0, 4))
        assertEquals(listOf(2, 4, 8, 16), slid(2, 4, 8, 16))
    }

    @Test
    fun `a single pair merges`() {
        val line = intArrayOf(2, 2, 0, 0)

        val gained = slideLineLeft(line)

        assertEquals(listOf(4, 0, 0, 0), line.toList())
        assertEquals(4, gained)
    }

    @Test
    fun `two separate pairs merge into two tiles`() {
        val line = intArrayOf(2, 2, 2, 2)

        val gained = slideLineLeft(line)

        assertEquals(listOf(4, 4, 0, 0), line.toList())
        assertEquals(8, gained)
    }

    @Test
    fun `only the matching neighbours merge`() {
        assertEquals(listOf(4, 4, 0, 0), slid(4, 2, 2, 0))
    }

    // TODO (participants): add a test for the line {4, 4, 8, 0}.
    //   What *should* the result be? Run it and see what actually happens.

    // -----------------------------------------------------------------------
    // Board.move — directions.
    // -----------------------------------------------------------------------

    @Test
    fun `move left collapses each row`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 4, 4, 0),
            listOf(0, 0, 0, 0),
            listOf(8, 0, 8, 0),
        )

        val changed = board.move(Direction.LEFT)

        assertTrue(changed)
        assertEquals(
            listOf(
                listOf(4, 0, 0, 0),
                listOf(8, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(16, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `move right collapses towards the right edge`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        board.move(Direction.RIGHT)

        assertEquals(4, board.at(0, 3))
    }

    @Test
    fun `move up collapses columns`() {
        val board = boardOf(
            listOf(2, 0, 0, 0),
            listOf(2, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        board.move(Direction.UP)

        assertEquals(4, board.at(0, 0))
    }

    @Test
    fun `a move that changes nothing returns false`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertFalse(board.move(Direction.LEFT))
    }

    @Test
    fun `score accumulates across moves`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        board.move(Direction.LEFT) // +4

        assertEquals(4, board.score)
    }

    // -----------------------------------------------------------------------
    // Win / lose detection.
    // -----------------------------------------------------------------------

    @Test
    fun `hasWon triggers at 2048`() {
        val board = boardOf(
            listOf(2048, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        assertTrue(board.hasWon())
    }

    @Test
    fun `a board with an empty cell is not game over`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 0),
        )

        assertFalse(board.isGameOver())
    }

    @Test
    fun `a fully locked board is game over`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertTrue(board.isGameOver())
    }

    // TODO (participants): a *full* board can still be playable if it has two
    //   equal neighbours. Write a test for a full board that contains a mergeable
    //   pair and assert that isGameOver() returns false.
}
