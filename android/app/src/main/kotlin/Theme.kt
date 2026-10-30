package com.widgettodo

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import org.json.JSONObject

class Theme(val json: JSONObject, private val context: Context) {
    val id = json.getString("id")
    val name = json.getString("name")
    val dark = json.optString("colorScheme") == "dark"
    val background = json.getJSONObject("background")
    val colors = background.getJSONArray("colors").let { a -> (0 until a.length()).map { Color.parseColor(a.getString(it)) }.toIntArray() }
    val primary = color("textPrimary")
    val secondary = color("textSecondary")
    val accent = color("accent")
    val overdue = color("overdue")
    val font = json.getJSONObject("font")
    val typeface: Typeface get() = when (font.optString("family")) {
        "serif" -> Typeface.SERIF
        "mono" -> Typeface.MONOSPACE
        "custom" -> Typeface.createFromAsset(context.assets, "fonts/" + when (font.optString("customName")) {
            "Caveat-Regular" -> "Caveat-Variable.ttf"
            "PressStart2P-Regular" -> "PressStart2P-Regular.ttf"
            else -> "IBMPlexMono-Regular.ttf"
        })
        "rounded" -> Typeface.create("sans-serif-rounded", Typeface.NORMAL)
        else -> Typeface.DEFAULT
    }
    val scale = font.optDouble("scale", 1.0).toFloat()
    val row = json.getJSONObject("row")
    val prefix = json.getJSONObject("header").optString("prefix")
    val checkbox get() = when (json.optString("checkbox")) { "square" -> "□"; "bracket" -> "[ ]"; "dot" -> "·"; "strike" -> "—"; else -> "○" }
    fun cased(value: String) = when (font.optString("case")) { "upper" -> value.uppercase(); "lower" -> value.lowercase(); else -> value }
    private fun color(key: String) = Color.parseColor(json.getString(key))
    companion object {
        fun all(context: Context): List<Theme> {
            val ids = org.json.JSONArray(context.assets.open("themes/index.json").bufferedReader().use { it.readText() })
            return (0 until ids.length()).map { i ->
                val id = ids.getString(i)
                Theme(JSONObject(context.assets.open("themes/$id.json").bufferedReader().use { it.readText() }), context)
            }
        }
        fun selected(context: Context, id: String): Theme = all(context).let { themes ->
            themes.find { it.id == id && Billing.unlocked(context, it.id) } ?: themes.first()
        }
    }
}
