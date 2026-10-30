package com.widgettodo

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import java.time.*

object Reminders {
    fun pending(context: Context, id: String): PendingIntent = PendingIntent.getBroadcast(context, 0,
        Intent(context, ReminderReceiver::class.java).setAction("remind:$id").putExtra("task", id), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun schedule(context: Context, tasks: List<Task>) {
        val prefs = context.getSharedPreferences("alarms", 0)
        val manager = context.getSystemService(AlarmManager::class.java)
        prefs.getStringSet("ids", emptySet())!!.forEach { manager.cancel(pending(context, it)) }
        val enabled = context.getSharedPreferences("todo1", 0).getBoolean("reminders", false)
        val upcoming = if (enabled) tasks.filter { !it.completed && it.timed && it.due != null && it.due > LocalDateTime.now() }.sortedBy { it.due }.take(60) else emptyList()
        upcoming.forEach { task ->
            // Inexact alarms avoid requesting special exact-alarm access; Android may delay them.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, task.due!!.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli(), pending(context, task.id))
        }
        prefs.edit().putStringSet("ids", upcoming.map { it.id }.toSet()).apply()
    }
}
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val task = Store(context).tasks.find { it.id == intent.getStringExtra("task") && !it.completed } ?: return
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val notifications = context.getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(NotificationChannel("due", "Task reminders", NotificationManager.IMPORTANCE_DEFAULT))
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java).setData(android.net.Uri.parse("todo1://task/${task.id}")), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        notifications.notify(task.id.hashCode(), Notification.Builder(context, "due").setSmallIcon(R.drawable.ic_launcher).setContentTitle(task.title).setContentText(task.notes.ifBlank { "Your task is due" }).setContentIntent(open).setAutoCancel(true).build())
    }
}
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) { Reminders.schedule(context, Store(context).tasks); TodoWidget.refresh(context) }
}
