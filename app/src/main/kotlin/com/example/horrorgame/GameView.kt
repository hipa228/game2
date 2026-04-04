package com.example.horrorgame

import android.content.Context
import android.graphics.*
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import kotlin.math.*

class GameView(context: Context) : SurfaceView(context), SurfaceHolder.Callback {
    private lateinit var gameThread: GameThread
    private val holder: SurfaceHolder = holder
    private var playerX: Float = 0f
    private var playerY: Float = 0f
    private var playerRadius: Float = 50f
    private var playerSpeed: Float = 10f
    private var targetX: Float = 0f
    private var targetY: Float = 0f
    private var isMoving: Boolean = false
    private val paint = Paint()
    private val bgPaint = Paint()
    private val enemyPaint = Paint()
    private val textPaint = Paint()
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var enemies = mutableListOf<Enemy>()
    private var score: Int = 0
    private var gameOver: Boolean = false

    init {
        holder.addCallback(this)
        isFocusable = true
        setupPaints()
    }

    private fun setupPaints() {
        bgPaint.color = Color.BLACK
        paint.color = Color.RED
        paint.style = Paint.Style.FILL
        enemyPaint.color = Color.GREEN
        enemyPaint.style = Paint.Style.FILL
        textPaint.color = Color.WHITE
        textPaint.textSize = 60f
        textPaint.textAlign = Paint.Align.CENTER
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        screenWidth = width
        screenHeight = height
        playerX = screenWidth / 2f
        playerY = screenHeight / 2f
        targetX = playerX
        targetY = playerY
        spawnEnemies()
        gameThread = GameThread(holder, this)
        gameThread.running = true
        gameThread.start()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // Handle surface changes
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        var retry = true
        gameThread.running = false
        while (retry) {
            try {
                gameThread.join()
                retry = false
            } catch (e: InterruptedException) {
                e.printStackTrace()
            }
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_MOVE -> {
                targetX = event.x
                targetY = event.y
                isMoving = true
            }
            MotionEvent.ACTION_UP -> {
                isMoving = false
            }
        }
        return true
    }

    fun update() {
        if (gameOver) return

        // Move player towards target
        val dx = targetX - playerX
        val dy = targetY - playerY
        val distance = sqrt(dx * dx + dy * dy)
        if (distance > playerSpeed) {
            playerX += dx / distance * playerSpeed
            playerY += dy / distance * playerSpeed
        } else {
            playerX = targetX
            playerY = targetY
        }

        // Update enemies
        for (enemy in enemies) {
            enemy.update(playerX, playerY)
            // Check collision
            val enemyDx = enemy.x - playerX
            val enemyDy = enemy.y - playerY
            val enemyDistance = sqrt(enemyDx * enemyDx + enemyDy * enemyDy)
            if (enemyDistance < playerRadius + enemy.radius) {
                gameOver = true
            }
        }

        // Remove enemies that are too far (optional)
        // Spawn new enemies occasionally
        if (enemies.size < 5 && (0..100).random() < 2) {
            spawnEnemy()
        }
    }

    override fun draw(canvas: Canvas?) {
        super.draw(canvas)
        canvas?.let {
            // Draw background
            it.drawRect(0f, 0f, screenWidth.toFloat(), screenHeight.toFloat(), bgPaint)

            // Draw player
            it.drawCircle(playerX, playerY, playerRadius, paint)

            // Draw enemies
            for (enemy in enemies) {
                it.drawCircle(enemy.x, enemy.y, enemy.radius, enemyPaint)
            }

            // Draw score
            it.drawText("Score: $score", screenWidth / 2f, 100f, textPaint)

            // Draw game over
            if (gameOver) {
                it.drawText("GAME OVER", screenWidth / 2f, screenHeight / 2f, textPaint)
            }
        }
    }

    private fun spawnEnemies() {
        enemies.clear()
        repeat(5) {
            spawnEnemy()
        }
    }

    private fun spawnEnemy() {
        val side = (0..3).random()
        val x = when (side) {
            0 -> -50f // left
            1 -> screenWidth + 50f // right
            else -> (0..screenWidth).random().toFloat()
        }
        val y = when (side) {
            2 -> -50f // top
            3 -> screenHeight + 50f // bottom
            else -> (0..screenHeight).random().toFloat()
        }
        enemies.add(Enemy(x, y))
    }

    fun pause() {
        gameThread.running = false
    }

    fun resume() {
        if (::gameThread.isInitialized) {
            gameThread.running = true
        }
    }

    inner class Enemy(var x: Float, var y: Float) {
        val radius: Float = 40f
        private val speed: Float = 3f

        fun update(playerX: Float, playerY: Float) {
            val dx = playerX - x
            val dy = playerY - y
            val distance = sqrt(dx * dx + dy * dy)
            if (distance > 0) {
                x += dx / distance * speed
                y += dy / distance * speed
            }
        }
    }

    inner class GameThread(
        private val surfaceHolder: SurfaceHolder,
        private val gameView: GameView
    ) : Thread() {
        var running: Boolean = false
        private val targetFPS: Long = 60
        private val targetTime: Long = 1000 / targetFPS

        override fun run() {
            var startTime: Long
            var timeMillis: Long
            var waitTime: Long

            while (running) {
                startTime = System.nanoTime()
                val canvas = surfaceHolder.lockCanvas()
                if (canvas != null) {
                    synchronized(surfaceHolder) {
                        gameView.update()
                        gameView.draw(canvas)
                    }
                    surfaceHolder.unlockCanvasAndPost(canvas)
                }

                timeMillis = (System.nanoTime() - startTime) / 1_000_000
                waitTime = targetTime - timeMillis

                try {
                    if (waitTime > 0) {
                        sleep(waitTime)
                    }
                } catch (e: InterruptedException) {
                    e.printStackTrace()
                }
            }
        }
    }
}