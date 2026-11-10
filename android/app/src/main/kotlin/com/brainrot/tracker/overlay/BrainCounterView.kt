package com.brainrot.tracker.overlay

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import com.brainrot.tracker.R
import com.brainrot.tracker.model.BrainRot
import com.brainrot.tracker.model.OperationalMode
import kotlin.random.Random

/**
 * Native floating Brainrot Counter View.
 * Renders the 7 stages of rotting brain with hardware-accelerated animations:
 *  - Idle: Harmonic sinusoidal breathing animation (3400ms period)
 *  - Reel Confirmed: 360ms squish & stretch with falling sweat / slime droplets
 *  - Stage Progression: Shockwave ring expansion, lightning strobe, camera shake, sprite swap
 *  - Stages 5+: 3-phase staggered rising smoke loop
 *  - Tap: Interactive wobble poke animation
 */
@SuppressLint("ViewConstructor")
class BrainCounterView(context: Context) : FrameLayout(context) {

    private val brain = ImageView(context)
    private val badge = TextView(context)
    private val fxContainer = FrameLayout(context)
    private val smokePuffs = List(3) { ImageView(context) }

    private var currentCount: Int? = null
    private var currentStage = 0
    private var operationalMode = OperationalMode.BALANCED

    private val breathingAnimator: AnimatorSet
    private var smokeLoopAnimator: ValueAnimator? = null
    private var isPaused = false

    init {
        clipChildren = false
        layoutParams = LayoutParams(dp(W), dp(H))

        // Smoke particles positioned behind the brain
        val smokeDrawables = intArrayOf(
            R.drawable.fx_smoke_1,
            R.drawable.fx_smoke_2,
            R.drawable.fx_smoke_3
        )
        smokePuffs.forEachIndexed { index, puffView ->
            puffView.setImageResource(smokeDrawables[index])
            puffView.alpha = 0f
            addView(puffView, LayoutParams(dp(18), dp(26)).apply {
                gravity = Gravity.TOP or Gravity.START
                leftMargin = dp(20 + index * 18)
                topMargin = dp(BRAIN_TOP - 16)
            })
        }

        // Central brain sprite
        brain.setImageResource(BrainRot.sprite(0))
        brain.scaleType = ImageView.ScaleType.FIT_CENTER
        addView(brain, LayoutParams(dp(BRAIN_W), dp(BRAIN_H)).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            topMargin = dp(BRAIN_TOP)
        })

        // Pivot anchored near bottom center so squish feels grounded
        brain.post {
            brain.pivotX = brain.width / 2f
            brain.pivotY = brain.height * 0.85f
        }

        // FX container for transient particles (droplets, rings, lightning bolts)
        addView(fxContainer, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        // Counter badge at the bottom
        badge.apply {
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER
            minWidth = dp(30)
            setPadding(dp(8), dp(1), dp(8), dp(2))
            background = GradientDrawable().apply {
                cornerRadius = dp(12).toFloat()
                setColor(0xE6141416.toInt())
                setStroke(dp(1), ACCENT_COLOR)
            }
            text = "–"
        }
        addView(badge, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            bottomMargin = dp(4)
        })

