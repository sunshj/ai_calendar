package com.example.ai_calendar

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class CalendarPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware, PluginRegistry.RequestPermissionsResultListener {

    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        val granted = CalendarPermission.checkPermissionResult(requestCode, grantResults)
        pendingPermissionResult?.let { result ->
            pendingPermissionResult = null
            result.success(granted)
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = applicationContext ?: run {
            result.error("NO_CONTEXT", "Application context not available", null)
            return
        }
        try {
            when (call.method) {
                METHOD_CHECK_PERMISSIONS -> {
                    result.success(CalendarPermission.hasPermissions(ctx))
                }
                METHOD_REQUEST_PERMISSIONS -> {
                    val act = activity
                    if (act == null) {
                        result.error("NO_ACTIVITY", "Activity not available", null)
                        return
                    }
                    if (CalendarPermission.hasPermissions(ctx)) {
                        result.success(true)
                        return
                    }
                    pendingPermissionResult = result
                    CalendarPermission.requestPermissions(act)
                }
                METHOD_CREATE_SCHEDULE -> {
                    val args = call.arguments as? Map<*, *>
                        ?: run { result.error("BAD_ARGS", "Arguments must be a Map", null); return }
                    handleCreateSchedule(ctx, args, result)
                }
                METHOD_UPDATE_SCHEDULE -> {
                    val args = call.arguments as? Map<*, *>
                        ?: run { result.error("BAD_ARGS", "Arguments must be a Map", null); return }
                    handleUpdateSchedule(ctx, args, result)
                }
                METHOD_DELETE_SCHEDULE -> {
                    val args = call.arguments as? Map<*, *>
                        ?: run { result.error("BAD_ARGS", "Arguments must be a Map", null); return }
                    val eventId = (args["eventId"] as? String)?.toLongOrNull()
                        ?: run { result.error("BAD_ARGS", "eventId required", null); return }
                    CalendarProvider.deleteEvent(ctx, eventId)
                    result.success(null)
                }
                METHOD_QUERY_SCHEDULES -> {
                    result.success(emptyList<Map<String, *>>())
                }
                else -> result.notImplemented()
            }
        } catch (se: SecurityException) {
            result.error("PERMISSION_DENIED", se.message, null)
        } catch (iae: IllegalArgumentException) {
            result.error("BAD_DATA", iae.message, null)
        } catch (t: Throwable) {
            result.error("UNEXPECTED", t.message, t.stackTraceToString())
        }
    }

    private fun handleCreateSchedule(ctx: Context, args: Map<*, *>, result: MethodChannel.Result) {
        val s = parseSchedule(args)
        val rrule = RRuleBuilder.fromRepeatRuleMap(s.repeatRule)

        val eventId = CalendarProvider.insertEvent(
            context = ctx,
            title = s.title,
            description = s.description,
            startMillis = s.startMillis,
            endMillis = s.endMillis,
            rrule = rrule,
            reminderMinutes = s.reminderMinutes,
        )
        result.success(eventId.toString())
    }

    private fun handleUpdateSchedule(ctx: Context, args: Map<*, *>, result: MethodChannel.Result) {
        val eventId = (args["eventId"] as? String)?.toLongOrNull()
            ?: run { result.error("BAD_ARGS", "eventId required", null); return }
        val scheduleMap = args["schedule"] as? Map<*, *>
            ?: run { result.error("BAD_ARGS", "schedule map required", null); return }
        val s = parseSchedule(scheduleMap)
        val rrule = RRuleBuilder.fromRepeatRuleMap(s.repeatRule)

        CalendarProvider.updateEvent(
            context = ctx,
            eventId = eventId,
            title = s.title,
            description = s.description,
            startMillis = s.startMillis,
            endMillis = s.endMillis,
            rrule = rrule,
            reminderMinutes = s.reminderMinutes,
        )
        result.success(null)
    }

    private data class ScheduleDto(
        val title: String,
        val description: String?,
        val startMillis: Long,
        val endMillis: Long,
        val reminderMinutes: Int,
        val repeatRule: Map<String, *>?,
    )

    @Suppress("UNCHECKED_CAST")
    private fun parseSchedule(args: Map<*, *>): ScheduleDto {
        val title = args["title"] as? String
            ?: throw IllegalArgumentException("title is required")
        val startIso = args["start"] as? String
            ?: throw IllegalArgumentException("start is required")
        val endIso = args["end"] as? String
            ?: throw IllegalArgumentException("end is required")
        val startMillis = RRuleBuilder.millisFromIso(startIso)
            ?: throw IllegalArgumentException("start is invalid ISO datetime")
        val endMillis = RRuleBuilder.millisFromIso(endIso)
            ?: throw IllegalArgumentException("end is invalid ISO datetime")

        return ScheduleDto(
            title = title,
            description = args["description"] as? String,
            startMillis = startMillis,
            endMillis = endMillis,
            reminderMinutes = (args["reminderMinutes"] as? Number)?.toInt() ?: 0,
            repeatRule = args["repeatRule"] as? Map<String, *>,
        )
    }

    companion object {
        private const val CHANNEL_NAME = "com.example.ai_calendar/calendar"
        private const val METHOD_CHECK_PERMISSIONS = "checkPermissions"
        private const val METHOD_REQUEST_PERMISSIONS = "requestPermissions"
        private const val METHOD_CREATE_SCHEDULE = "createSchedule"
        private const val METHOD_UPDATE_SCHEDULE = "updateSchedule"
        private const val METHOD_DELETE_SCHEDULE = "deleteSchedule"
        private const val METHOD_QUERY_SCHEDULES = "querySchedules"
    }
}
