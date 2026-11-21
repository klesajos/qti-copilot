package com.quanti.g2048.api

import com.quanti.g2048.engine.Direction
import java.util.UUID
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

data class ApiResponse<T>(val data: T)

data class MoveRequest(val direction: Direction)

@RestController
@RequestMapping("/api/v1/games")
class GameController(private val games: GameService) {

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(): ApiResponse<GameState> = ApiResponse(games.create())

    @GetMapping("/{id}")
    fun find(@PathVariable id: UUID): ApiResponse<GameState> = ApiResponse(games.find(id))

    @PostMapping("/{id}/moves")
    fun move(
        @PathVariable id: UUID,
        @RequestBody request: MoveRequest,
    ): ApiResponse<GameState> = ApiResponse(games.move(id, request.direction))
}
