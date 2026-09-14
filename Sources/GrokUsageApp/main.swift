// Sources/GrokUsageApp/main.swift
import AppKit
import SharedQuotaKit

@main
@MainActor
struct GrokAppMain {
    static var delegateHolder: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        delegateHolder = delegate
        app.delegate = delegate
        delegate.setup()
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    public var menuBarManager: MenuBarManager?

    public func setup() {
        guard menuBarManager == nil else { return }
        let provider = GrokDataProvider()
        menuBarManager = MenuBarManager(brand: .grok, dataProvider: provider)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setup()
    }
}
