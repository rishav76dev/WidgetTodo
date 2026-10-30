package com.widgettodo

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime

class Store(private val context: Context) {
    val prefs = context.getSharedPreferences("todo1", Context.MODE_PRIVATE)
    var tasks: List<Task> = readTasks()
        private set
    var lists: List<TaskList> = readLists()
        private set
    var themeId: String
        get() = prefs.getString("theme", "paper")!!
        set(value) { prefs.edit().putString("theme", value).apply(); TodoWidget.refresh(context) }
    var reminders: Boolean
        get() = prefs.getBoolean("reminders", false)
        set(value) { prefs.edit().putBoolean("reminders", value).apply(); Reminders.schedule(context, tasks) }

    private fun readTasks(): List<Task> {
        val data = JSONArray(prefs.getString("tasks", "[]"))
        return (0 until data.length()).map { index ->
            val o = data.getJSONObject(index)
            Task(o.getString("id"), o.getString("title"), o.optString("notes"),
                o.optString("due").takeIf { it.isNotEmpty() }?.let(LocalDateTime::parse),
                o.optBoolean("timed"), o.optString("repeat", "none"), o.optString("list", "inbox"),
                o.optString("completed").takeIf { it.isNotEmpty() }?.let(LocalDateTime::parse),
                LocalDateTime.parse(o.getString("created")))
        }
    }
    private fun readLists(): List<TaskList> {
        val data = JSONArray(prefs.getString("lists", "[{\"id\":\"inbox\",\"name\":\"Inbox\"}]"))
        return (0 until data.length()).map { data.getJSONObject(it).let { o -> TaskList(o.getString("id"), o.getString("name")) } }
    }
    fun save(task: Task) {
        val normalized = task.title.trim().replace(Regex("\\s+"), " ").take(500)
        require(normalized.isNotEmpty())
        tasks = tasks.filterNot { it.id == task.id } + task.copy(title = normalized)
        persist()
    }
    fun delete(id: String) { tasks = tasks.filterNot { it.id == id }; persist() }
    fun toggle(id: String) {
        val task = tasks.find { it.id == id } ?: return
        val now = LocalDateTime.now()
        val next = if (!task.completed) task.nextOccurrence(now) else null
        tasks = tasks.map { if (it.id == id) it.copy(completedAt = if (it.completed) null else now) else it }
        if (next != null) tasks = tasks + task.copy(id = java.util.UUID.randomUUID().toString(), due = next, createdAt = now)
        persist()
    }
    fun saveList(list: TaskList) {
        val name = list.name.trim().take(80)
        require(name.isNotEmpty())
        lists = lists.filterNot { it.id == list.id } + list.copy(name = name)
        persist()
    }
    fun deleteList(id: String) {
        if (id == "inbox") return
        lists = lists.filterNot { it.id == id }
        tasks = tasks.map { if (it.listId == id) it.copy(listId = "inbox") else it }
        persist()
    }
    fun cleanup() {
        val cutoff = LocalDateTime.now().minusDays(30)
        val retained = tasks.filter { it.completedAt == null || it.completedAt >= cutoff }
        if (retained.size != tasks.size) { tasks = retained; persist() }
    }
    private fun persist() {
        val data = JSONArray()
        tasks.forEach { t -> data.put(JSONObject().put("id", t.id).put("title", t.title).put("notes", t.notes)
            .put("due", t.due?.toString() ?: "").put("timed", t.timed).put("repeat", t.repeat)
            .put("list", t.listId).put("completed", t.completedAt?.toString() ?: "").put("created", t.createdAt.toString())) }
        val listData = JSONArray()
        lists.forEach { listData.put(JSONObject().put("id", it.id).put("name", it.name)) }
        // commit makes edits durable before a widget receiver returns to the system.
        check(prefs.edit().putString("tasks", data.toString()).putString("lists", listData.toString()).commit()) { "Could not save tasks" }
        TodoWidget.refresh(context)
        Reminders.schedule(context, tasks)
    }
}
