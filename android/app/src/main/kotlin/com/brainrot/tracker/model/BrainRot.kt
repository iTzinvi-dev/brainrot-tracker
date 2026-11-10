package com.brainrot.tracker.model

import com.brainrot.tracker.R

/**
 * 7-stage rotting brain progression model.
 * Maps daily short-form video swipe counts to brain rot stages, sprites, and visual states.
 */
object BrainRot {

    const val STAGES = 7

    /** Daily swipe thresholds corresponding to each stage: 0 to 6. */
    val THRESHOLDS = intArrayOf(0, 10, 25, 50, 100, 175, 250)

    /** Stage descriptions reflecting progressive mental fatigue. */
    val LABELS = arrayOf(
        "Fresh",       // Stage 0: Healthy, fully alert (0–9)
        "Bruised",     // Stage 1: Mild fatigue (10–24)
        "Foggy",       // Stage 2: Scattered focus (25–49)
        "Fried",       // Stage 3: Brain overheat (50–99)
        "Mushy",       // Stage 4: Toxic sludge / green slime (100–174)
        "Rotting",     // Stage 5: Smoking decay (175–249)
        "Brain rot"    // Stage 6: Total doomscroll rot (250+)
    )

    /** Drawable resource references matching assets in res/drawable-nodpi/ */
    val SPRITES = intArrayOf(
        R.drawable.brain_stage_0,
        R.drawable.brain_stage_1,
        R.drawable.brain_stage_2,
        R.drawable.brain_stage_3,
        R.drawable.brain_stage_4,
        R.drawable.brain_stage_5,
        R.drawable.brain_stage_6,
    )

    /**
     * Resolves the current rotting stage based on cumulative reel count.
     */
    fun stage(count: Int): Int {
        val idx = THRESHOLDS.indexOfLast { count >= it }
        return idx.coerceIn(0, STAGES - 1)
    }

    /**
     * Returns the drawable resource for the specified stage.
     */
    fun sprite(stage: Int): Int {
        return SPRITES[stage.coerceIn(0, STAGES - 1)]
    }

    /**
     * Returns the human-readable label for the specified stage.
     */
    fun label(stage: Int): String {
        return LABELS[stage.coerceIn(0, STAGES - 1)]
    }

    /**
     * Swipes remaining until next stage progression, or null if already at max stage.
     */
    fun untilNext(count: Int): Int? {
        val currentStage = stage(count)
        val nextStage = currentStage + 1
        return if (nextStage < STAGES) {
            (THRESHOLDS[nextStage] - count).coerceAtLeast(0)
        } else {
            null
        }
    }

    /**
     * Stages 4 and above turn toxic green; sweat drops convert to viscous slime.
     */
    fun isSlimy(stage: Int): Boolean = stage >= 4

    /**
     * Stages 5 and above begin actively smoking with rising smoke particles.
     */
    fun isSmoking(stage: Int): Boolean = stage >= 5
}
