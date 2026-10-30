package com.widgettodo

import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDateTime

class TaskTest {
    private val now = LocalDateTime.of(2026, 10, 30, 12, 0)
    @Test fun allDayTaskIsNotOverdueUntilNextDay() {
        val task = Task(title = "Read", due = now.toLocalDate().atStartOfDay())
        assertFalse(task.overdue(now))
        assertTrue(task.overdue(now.plusDays(1)))
    }
    @Test fun todayIncludesOverdueButNotUndated() {
        val overdue = Task(title = "Late", due = now.minusDays(1))
        val today = Task(title = "Today", due = now)
        val undated = Task(title = "Someday")
        assertEquals(setOf(overdue.id, today.id), visibleTasks(listOf(overdue, today, undated), "today", now).map { it.id }.toSet())
    }
    @Test fun monthlyRecurrenceDoesNotDriftAfterFebruary() {
        val task = Task(title = "Rent", due = LocalDateTime.of(2026, 1, 31, 9, 0), repeat = "monthly")
        assertEquals(LocalDateTime.of(2026, 3, 31, 9, 0), task.nextOccurrence(LocalDateTime.of(2026, 3, 1, 0, 0)))
    }
    @Test fun weekdaysSkipsWeekendAndPastOccurrences() {
        val task = Task(title = "Work", due = now.withHour(9), repeat = "weekdays")
        assertEquals(LocalDateTime.of(2026, 11, 2, 9, 0), task.nextOccurrence(now))
    }
    @Test fun completedTasksAreNeverOverdue() {
        assertEquals("Completed", Task(title = "Done", due = now.minusDays(2), completedAt = now).group(now))
    }
    @Test fun yearlyRecurrenceKeepsLeapDayAnchor() {
        val task = Task(title = "Leap", due = LocalDateTime.of(2024, 2, 29, 9, 0), repeat = "yearly")
        assertEquals(LocalDateTime.of(2028, 2, 29, 9, 0), task.nextOccurrence(LocalDateTime.of(2027, 3, 1, 0, 0)))
    }
}
