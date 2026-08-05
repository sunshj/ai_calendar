package com.example.ai_calendar

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object CalendarPermission {

    private val CALENDAR_PERMISSIONS = arrayOf(
        Manifest.permission.READ_CALENDAR,
        Manifest.permission.WRITE_CALENDAR,
    )

    const val REQUEST_CODE_CALENDAR = 1001

    fun hasPermissions(context: Context): Boolean {
        return CALENDAR_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun shouldShowRationale(activity: Activity): Boolean {
        return CALENDAR_PERMISSIONS.any {
            ActivityCompat.shouldShowRequestPermissionRationale(activity, it)
        }
    }

    fun requestPermissions(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            CALENDAR_PERMISSIONS,
            REQUEST_CODE_CALENDAR,
        )
    }

    fun checkPermissionResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE_CALENDAR) return false
        if (grantResults.isEmpty()) return false
        return grantResults.all { it == PackageManager.PERMISSION_GRANTED }
    }
}
