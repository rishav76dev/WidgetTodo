#if canImport(SwiftUI)
import CoreText
import Foundation

/// Registers the bundled OFL fonts (`Shared/Fonts`) for this process.
public enum FontRegistration {
    /// Safe to call repeatedly and from any target; fonts already loaded (for example through
    /// `UIAppFonts` in Info.plist) are skipped.
    public static func registerBundledFonts() {
        _ = registration
    }

    private static let registration: Void = {
        let urls = ["Fonts", nil].flatMap { Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: $0) ?? [] }
        for url in urls where !isLoaded(url) {
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// True when every font in the file is already available by its PostScript name.
    private static func isLoaded(_ url: URL) -> Bool {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              !descriptors.isEmpty else { return false }
        return descriptors.allSatisfy { descriptor in
            guard let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String else { return false }
            let font = CTFontCreateWithName(name as CFString, 12, nil)
            return CTFontCopyPostScriptName(font) as String == name
        }
    }
}
#endif
