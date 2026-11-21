package com.quanti.g2048.api

import java.util.UUID
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.assertj.MockMvcTester

@WebMvcTest(GameController::class)
@Import(GameService::class)
class GameControllerTest(@Autowired private val mvc: MockMvcTester) {

    private fun createGameId(): String {
        val body = mvc.post().uri("/api/v1/games").exchange().response.contentAsString
        return Regex("\"id\":\"([^\"]+)\"").find(body)!!.groupValues[1]
    }

    @Test
    fun `creating a game returns 201`() {
        assertThat(mvc.post().uri("/api/v1/games")).hasStatus(HttpStatus.CREATED)
    }

    @Test
    fun `a new game starts with score zero and is in progress`() {
        assertThat(mvc.post().uri("/api/v1/games"))
            .bodyJson()
            .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
    }

    @Test
    fun `a move returns the game with its four rows`() {
        val id = createGameId()

        val result = mvc.post().uri("/api/v1/games/$id/moves")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""{"direction":"LEFT"}""")

        assertThat(result).hasStatusOk().bodyJson().extractingPath("$.data.grid.length()").isEqualTo(4)
    }

    @Test
    fun `moving in an unknown game returns a structured 404`() {
        val result = mvc.post().uri("/api/v1/games/${UUID.randomUUID()}/moves")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""{"direction":"LEFT"}""")

        assertThat(result)
            .hasStatus(HttpStatus.NOT_FOUND)
            .bodyJson()
            .extractingPath("$.error.code")
            .isEqualTo("GAME_NOT_FOUND")
    }

    @Test
    fun `an unknown direction returns a structured 400`() {
        val id = createGameId()

        val result = mvc.post().uri("/api/v1/games/$id/moves")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""{"direction":"SIDEWAYS"}""")

        assertThat(result)
            .hasStatus(HttpStatus.BAD_REQUEST)
            .bodyJson()
            .extractingPath("$.error.code")
            .isEqualTo("INVALID_REQUEST")
    }
}
