// Sources/SharedQuotaKit/UI/HUDPanel.swift
import AppKit
import SwiftUI

public final class HUDPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    public static func makeHUD(for screen: NSScreen?, size: NSSize = NSSize(width: 360, height: 380)) -> HUDPanel {
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first!
        let visible = targetScreen.visibleFrame

        // Place at top-right of the target screen with 20px margin
        let x = visible.maxX - size.width - 24
        let y = visible.maxY - size.height - 12
        let rect = NSRect(x: x, y: y, width: size.width, height: size.height)

        return HUDPanel(contentRect: rect)
    }

    public func clampToScreen() {
        guard let screen = self.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        var frame = self.frame

        if frame.maxX > visible.maxX {
            frame.origin.x = visible.maxX - frame.width
        }
        if frame.minX < visible.minX {
            frame.origin.x = visible.minX
        }
        if frame.maxY > visible.maxY {
            frame.origin.y = visible.maxY - frame.height
        }
        if frame.minY < visible.minY {
            frame.origin.y = visible.minY
        }
        self.setFrame(frame, display: true)
    }
}
