package com.project.garuda

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.project.garuda.ui.sos.CitizenScreen
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.GarudaTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            GarudaTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = AmoledBlack
                ) {
                    CitizenScreen()
                }
            }
        }
    }
}