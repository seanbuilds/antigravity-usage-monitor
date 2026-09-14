// Sources/SharedQuotaKit/Windowing/MenuBarManager.swift
import AppKit
import SwiftUI

@MainActor
public final class MenuBarManager: NSObject, NSPopoverDelegate {
    public let brand: BrandIdentity
    public let dataProvider: any QuotaDataProvider
    public let viewModel: DashboardViewModel

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var hudPanel: HUDPanel?
    private var pollTimer: Timer?
    private var tickTimer: Timer?

    public init(brand: BrandIdentity, dataProvider: any QuotaDataProvider) {
        self.brand = brand
        self.dataProvider = dataProvider
        self.viewModel = DashboardViewModel()
        super.init()

        setupUI()
        setupTimers()
        refreshData()
    }

    private func setupUI() {
        // Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let cached = AppGroupPersistence.shared.loadSnapshot(for: brand) {
                viewModel.snapshot = cached
                button.title = cached.menuBarTitle
            } else {
                button.title = "\(brand.statusSymbol) --%"
            }
            button.target = self
            button.action = #selector(handleStatusClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // ViewModel callbacks
        viewModel.onToggleUnsnap = { [weak self] in
            self?.toggleUnsnap()
        }
        viewModel.onRefresh = { [weak self] in
            self?.refreshData()
        }
        viewModel.onQuit = {
            NSApp.terminate(nil)
        }

        // Popover
        let hosting = NSHostingController(rootView: SharedDashboardView(viewModel: viewModel))
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor

        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 380)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = hosting

        setupMainMenu()
    }

    private func setupTimers() {
        // Data Poll Timer (every 30 seconds)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshData()
            }
        }

        // Local 1-second countdown ticker for smooth UI updates
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.decrementTickers()
            }
        }
    }

    public func refreshData() {
        viewModel.isLoading = true
        Task {
            do {
                let snapshot = try await dataProvider.fetchQuota()
                self.viewModel.snapshot = snapshot
                self.viewModel.isOffline = false
                self.viewModel.isLoading = false
                AppGroupPersistence.shared.saveSnapshot(snapshot)
                self.updateStatusItem()
            } catch {
                self.viewModel.isOffline = true
                self.viewModel.isLoading = false
                if let cached = AppGroupPersistence.shared.loadSnapshot(for: brand) {
                    self.viewModel.snapshot = cached
                }
                self.statusItem.button?.title = "\(brand.statusSymbol) (offline)"
            }
        }
    }

    private func decrementTickers() {
        guard let current = viewModel.snapshot else { return }
        var updatedGroups = [ModelQuotaGroup]()
        for grp in current.groups {
            let pLimit = grp.primaryLimit
            let sLimit = grp.secondaryLimit

            let newPResets = (pLimit.resetsInSeconds ?? 0) > 1 ? (pLimit.resetsInSeconds! - 1) : pLimit.resetsInSeconds
            let newSResets = (sLimit.resetsInSeconds ?? 0) > 1 ? (sLimit.resetsInSeconds! - 1) : sLimit.resetsInSeconds

            let newP = RateLimitWindow(name: pLimit.name, iconName: pLimit.iconName, fraction: pLimit.fraction, resetsInSeconds: newPResets, resetTime: pLimit.resetTime)
            let newS = RateLimitWindow(name: sLimit.name, iconName: sLimit.iconName, fraction: sLimit.fraction, resetsInSeconds: newSResets, resetTime: sLimit.resetTime)
            updatedGroups.append(ModelQuotaGroup(title: grp.title, subtitle: grp.subtitle, primaryLimit: newP, secondaryLimit: newS))
        }

        let updated = UnifiedQuotaSnapshot(
            brand: current.brand,
            account: current.account,
            tier: current.tier,
            tierId: current.tierId,
            description: current.description,
            groups: updatedGroups,
            lastUpdated: current.lastUpdated
        )
        self.viewModel.snapshot = updated
        self.updateStatusItem()
    }

    private func updateStatusItem() {
        guard let snapshot = viewModel.snapshot, let button = statusItem.button else { return }
        button.title = snapshot.menuBarTitle

        var tooltip = "\(brand.displayName) (\(snapshot.tier)):\n"
        for grp in snapshot.groups {
            tooltip += "• \(grp.title): \(grp.primaryLimit.percentage)% (\(formatRelativeTime(seconds: grp.primaryLimit.resetsInSeconds)))\n"
        }
        button.toolTip = tooltip
    }

    @objc private func handleStatusClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePresentation()
        }
    }

    public func togglePresentation() {
        if viewModel.isUnsnapped {
            if let hud = hudPanel {
                if hud.isVisible {
                    hud.orderOut(nil)
                } else {
                    hud.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        } else {
            if popover.isShown {
                popover.performClose(nil)
            } else if let button = statusItem.button {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    public func toggleUnsnap() {
        if viewModel.isUnsnapped {
            // Snap back to Popover
            viewModel.isUnsnapped = false
            hudPanel?.orderOut(nil)
            hudPanel = nil
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        } else {
            // Detach to floating HUD
            viewModel.isUnsnapped = true
            if popover.isShown {
                popover.close()
            }
            let screen = statusItem.button?.window?.screen ?? NSScreen.main
            let hud = HUDPanel.makeHUD(for: screen)
            let hosting = NSHostingController(rootView: SharedDashboardView(viewModel: viewModel))
            hosting.view.wantsLayer = true
            hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
            hud.contentViewController = hosting
            hud.makeKeyAndOrderFront(nil)
            hudPanel = hud
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "\(brand.displayName) (\(viewModel.snapshot?.tier ?? "Active"))", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Refresh Quota", action: #selector(refreshClicked), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: viewModel.isUnsnapped ? "Snap to Menu Bar" : "Unsnap to HUD", action: #selector(unsnapClicked), keyEquivalent: "u"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func refreshClicked() { refreshData() }
    @objc private func unsnapClicked() { toggleUnsnap() }
    @objc private func quitClicked() { NSApp.terminate(nil) }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About \(brand.displayName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        let unsnapItem = NSMenuItem(title: "Unsnap / Snap Window", action: #selector(unsnapClicked), keyEquivalent: "u")
        unsnapItem.target = self
        appMenu.addItem(unsnapItem)

        let reloadItem = NSMenuItem(title: "Refresh Data", action: #selector(refreshClicked), keyEquivalent: "r")
        reloadItem.target = self
        appMenu.addItem(reloadItem)
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit \(brand.displayName)", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)

        NSApp.mainMenu = mainMenu
    }
}
