package com.project.garuda.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val GarudaDarkColorScheme = darkColorScheme(
    primary = EmergencyBloodRed,
    onPrimary = Color.White,
    primaryContainer = EmergencyRedContainer,
    onPrimaryContainer = EmergencyOnRedContainer,
    
    secondary = AmberAlert,
    onSecondary = Color.Black,
    secondaryContainer = AmberAlertContainer,
    onSecondaryContainer = AmberOnContainer,
    
    tertiary = SafeGreen,
    onTertiary = Color.White,
    tertiaryContainer = SafeGreenContainer,
    onTertiaryContainer = SafeOnContainer,
    
    background = AmoledBlack,
    onBackground = TextPrimaryDark,
    surface = SurfaceDark,
    onSurface = TextPrimaryDark,
    surfaceVariant = SurfaceCard,
    onSurfaceVariant = TextSecondaryDark,
    outline = BorderSubtle,
    error = EmergencyBloodRed,
    onError = Color.White
)

@Composable
fun GarudaTheme(
    darkTheme: Boolean = true, // Force high contrast AMOLED dark mode for disaster preparedness & battery saving
    content: @Composable () -> Unit
) {
    val colorScheme = GarudaDarkColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = AmoledBlack.toArgb()
                window.navigationBarColor = AmoledBlack.toArgb()
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
                WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = false
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}