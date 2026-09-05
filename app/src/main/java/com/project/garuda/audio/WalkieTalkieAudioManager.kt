package com.project.garuda.audio

import android.content.Context
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.util.Base64
import android.util.Log
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

object WalkieTalkieAudioManager {
    private const val TAG = "WalkieTalkieAudio"

    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentRecordingFile: File? = null
    private var recordingStartTime: Long = 0L

    var currentPlayingId: String? = null
        private set

    fun startRecording(context: Context): Boolean {
        try {
            stopRecording()
            stopAudio()

            val audioDir = File(context.cacheDir, "mesh_voice").apply { mkdirs() }
            val outputFile = File(audioDir, "ptt_${System.currentTimeMillis()}.3gp")
            currentRecordingFile = outputFile

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                setOutputFile(outputFile.absolutePath)
                prepare()
                start()
            }
            recordingStartTime = System.currentTimeMillis()
            Log.d(TAG, "Started walkie-talkie PTT recording")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start audio recording", e)
            mediaRecorder?.release()
            mediaRecorder = null
            return false
        }
    }

    fun stopRecording(): Pair<String, Int>? {
        if (mediaRecorder == null) return null
        val durationSec = ((System.currentTimeMillis() - recordingStartTime) / 1000).toInt().coerceAtLeast(1)

        return try {
            mediaRecorder?.apply {
                try {
                    stop()
                } catch (e: Exception) {
                    Log.v(TAG, "Stop exception note: ${e.message}")
                }
                release()
            }
            mediaRecorder = null

            val file = currentRecordingFile
            if (file != null && file.exists() && file.length() > 0) {
                val bytes = ByteArray(file.length().toInt())
                FileInputStream(file).use { it.read(bytes) }
                val base64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
                Pair(base64, durationSec)
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to process audio recording", e)
            null
        } finally {
            mediaRecorder = null
        }
    }

    fun playAudio(context: Context, msgId: String, base64Audio: String, onFinished: () -> Unit = {}) {
        try {
            stopAudio()

            val bytes = Base64.decode(base64Audio, Base64.NO_WRAP)
            val tempFile = File(context.cacheDir, "playback_${msgId.hashCode()}.3gp")
            FileOutputStream(tempFile).use { it.write(bytes) }

            currentPlayingId = msgId

            mediaPlayer = MediaPlayer().apply {
                setDataSource(tempFile.absolutePath)
                prepare()
                setOnCompletionListener {
                    currentPlayingId = null
                    it.release()
                    mediaPlayer = null
                    onFinished()
                }
                start()
            }
            Log.d(TAG, "Playing walkie-talkie memo: $msgId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play voice message", e)
            currentPlayingId = null
            onFinished()
        }
    }

    fun stopAudio() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
        } catch (e: Exception) {
            Log.v(TAG, "Audio stop note: ${e.message}")
        } finally {
            mediaPlayer = null
            currentPlayingId = null
        }
    }
}