        // Harmonic sinusoidal breathing animation (1700ms each way = 3400ms period)
        breathingAnimator = AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(brain, View.SCALE_X, 1f, 1.035f).apply {
                    duration = 1700
                    repeatCount = ValueAnimator.INFINITE
                    repeatMode = ValueAnimator.REVERSE
                },
                ObjectAnimator.ofFloat(brain, View.SCALE_Y, 1f, 1.05f).apply {
                    duration = 1700
                    repeatCount = ValueAnimator.INFINITE
                    repeatMode = ValueAnimator.REVERSE
                }
            )
        }

        contentDescription = "Brain rot counter: 0 reels"
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        if (!isPaused) {
            breathingAnimator.start()
            if (BrainRot.isSmoking(currentStage) && operationalMode.fxEnabled) {
                startSmokeLoop()
            }
        }
    }

    override fun onDetachedFromWindow() {
        breathingAnimator.cancel()
        stopSmokeLoop()
        fxContainer.removeAllViews()
        super.onDetachedFromWindow()
    }

    /**
     * Pauses all animations during screen sleep or power saving.
     */
    fun pauseAnimations() {
        isPaused = true
        breathingAnimator.pause()
        stopSmokeLoop()
    }

    /**
     * Resumes animations when display powers on.
     */
    fun resumeAnimations() {
        isPaused = false
        breathingAnimator.resume()
        if (BrainRot.isSmoking(currentStage) && operationalMode.fxEnabled) {
            startSmokeLoop()
        }
    }

    /**
     * Updates operational power mode and adjusts particle animation budget.
     */
    fun setOperationalMode(mode: OperationalMode) {
        operationalMode = mode
        if (!mode.fxEnabled) {
            stopSmokeLoop()
            fxContainer.removeAllViews()
        } else if (BrainRot.isSmoking(currentStage) && !isPaused) {
            startSmokeLoop()
        }
    }

    /**
     * Updates the displayed reel count and triggers appropriate animation response.
     */
    fun setCount(newCount: Int) {
        val previous = currentCount
        currentCount = newCount
        badge.text = newCount.toString()
        contentDescription = "Brain rot counter: $newCount reels"

        val targetStage = BrainRot.stage(newCount)
        if (previous == null || newCount < previous) {
            // Initial state or midnight reset
            applyStage(targetStage)
            return
        }

        if (newCount == previous) return

        if (targetStage > currentStage) {
            stageUpgrade(targetStage)
        } else {
            reelCounted()
        }
    }

    /**
     * Interactive tap wobble: executes an elastic rotation bounce when tapped without drag.
     */
    fun poke() {
        ObjectAnimator.ofFloat(brain, View.ROTATION, 0f, -10f, 8f, -5f, 3f, 0f).apply {
            duration = 420
            start()
        }
    }

    // ------------------------------------------------------------------ Animation Engine

    /**
     * Standard swipe response: squish animation, badge pop, and droplet emission.
     */
    private fun reelCounted() {
        squish()
        popBadge()
        if (operationalMode.fxEnabled) {
            val dropletSprite = if (BrainRot.isSlimy(currentStage)) {
                R.drawable.fx_drop_green
            } else {
                R.drawable.fx_drop_blue
            }
            dropDroplet(dropletSprite)
        }
    }

    /**
     * Stage progression celebration: lightning strobe, shockwave ring, camera shake, and sprite swap.
     */
    private fun stageUpgrade(newStage: Int) {
        popBadge()
        shake()

        if (operationalMode.fxEnabled) {
            shockwaveRing()
            lightningBolts()
        }

        // Swap brain sprite at the flash zenith
        brain.animate()
            .alpha(0.35f)
            .setDuration(120)
            .withEndAction {
                applyStage(newStage)
                brain.animate().alpha(1f).setDuration(220).start()
            }
            .start()

        if (operationalMode.fxEnabled) {
            val dripSprite = if (BrainRot.isSlimy(newStage)) {
                R.drawable.fx_drip_green
            } else {
                R.drawable.fx_drip_blue
            }
            dropDroplet(dripSprite, isBigDrip = true)
        }
    }

    /**
     * Applies stage theme updates (sprite, badge stroke color, and smoke state).
     */
    private fun applyStage(newStage: Int) {
        currentStage = newStage
        brain.setImageResource(BrainRot.sprite(newStage))

        val strokeColor = if (BrainRot.isSlimy(newStage)) SLIME_COLOR else ACCENT_COLOR
        (badge.background as? GradientDrawable)?.setStroke(dp(1), strokeColor)

        if (BrainRot.isSmoking(newStage) && operationalMode.fxEnabled && !isPaused) {
            startSmokeLoop()
        } else {
            stopSmokeLoop()
        }
    }

    /**
     * 360ms non-linear squish and stretch keyframe response.
     */
    private fun squish() {
        AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(brain, View.SCALE_Y, 1f, 0.84f, 1.08f, 1f),
                ObjectAnimator.ofFloat(brain, View.SCALE_X, 1f, 1.12f, 0.96f, 1f)
            )
            duration = 360
            start()
        }
    }

    /**
     * Horizontal camera shake across [-5dp, 5dp, -4dp, 3dp, 0dp].
     */
    private fun shake() {
        ObjectAnimator.ofFloat(
            brain,
            View.TRANSLATION_X,
            0f, -dp(5f), dp(5f), -dp(4f), dp(3f), 0f
        ).apply {
            duration = 380
            start()
        }
    }

    /**
     * Badge scale pop with elastic overshoot.
     */
    private fun popBadge() {
        badge.animate().cancel()
        badge.scaleX = 1.3f
        badge.scaleY = 1.3f
        badge.animate()
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(260)
            .setInterpolator(OvershootInterpolator(3f))
            .start()
    }

    /**
     * Emits a falling droplet particle (sweat for stages 0-3, viscous slime with stretch for stages 4+).
     */
    private fun dropDroplet(spriteResId: Int, isBigDrip: Boolean = false) {
        val dropWidth = dp(if (isBigDrip) 30 else 10)
        val dropHeight = dp(if (isBigDrip) 28 else 16)
        val dropView = ImageView(context).apply {
            setImageResource(spriteResId)
        }

        val horizontalOffset = if (isBigDrip) {
            0
        } else {
            Random.nextInt(-dp(16), dp(16))
        }
        val dropLeft = dp(W / 2) - dropWidth / 2 + horizontalOffset

        fxContainer.addView(dropView, LayoutParams(dropWidth, dropHeight).apply {
            gravity = Gravity.TOP or Gravity.START
            leftMargin = dropLeft
            topMargin = dp(BRAIN_TOP + BRAIN_H - 16)
        })

        dropView.alpha = 0f
        dropView.pivotY = 0f

        val verticalStretch = if (BrainRot.isSlimy(currentStage)) 1.35f else 1f
        val fallDistance = dp(if (isBigDrip) 10f else 20f)
        val fallDuration = if (isBigDrip) 700L else 520L

        dropView.animate()
            .alpha(1f)
            .translationY(fallDistance)
            .scaleY(verticalStretch)
            .setDuration(fallDuration)
            .setInterpolator(AccelerateInterpolator())
            .withEndAction {
                dropView.animate()
                    .alpha(0f)
                    .setDuration(220)
                    .withEndAction { fxContainer.removeView(dropView) }
                    .start()
            }
            .start()
    }

    /**
     * Expanding shockwave ring from the brain's center (0.3x -> 1.25x scale).
     */
    private fun shockwaveRing() {
        val size = dp(BRAIN_W)
        val ringView = ImageView(context).apply {
            setImageResource(R.drawable.fx_ring)
        }
        fxContainer.addView(ringView, LayoutParams(size, size).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            topMargin = dp(BRAIN_TOP + BRAIN_H / 2) - size / 2
        })

        ringView.scaleX = 0.3f
        ringView.scaleY = 0.3f
        ringView.alpha = 0.9f
        ringView.animate()
            .scaleX(1.25f)
            .scaleY(1.25f)
            .alpha(0f)
            .setDuration(520)
            .setInterpolator(DecelerateInterpolator())
            .withEndAction { fxContainer.removeView(ringView) }
            .start()
    }

    /**
     * Double lightning strobe over the brain during stage progression.
     */
    private fun lightningBolts() {
        val boltView = ImageView(context).apply {
            setImageResource(R.drawable.fx_bolt)
        }
        fxContainer.addView(boltView, LayoutParams(dp(44), dp(40)).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            topMargin = 0
        })

        ObjectAnimator.ofFloat(boltView, View.ALPHA, 0f, 1f, 0.1f, 1f, 0f).apply {
            duration = 560
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    fxContainer.removeView(boltView)
                }
            })
            start()
        }
    }

    /**
     * 3-phase continuous smoke loop with 1/3 offset rising wisps.
     */
    private fun startSmokeLoop() {
        if (smokeLoopAnimator != null || !isAttachedToWindow) return

        smokeLoopAnimator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 2400
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener { animator ->
                val progress = animator.animatedValue as Float
                smokePuffs.forEachIndexed { index, puffView ->
                    val phase = (progress + index / 3f) % 1f
                    puffView.translationY = -dp(14f) * phase
                    puffView.alpha = (if (phase < 0.3f) phase / 0.3f else (1f - phase) / 0.7f) * 0.75f
                }
            }
            start()
        }
    }

    /**
     * Stops and fades the smoke particle loop.
     */
    private fun stopSmokeLoop() {
        smokeLoopAnimator?.cancel()
        smokeLoopAnimator = null
        smokePuffs.forEach { it.alpha = 0f }
    }

    // ------------------------------------------------------------------ Dimensions & Helpers

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
    private fun dp(value: Float): Float = value * resources.displayMetrics.density

    companion object {
        const val W = 92
        const val H = 104
        private const val BRAIN_W = 62
        private const val BRAIN_H = 52
        private const val BRAIN_TOP = 18

        private const val ACCENT_COLOR = 0xFFFF5A4E.toInt()
        private const val SLIME_COLOR = 0xFF8BC34A.toInt()
    }
}
