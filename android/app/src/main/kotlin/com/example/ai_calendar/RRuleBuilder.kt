package com.example.ai_calendar

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object RRuleBuilder {

    private val untilDateFormat: SimpleDateFormat by lazy {
        SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
    }

    data class RepeatRuleData(
        val frequency: String? = null,
        val interval: Int = 1,
        val byDay: List<String> = emptyList(),
        val byMonthDay: List<Int> = emptyList(),
        val untilIso: String? = null,
        val count: Int? = null,
    )

    @JvmStatic
    fun fromRepeatRuleMap(repeatRule: Map<String, *>?): String? {
        if (repeatRule == null) return null

        val freqRaw = repeatRule["frequency"] as? String
        if (freqRaw.isNullOrBlank()) return null

        val data = RepeatRuleData(
            frequency = freqRaw.uppercase(),
            interval = (repeatRule["interval"] as? Number)?.toInt() ?: 1,
            byDay = (repeatRule["byDay"] as? List<*>)?.map { it.toString().uppercase() }
                ?: emptyList(),
            byMonthDay = (repeatRule["byMonthDay"] as? List<*>)?.map {
                (it as Number).toInt()
            } ?: emptyList(),
            untilIso = repeatRule["until"] as? String,
            count = (repeatRule["count"] as? Number)?.toInt(),
        )

        return build(data)
    }

    @JvmStatic
    fun build(data: RepeatRuleData): String? {
        val freq = data.frequency
        if (freq.isNullOrBlank()) return null

        val parts = mutableListOf<String>()
        parts += "FREQ=$freq"

        if (data.interval > 1) {
            parts += "INTERVAL=${data.interval}"
        }

        if (data.byDay.isNotEmpty()) {
            parts += "BYDAY=${data.byDay.joinToString(",")}"
        }

        if (data.byMonthDay.isNotEmpty()) {
            parts += "BYMONTHDAY=${data.byMonthDay.joinToString(",")}"
        }

        data.count?.let { cnt ->
            if (cnt > 0) parts += "COUNT=$cnt"
        }

        data.untilIso?.let { iso ->
            val date = parseIsoDateTime(iso)
            if (date != null) {
                parts += "UNTIL=${untilDateFormat.format(date)}"
            }
        }

        return parts.joinToString(";")
    }

    @JvmStatic
    fun parseIsoDateTime(iso: String): Date? {
        return try {
            val clean = iso.replace("Z", "+00:00")
            val t = java.time.Instant.parse(clean)
            Date.from(t)
        } catch (_: Exception) {
            try {
                val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
                fmt.timeZone = TimeZone.getTimeZone("UTC")
                fmt.parse(iso)
            } catch (_: Exception) {
                null
            }
        }
    }

    @JvmStatic
    fun millisFromIso(iso: String?): Long? {
        if (iso == null) return null
        val date = parseIsoDateTime(iso) ?: return null
        return date.time
    }
}
