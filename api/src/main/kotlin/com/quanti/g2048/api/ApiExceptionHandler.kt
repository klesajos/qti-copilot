package com.quanti.g2048.api

import org.springframework.http.HttpStatus
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException

data class ErrorBody(val code: String, val message: String)

data class ErrorResponse(val error: ErrorBody)

@RestControllerAdvice
class ApiExceptionHandler {

    @ExceptionHandler(GameNotFoundException::class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    fun gameNotFound(exception: GameNotFoundException): ErrorResponse =
        ErrorResponse(ErrorBody("GAME_NOT_FOUND", exception.message ?: "Game does not exist"))

    // Fixed messages on purpose: the framework's own text leaks class names and parser details.
    @ExceptionHandler(HttpMessageNotReadableException::class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    fun unreadableBody(): ErrorResponse =
        ErrorResponse(
            ErrorBody("INVALID_REQUEST", "Body must be JSON with a direction of UP, DOWN, LEFT or RIGHT"),
        )

    @ExceptionHandler(MethodArgumentTypeMismatchException::class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    fun invalidPathVariable(): ErrorResponse =
        ErrorResponse(ErrorBody("INVALID_REQUEST", "Game id must be a UUID"))
}
