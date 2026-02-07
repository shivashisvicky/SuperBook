package com.interactivebook.vision

import io.flutter.plugin.common.MethodChannel
import org.opencv.core.*
import org.opencv.imgcodecs.Imgcodecs

class VisionChannel(
    private val engine: PageRecognitionEngine
) {

    fun onCall(call: MethodChannel.MethodCall,
               result: MethodChannel.Result) {
        if (call.method == "detectPage") {
            val bytes = call.argument<ByteArray>("frame")!!
            val mat = Imgcodecs.imdecode(
                MatOfByte(*bytes),
                Imgcodecs.IMREAD_GRAYSCALE
            )
            val page = engine.match(mat, PageStore.pages)
            result.success(page)
        }
    }
}
