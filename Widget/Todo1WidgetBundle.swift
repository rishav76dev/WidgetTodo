import SwiftUI
import TodoUI
import WidgetKit

@main
struct Todo1WidgetBundle: WidgetBundle {
    init() {
        FontRegistration.registerBundledFonts()
    }

    var body: some Widget {
        TaskListWidget()
    }
}
