package com.example.ai_calendar

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import android.provider.CalendarContract.Events
import android.provider.CalendarContract.Reminders
import java.util.TimeZone

object CalendarProvider {

    private data class LocalCalendar(val id: Long, val accountName: String)

    private const val PROJECTION_ID_INDEX = 0
    private const val PROJECTION_ACCOUNT_INDEX = 1

    @Throws(SecurityException::class)
    fun insertEvent(
        context: Context,
        title: String,
        description: String?,
        startMillis: Long,
        endMillis: Long,
        allDay: Boolean = false,
        rrule: String? = null,
        reminderMinutes: Int? = null,
    ): Long {
        val calendarId = ensureCalendarExists(context)
        val tz = TimeZone.getDefault().id

        val values = ContentValues().apply {
            put(Events.CALENDAR_ID, calendarId)
            put(Events.TITLE, title)
            put(Events.DTSTART, startMillis)
            put(Events.DTEND, endMillis)
            put(Events.EVENT_TIMEZONE, tz)
            put(Events.ALL_DAY, if (allDay) 1 else 0)
            put(Events.STATUS, Events.STATUS_CONFIRMED)
            put(Events.SELF_ATTENDEE_STATUS, Events.STATUS_CONFIRMED)
            put(Events.AVAILABILITY, Events.AVAILABILITY_BUSY)

            description?.let { put(Events.DESCRIPTION, it) }
            rrule?.takeIf { it.isNotBlank() }?.let { put(Events.RRULE, it) }
        }

        val eventUri: Uri? = context.contentResolver.insert(Events.CONTENT_URI, values)
        val eventId = eventUri?.lastPathSegment?.toLongOrNull()
            ?: throw IllegalStateException("Failed to insert event, no event URI returned")

        reminderMinutes?.let {
            insertReminder(context, eventId, it)
        }

        return eventId
    }

    @Throws(SecurityException::class)
    fun updateEvent(
        context: Context,
        eventId: Long,
        title: String,
        description: String?,
        startMillis: Long,
        endMillis: Long,
        allDay: Boolean = false,
        rrule: String? = null,
        reminderMinutes: Int? = null,
    ) {
        val tz = TimeZone.getDefault().id
        val values = ContentValues().apply {
            put(Events.TITLE, title)
            put(Events.DTSTART, startMillis)
            put(Events.DTEND, endMillis)
            put(Events.EVENT_TIMEZONE, tz)
            put(Events.ALL_DAY, if (allDay) 1 else 0)

            description?.let { put(Events.DESCRIPTION, it) }
                ?: putNull(Events.DESCRIPTION)

            if (rrule.isNullOrBlank()) {
                putNull(Events.RRULE)
            } else {
                put(Events.RRULE, rrule)
            }
        }

        val uri = ContentUris.withAppendedId(Events.CONTENT_URI, eventId)
        context.contentResolver.update(uri, values, null, null)

        deleteRemindersForEvent(context, eventId)
        reminderMinutes?.let {
            insertReminder(context, eventId, it)
        }
    }

    @Throws(SecurityException::class)
    fun deleteEvent(context: Context, eventId: Long) {
        val uri = ContentUris.withAppendedId(Events.CONTENT_URI, eventId)
        context.contentResolver.delete(uri, null, null)
    }

    private fun insertReminder(context: Context, eventId: Long, minutes: Int) {
        val values = ContentValues().apply {
            put(Reminders.EVENT_ID, eventId)
            put(Reminders.MINUTES, minutes)
            put(Reminders.METHOD, Reminders.METHOD_ALERT)
        }
        context.contentResolver.insert(Reminders.CONTENT_URI, values)
    }

    private fun deleteRemindersForEvent(context: Context, eventId: Long) {
        val uri = Reminders.CONTENT_URI
        context.contentResolver.delete(
            uri,
            "${Reminders.EVENT_ID} = ?",
            arrayOf(eventId.toString()),
        )
    }

    @Throws(SecurityException::class)
    private fun ensureCalendarExists(context: Context): Long {
        findWritableCalendar(context)?.let { return it.id }
        return createLocalCalendar(context)
    }

    @Throws(SecurityException::class)
    private fun findWritableCalendar(context: Context): LocalCalendar? {
        val projection = arrayOf(Events._ID, Events.ACCOUNT_NAME)
        val selection = "${CalendarContract.Calendars.VISIBLE} = ?"
        val selectionArgs = arrayOf("1")

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null,
        )?.use { cursor ->
            val idCol = cursor.getColumnIndex(Events._ID)
            val accCol = cursor.getColumnIndex(Events.ACCOUNT_NAME)
            while (cursor.moveToNext()) {
                return LocalCalendar(
                    id = cursor.getLong(idCol),
                    accountName = if (accCol >= 0) cursor.getString(accCol) ?: "local" else "local",
                )
            }
        }
        return null
    }

    @Throws(SecurityException::class)
    private fun createLocalCalendar(context: Context): Long {
        val accountName = "${context.packageName}.calendar"
        val values = ContentValues().apply {
            put(CalendarContract.Calendars.ACCOUNT_NAME, accountName)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            put(CalendarContract.Calendars.NAME, "AI Calendar")
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, "AI Calendar")
            put(CalendarContract.Calendars.CALENDAR_COLOR, -0x9c5320a4)
            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
            put(CalendarContract.Calendars.OWNER_ACCOUNT, accountName)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
            put(CalendarContract.Calendars.VISIBLE, 1)
        }

        val uri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, accountName)
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            .build()

        val resultUri: Uri? = context.contentResolver.insert(uri, values)
        return resultUri?.lastPathSegment?.toLongOrNull()
            ?: throw IllegalStateException("Failed to create local calendar")
    }
}
