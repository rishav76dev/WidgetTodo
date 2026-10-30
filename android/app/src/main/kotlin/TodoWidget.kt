package com.widgettodo

import android.app.PendingIntent
import android.appwidget.*
import android.content.*
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.LinearGradient
import android.graphics.Shader
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews

class TodoWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) { ids.forEach { update(context, manager, it) } }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) { update(context, manager, id) }
    override fun onDeleted(context: Context, ids: IntArray) { val edit = context.getSharedPreferences("widgets", 0).edit(); ids.forEach { edit.remove("filter:$it").remove("theme:$it") }; edit.apply() }
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "todo1.TOGGLE") intent.getStringExtra("task")?.let { Store(context).toggle(it) }
    }
    companion object {
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, TodoWidget::class.java)).forEach { update(context, manager, it) }
        }
        private fun open(context: Context, uri: String) = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java).setData(Uri.parse(uri)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val store = Store(context)
            val prefs = context.getSharedPreferences("widgets", 0)
            val savedFilter = prefs.getString("filter:$id", "all")!!
            val filter = savedFilter.takeIf { it in listOf("all", "today") || store.lists.any { list -> list.id == it } } ?: "all"
            val theme = Theme.selected(context, prefs.getString("theme:$id", store.themeId)!!)
            val tasks = visibleTasks(store.tasks, filter).filterNot { it.completed }
            val title = when (filter) { "all" -> "All Tasks"; "today" -> "Today"; else -> store.lists.find { it.id == filter }?.name ?: "Tasks" }
            val views = RemoteViews(context.packageName, R.layout.widget)
            views.setInt(R.id.widget_root, "setBackgroundColor", theme.colors.first())
            views.setTextViewText(R.id.widget_title, theme.cased(theme.prefix + title))
            listOf(R.id.widget_title, R.id.widget_add, R.id.widget_config).forEach { views.setTextColor(it, theme.primary) }
            views.setOnClickPendingIntent(R.id.widget_title, open(context, "todo1://home?filter=$filter"))
            views.setOnClickPendingIntent(R.id.widget_config, open(context, "todo1://widget/$id"))
            views.setOnClickPendingIntent(R.id.widget_add, open(context, "todo1://add?filter=$filter"))
            views.removeAllViews(R.id.widget_rows)
            val height = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180)
            val count = if (theme.json.optString("layout") == "focus") 1 else ((height - 85) / 44).coerceIn(1, 8)
            tasks.take(count).forEach { task ->
                val row = RemoteViews(context.packageName, R.layout.widget_row)
                row.setTextViewText(R.id.row_title, theme.cased(task.title))
                row.setTextViewText(R.id.row_check, theme.checkbox)
                row.setTextColor(R.id.row_title, if (task.overdue(java.time.LocalDateTime.now())) theme.overdue else theme.primary)
                row.setTextColor(R.id.row_check, theme.accent)
                val toggle = Intent(context, TodoWidget::class.java).setAction("todo1.TOGGLE").setData(Uri.parse("todo1://toggle/${task.id}")).putExtra("task", task.id)
                row.setOnClickPendingIntent(R.id.row_check, PendingIntent.getBroadcast(context, 0, toggle, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
                row.setOnClickPendingIntent(R.id.row_title, open(context, "todo1://task/${task.id}"))
                views.addView(R.id.widget_rows, row)
            }
            views.setTextViewText(R.id.widget_footer, if (tasks.isEmpty()) "All clear · Tap + to add a task" else "${tasks.size} remaining${if (tasks.size > count) " · +${tasks.size - count} more" else ""}")
            views.setTextColor(R.id.widget_footer, theme.secondary)
            manager.updateAppWidget(id, views)
        }
    }
}
