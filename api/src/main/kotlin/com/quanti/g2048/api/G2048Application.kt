package com.quanti.g2048.api

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class G2048Application

fun main(args: Array<String>) {
    runApplication<G2048Application>(*args)
}
