package com.interactivebook.vision

import org.opencv.core.*
import org.opencv.features2d.ORB
import org.opencv.features2d.DescriptorMatcher

class PageRecognitionEngine {

    private val orb = ORB.create(1000)
    private val matcher =
        DescriptorMatcher.create(DescriptorMatcher.BRUTEFORCE_HAMMING)

    fun extract(gray: Mat): Mat {
        val kp = MatOfKeyPoint()
        val desc = Mat()
        orb.detectAndCompute(gray, Mat(), kp, desc)
        return desc
    }

    fun match(
        frame: Mat,
        pages: Map<String, Mat>
    ): String? {
        val frameDesc = extract(frame)
        var best = 0
        var page: String? = null

        pages.forEach { (id, desc) ->
            val matches = MatOfDMatch()
            matcher.match(frameDesc, desc, matches)
            val good = matches.toArray().count { it.distance < 50 }
            if (good > best) {
                best = good
                page = id
            }
        }
        return if (best > 40) page else null
    }
}
