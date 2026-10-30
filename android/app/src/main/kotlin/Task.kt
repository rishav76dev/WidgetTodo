package com.widgettodo

import java.time.*
import java.util.UUID

data class Task(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val notes: String = "",
    val due: LocalDateTime? = null,
    val timed: Boolean = false,
    val repeat: String = "none",
    val listId: String = "inbox",
    val completedAt: LocalDateTime? = null,
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    val completed get() = completedAt != null
    fun overdue(now: LocalDateTime): Boolean = !completed && due != null &&
        if (timed) due < now else due.toLocalDate() < now.toLocalDate()
    fun group(now: LocalDateTime): String = when {
        completed -> "Completed"
        overdue(now) -> "Overdue"
        due == null -> "No date"
        due.toLocalDate() == now.toLocalDate() -> "Today"
        due.toLocalDate() == now.toLocalDate().plusDays(1) -> "Tomorrow"
        else -> "Upcoming"
    }
    fun nextOccurrence(now: LocalDateTime): LocalDateTime? {
        val original = due ?: return null
        if (repeat == "none") return null
        for (k in 1L..10000L) {
            val next = when (repeat) {
                "daily", "weekdays" -> original.plusDays(k)
                "weekly" -> original.plusWeeks(k)
                "monthly" -> original.plusMonths(k)
                "yearly" -> original.plusYears(k)
                else -> return null
            }
            if (repeat == "weekdays" && next.dayOfWeek in listOf(DayOfWeek.SATURDAY, DayOfWeek.SUNDAY)) continue
            if (next > now) return next
        }
        return null
    }
}
data class TaskList(val id: String = UUID.randomUUID().toString(), val name: String)

fun visibleTasks(tasks: List<Task>, filter: String, now: LocalDateTime = LocalDateTime.now()) = tasks.filter {
    when (filter) {
        "all" -> true
        "today" -> it.due?.toLocalDate() == now.toLocalDate() || it.overdue(now)
        else -> it.listId == filter
    }
}.sortedWith(compareBy<Task> { it.due == null }.thenBy { it.due }.thenBy { it.createdAt })
