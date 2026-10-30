package com.widgettodo

import android.Manifest
import android.app.*
import android.appwidget.AppWidgetManager
import android.content.*
import android.content.pm.PackageManager
import android.graphics.*
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.*
import android.view.*
import android.view.inputmethod.InputMethodManager
import android.widget.*
import java.time.*
import java.time.format.DateTimeFormatter

class MainActivity : Activity() {
    private lateinit var store: Store
    private lateinit var theme: Theme
    private lateinit var root: LinearLayout
    private var filter = "all"
    private var page = "home"
    private var showCompleted = false
    private var undo: Task? = null
    private val handler = Handler(Looper.getMainLooper())
    private val clock = object : Runnable {
        override fun run() { if (page == "home" && !isFinishing) render(); handler.postDelayed(this, 60_000) }
    }

    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        filter = state?.getString("filter") ?: "all"
        page = state?.getString("page") ?: "home"
        store = Store(this)
        store.cleanup()
        render()
        Billing.start(this) { runOnUiThread { render() } }
        if (!store.prefs.getBoolean("onboarded", false)) onboarding() else route(intent)
    }
    override fun onResume() { super.onResume(); if (::store.isInitialized) { store = Store(this); render() }; handler.postDelayed(clock, 60_000) }
    override fun onPause() { handler.removeCallbacks(clock); super.onPause() }
    override fun onSaveInstanceState(outState: Bundle) { outState.putString("filter", filter); outState.putString("page", page); super.onSaveInstanceState(outState) }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); store = Store(this); route(intent) }
    private fun route(intent: Intent) {
        val uri = intent.data ?: return
        filter = uri.getQueryParameter("filter") ?: filter
        when (uri.host) {
            "add" -> { page = "home"; render(); editTask(null) }
            "task" -> { page = "home"; render(); store.tasks.find { it.id == uri.lastPathSegment }?.let { editTask(it) } }
            "widget" -> uri.lastPathSegment?.toIntOrNull()?.let(::configureWidget)
            else -> { page = "home"; render() }
        }
        intent.data = null
    }
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() { if (page != "home") { page = "home"; render() } else super.onBackPressed() }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun column() = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    private fun row() = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
    private fun label(value: String, size: Float = 16f, secondary: Boolean = false) = TextView(this).apply {
        text = theme.cased(value); textSize = size * theme.scale; setTextColor(if (secondary) theme.secondary else theme.primary); typeface = theme.typeface
        setPadding(dp(4), dp(8), dp(4), dp(8))
    }
    private fun button(value: String, action: () -> Unit) = Button(this).apply {
        text = value; isAllCaps = false; typeface = theme.typeface; setTextColor(theme.primary); minHeight = dp(48); setOnClickListener { action() }
        backgroundTintList = android.content.res.ColorStateList.valueOf(if (theme.dark) Color.rgb(45, 45, 45) else Color.rgb(236, 233, 226))
    }
    private fun scroll(content: LinearLayout) { root.addView(ScrollView(this).apply { isFillViewport = true; addView(content) }, LinearLayout.LayoutParams(-1, 0, 1f)) }
    private fun heading(content: LinearLayout, text: String) { content.addView(label(text, 13f, true).apply { setPadding(dp(4), dp(22), dp(4), dp(8)); letterSpacing = .10f }) }

    private fun render() {
        theme = Theme.selected(this, store.themeId)
        window.statusBarColor = theme.colors.first(); window.navigationBarColor = theme.colors.first()
        window.decorView.systemUiVisibility = if (theme.dark) 0 else View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        root = column().apply { setPadding(dp(16), dp(8), dp(16), dp(8)); background = ThemeBackground(theme) }
        // Keep controls clear of Android 15 edge-to-edge system bars and the keyboard.
        root.setOnApplyWindowInsetsListener { view, insets ->
            if (Build.VERSION.SDK_INT >= 30) {
                val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.ime())
                view.setPadding(dp(16) + bars.left, dp(8) + bars.top, dp(16) + bars.right, dp(8) + bars.bottom)
            }
            insets
        }
        setContentView(root)
        val bar = row()
        if (page != "home") bar.addView(button("‹") { page = "home"; render() })
        val title = when (page) { "themes" -> "Themes"; "lists" -> "Lists"; "settings" -> "Settings"; else -> filterTitle() }
        bar.addView(label(theme.prefix + title, 30f).apply { setTypeface(theme.typeface, Typeface.BOLD) }, LinearLayout.LayoutParams(0, -2, 1f))
        root.addView(bar)
        when (page) { "themes" -> themes(); "lists" -> lists(); "settings" -> settings(); else -> home() }
    }
    private fun filterTitle() = when (filter) { "all" -> "All Tasks"; "today" -> "Today"; else -> store.lists.find { it.id == filter }?.name ?: "All Tasks" }

    private fun home() {
        val nav = row()
        listOf("Themes" to "themes", "Lists" to "lists", "Settings" to "settings").forEach { (title, target) -> nav.addView(button(title) { page = target; render() }, LinearLayout.LayoutParams(0, -2, 1f)) }
        root.addView(nav)
        val chips = row()
        (listOf("all" to "All", "today" to "Today") + store.lists.map { it.id to it.name }).forEach { (id, name) ->
            chips.addView(button(if (filter == id) "• $name" else name) { filter = id; render() })
        }
        root.addView(HorizontalScrollView(this).apply { isHorizontalScrollBarEnabled = false; addView(chips) })
        val body = column()
        val now = LocalDateTime.now()
        val visible = visibleTasks(store.tasks, filter, now)
        if (visible.isEmpty()) {
            body.addView(label("All clear", 32f).apply { gravity = Gravity.CENTER; setPadding(0, dp(100), 0, dp(8)) })
            body.addView(label("Tap + to add a task.", 16f, true).apply { gravity = Gravity.CENTER })
        }
        val groups = visible.groupBy { it.group(now) }
        listOf("Overdue", "Today", "Tomorrow", "Upcoming", "No date", "Completed").forEach { group ->
            val tasks = groups[group].orEmpty()
            if (tasks.isNotEmpty()) {
                if (group == "Completed") body.addView(button("${if (showCompleted) "▾" else "▸"} Completed (${tasks.size})") { showCompleted = !showCompleted; render() })
                else heading(body, group)
                if (group != "Completed" || showCompleted) tasks.forEach { task -> body.addView(taskRow(task)) }
            }
        }
        scroll(body)
        val bottom = row()
        val deleted = undo
        if (deleted != null) bottom.addView(button("Undo delete") { store.save(deleted); undo = null; render() }, LinearLayout.LayoutParams(0, -2, 1f))
        else bottom.addView(label("${visible.count { !it.completed }} remaining", 13f, true), LinearLayout.LayoutParams(0, -2, 1f))
        bottom.addView(button("+ Add task") { editTask(null) })
        root.addView(bottom)
    }
    private fun taskRow(task: Task): View {
        val wrap = column()
        val line = row().apply { minimumHeight = dp(58) }
        val check = label(if (task.completed) "✓" else theme.checkbox, 25f).apply {
            gravity = Gravity.CENTER; contentDescription = if (task.completed) "Mark ${task.title} incomplete" else "Complete ${task.title}"
            setTextColor(theme.accent); isClickable = true; isFocusable = true
            setOnClickListener { store.toggle(task.id); performHapticFeedback(HapticFeedbackConstants.CONFIRM); render() }
        }
        line.addView(check, LinearLayout.LayoutParams(dp(48), dp(52)))
        val texts = column()
        texts.addView(label(task.title).apply {
            if (task.completed) { paintFlags = paintFlags or Paint.STRIKE_THRU_TEXT_FLAG; alpha = .55f }
            if (task.overdue(LocalDateTime.now())) setTextColor(theme.overdue)
        })
        val detail = listOfNotNull(task.due?.format(DateTimeFormatter.ofPattern(if (task.timed) "EEE, MMM d · HH:mm" else "EEE, MMM d")),
            if (task.repeat != "none") "↻ ${task.repeat}" else null,
            store.lists.find { it.id == task.listId }?.name?.takeIf { filter != task.listId }).joinToString(" · ")
        if (detail.isNotEmpty()) texts.addView(label(detail, 12f, true))
        texts.setOnClickListener { editTask(task) }; texts.isFocusable = true; texts.contentDescription = "Edit ${task.title}"
        line.addView(texts, LinearLayout.LayoutParams(0, -2, 1f))
        line.setOnLongClickListener { deleteTask(task); true }
        if (theme.row.optString("style") == "card") line.background = GradientDrawable().apply { setColor(if (theme.dark) 0x33222222 else 0x22FFFFFF); cornerRadius = dp(10).toFloat() }
        wrap.addView(line)
        if (theme.row.optString("style") in listOf("divider", "dashed")) wrap.addView(View(this).apply { setBackgroundColor(theme.secondary); alpha = .2f }, LinearLayout.LayoutParams(-1, dp(1)))
        wrap.setPadding(0, dp(theme.row.optDouble("spacing", 6.0).toInt() / 2), 0, dp(3))
        return wrap
    }
    private fun deleteTask(task: Task) {
        AlertDialog.Builder(this).setTitle("Delete task?").setMessage(task.title).setNegativeButton("Cancel", null).setPositiveButton("Delete") { _, _ ->
            store.delete(task.id); undo = task; render()
            handler.postDelayed({ if (undo?.id == task.id) { undo = null; if (page == "home") render() } }, 5000)
        }.show()
    }

    private fun editTask(original: Task?) {
        val content = column().apply { setPadding(dp(20), dp(8), dp(20), dp(16)) }
        val title = EditText(this).apply { hint = "What needs doing?"; setText(original?.title ?: ""); filters = arrayOf(android.text.InputFilter.LengthFilter(500)); inputType = android.text.InputType.TYPE_CLASS_TEXT or android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES }
        val notes = EditText(this).apply { hint = "Notes"; setText(original?.notes ?: ""); minLines = 2; inputType = android.text.InputType.TYPE_CLASS_TEXT or android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE }
        content.addView(title); content.addView(notes)
        var due = original?.due ?: LocalDate.now().atTime(9, 0)
        val dateOn = CheckBox(this).apply { text = "Date"; isChecked = original?.due != null || (original == null && filter == "today") }
        val timeOn = CheckBox(this).apply { text = "Time / reminder"; isChecked = original?.timed ?: false }
        val dateButton = button("") {}
        val timeButton = button("") {}
        fun refreshDate() {
            dateButton.text = due.format(DateTimeFormatter.ofPattern("EEEE, MMM d, yyyy")); timeButton.text = due.format(DateTimeFormatter.ofPattern("HH:mm"))
            dateButton.visibility = if (dateOn.isChecked) View.VISIBLE else View.GONE
            timeOn.visibility = dateButton.visibility
            timeButton.visibility = if (dateOn.isChecked && timeOn.isChecked) View.VISIBLE else View.GONE
        }
        dateButton.setOnClickListener { DatePickerDialog(this, { _, y, m, d -> due = LocalDate.of(y, m + 1, d).atTime(due.toLocalTime()); refreshDate() }, due.year, due.monthValue - 1, due.dayOfMonth).show() }
        timeButton.setOnClickListener { TimePickerDialog(this, { _, h, m -> due = due.withHour(h).withMinute(m); refreshDate() }, due.hour, due.minute, true).show() }
        dateOn.setOnCheckedChangeListener { _, _ -> refreshDate() }; timeOn.setOnCheckedChangeListener { _, _ -> refreshDate() }
        content.addView(dateOn); content.addView(dateButton); content.addView(timeOn); content.addView(timeButton)
        val repeats = listOf("none", "daily", "weekdays", "weekly", "monthly", "yearly")
        content.addView(TextView(this).apply { text = "Repeat" })
        val repeat = Spinner(this).apply { adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, listOf("Never", "Daily", "Weekdays", "Weekly", "Monthly", "Yearly")); setSelection(repeats.indexOf(original?.repeat ?: "none").coerceAtLeast(0)) }
        content.addView(repeat)
        content.addView(TextView(this).apply { text = "List" })
        val lists = Spinner(this).apply { adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, store.lists.map { it.name }); setSelection(store.lists.indexOfFirst { it.id == (original?.listId ?: filter) }.coerceAtLeast(0)) }
        content.addView(lists); refreshDate()
        val dialog = AlertDialog.Builder(this).setTitle(if (original == null) "Add Task" else "Edit Task").setView(ScrollView(this).apply { addView(content) }).setNegativeButton("Cancel", null).setPositiveButton("Save", null)
        if (original != null) dialog.setNeutralButton("Delete") { _, _ -> deleteTask(original) }
        val shown = dialog.create(); shown.setOnShowListener {
            shown.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                if (title.text.toString().isBlank()) { title.error = "Enter a task title"; return@setOnClickListener }
                val task = (original ?: Task(title = "")).copy(title = title.text.toString(), notes = notes.text.toString(),
                    due = if (!dateOn.isChecked) null else if (timeOn.isChecked) due.withSecond(0).withNano(0) else due.toLocalDate().atStartOfDay(),
                    timed = dateOn.isChecked && timeOn.isChecked, repeat = if (dateOn.isChecked) repeats[repeat.selectedItemPosition] else "none", listId = store.lists[lists.selectedItemPosition].id)
                try { store.save(task); if (task.timed) { store.reminders = true; requestNotifications() }; shown.dismiss(); render() }
                catch (e: IllegalStateException) { Toast.makeText(this, "Couldn't save. Please try again.", Toast.LENGTH_LONG).show() }
            }
        }; shown.show()
    }

    private fun themes() {
        val content = column()
        content.addView(label("Your tasks. Your style.", 18f, true))
        Theme.all(this).forEach { candidate ->
            val card = column().apply { background = ThemeBackground(candidate); setPadding(dp(16), dp(12), dp(16), dp(12)) }
            val unlocked = Billing.unlocked(this, candidate.id)
            card.addView(TextView(this).apply { text = "${candidate.name}${if (candidate.id == store.themeId) "  ✓" else ""}${if (!unlocked) "  · Premium" else ""}"; textSize = 22f; typeface = candidate.typeface; setTextColor(candidate.primary) })
            listOf("A little more focus", "Make room for what matters").forEach { text -> card.addView(TextView(this).apply { this.text = candidate.cased("${candidate.checkbox}  $text"); textSize = 16f; typeface = candidate.typeface; setTextColor(candidate.primary); setPadding(0, dp(8), 0, dp(4)) }) }
            card.addView(button(if (candidate.id == store.themeId) "Selected" else if (unlocked) "Use ${candidate.name}" else "Unlock Premium") {
                if (unlocked) { store.themeId = candidate.id; render() } else Billing.paywall(this) { render() }
            })
            content.addView(card, LinearLayout.LayoutParams(-1, -2).apply { bottomMargin = dp(14) })
        }
        scroll(content)
    }
    private fun lists() {
        val content = column()
        store.lists.forEach { list ->
            val line = row()
            line.addView(button("${list.name} (${store.tasks.count { it.listId == list.id && !it.completed }})") { filter = list.id; page = "home"; render() }, LinearLayout.LayoutParams(0, -2, 1f))
            line.addView(button("Edit") { editList(list) })
            if (list.id != "inbox") line.addView(button("×") {
                AlertDialog.Builder(this).setTitle("Delete ${list.name}?").setMessage("Its tasks will move to Inbox.").setNegativeButton("Cancel", null).setPositiveButton("Delete") { _, _ -> store.deleteList(list.id); if (filter == list.id) filter = "all"; render() }.show()
            }.apply { contentDescription = "Delete ${list.name}" })
            content.addView(line)
        }
        content.addView(button("+ New list") { editList(null) }); scroll(content)
    }
    private fun editList(list: TaskList?) {
        val input = EditText(this).apply { hint = "List name"; setText(list?.name ?: ""); filters = arrayOf(android.text.InputFilter.LengthFilter(80)) }
        val dialog = AlertDialog.Builder(this).setTitle(if (list == null) "New List" else "Rename List").setView(input).setNegativeButton("Cancel", null).setPositiveButton("Save", null).create()
        dialog.setOnShowListener { dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
            if (input.text.isBlank()) { input.error = "Enter a name" } else { store.saveList(TaskList(list?.id ?: java.util.UUID.randomUUID().toString(), input.text.toString())); dialog.dismiss(); render() }
        } }; dialog.show()
    }
    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 42)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 42) { Reminders.schedule(this, store.tasks); if (page == "settings") render() }
    }
    private fun settings() {
        val content = column()
        heading(content, "Premium")
        content.addView(label(if (Billing.unlocked(this, "terminal")) "Premium is active" else "Free plan · 3 themes", 18f))
        content.addView(button("Unlock all 12 themes") { Billing.paywall(this) { render() } })
        content.addView(button("Restore purchases") { Billing.restore(this) { render() } })
        content.addView(button("Manage subscription") { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/account/subscriptions"))) })
        heading(content, "Notifications")
        content.addView(Switch(this).apply { text = "Reminders"; setTextColor(theme.primary); isChecked = store.reminders; setOnCheckedChangeListener { _, enabled -> store.reminders = enabled; if (enabled) requestNotifications() } })
        content.addView(label("Get a reminder for tasks with a due time. Android battery settings may delay delivery.", 14f, true))
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) content.addView(button("Enable notifications in Settings") { startActivity(Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)) })
        heading(content, "Data")
        content.addView(label("Tasks stay on this device. Android backup can restore them when you change phones. Live sync with iCloud is unavailable on Android.", 14f, true))
        heading(content, "Home-screen widget")
        content.addView(label("Touch and hold your Home Screen, choose Widgets, then Todo1. Tap ⋯ on a widget to choose its list and theme.", 14f, true))
        if (AppWidgetManager.getInstance(this).isRequestPinAppWidgetSupported) content.addView(button("Add widget") { AppWidgetManager.getInstance(this).requestPinAppWidget(ComponentName(this, TodoWidget::class.java), null, null) })
        heading(content, "About")
        content.addView(button("Privacy Policy") { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/rishav76dev/WidgetTodo/blob/main/site/privacy.html"))) })
        content.addView(button("Terms of Use") { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/rishav76dev/WidgetTodo/blob/main/site/terms.html"))) })
        content.addView(label("Todo1 · ${BuildConfig.VERSION_NAME}", 13f, true)); scroll(content)
    }
    private fun onboarding() {
        AlertDialog.Builder(this).setTitle("A little more focus.").setMessage("Welcome to Todo1. Keep tasks in simple lists, choose your style, and tick things off right from your Home Screen.\n\nThree themes are free. Premium unlocks all twelve.").setPositiveButton("Get started") { _, _ -> store.prefs.edit().putBoolean("onboarded", true).apply(); route(intent) }.setCancelable(false).show()
    }
    private fun configureWidget(id: Int) {
        val prefs = getSharedPreferences("widgets", 0)
        val content = column().apply { setPadding(dp(20), dp(12), dp(20), dp(12)) }
        val filters = listOf("all" to "All Tasks", "today" to "Today") + store.lists.map { it.id to it.name }
        val themes = Theme.all(this).filter { Billing.unlocked(this, it.id) }
        val lists = Spinner(this).apply { adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, filters.map { it.second }); setSelection(filters.indexOfFirst { it.first == prefs.getString("filter:$id", "all") }.coerceAtLeast(0)) }
        val styles = Spinner(this).apply { adapter = ArrayAdapter(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, themes.map { it.name }); setSelection(themes.indexOfFirst { it.id == prefs.getString("theme:$id", store.themeId) }.coerceAtLeast(0)) }
        content.addView(TextView(this).apply { text = "List" }); content.addView(lists); content.addView(TextView(this).apply { text = "Theme" }); content.addView(styles)
        AlertDialog.Builder(this).setTitle("Widget style").setView(content).setNegativeButton("Cancel", null).setPositiveButton("Save") { _, _ ->
            prefs.edit().putString("filter:$id", filters[lists.selectedItemPosition].first).putString("theme:$id", themes[styles.selectedItemPosition].id).apply(); TodoWidget.refresh(this)
        }.show()
    }
}

class ThemeBackground(private val theme: Theme) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    override fun draw(canvas: Canvas) {
        paint.shader = if (theme.colors.size > 1) LinearGradient(0f, 0f, bounds.width().toFloat(), bounds.height().toFloat(), theme.colors, null, Shader.TileMode.CLAMP) else null
        paint.color = theme.colors.first(); canvas.drawRect(bounds, paint); paint.shader = null
        if (theme.background.optString("type") == "grid") {
            paint.color = Color.parseColor(theme.background.optString("gridColor", "#334466")); paint.strokeWidth = 1f
            val step = 28f * android.content.res.Resources.getSystem().displayMetrics.density
            var x = bounds.left.toFloat(); while (x < bounds.right) { canvas.drawLine(x, bounds.top.toFloat(), x, bounds.bottom.toFloat(), paint); x += step }
            var y = bounds.top.toFloat(); while (y < bounds.bottom) { canvas.drawLine(bounds.left.toFloat(), y, bounds.right.toFloat(), y, paint); y += step }
        }
    }
    override fun setAlpha(alpha: Int) { paint.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java") override fun getOpacity() = PixelFormat.OPAQUE
}
