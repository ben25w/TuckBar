import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: IconRegistryStore
    @ObservedObject var dockIconController: DockIconController
    let onRefresh: () -> Void
    let onRequestPermission: () -> Void
    let onPress: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SettingsToolbar(
                store: store,
                dockIconController: dockIconController,
                onRefresh: onRefresh,
                onRequestPermission: onRequestPermission
            )

            Divider()

            if !store.hasAccessibilityPermission {
                VStack(spacing: 14) {
                    Image(systemName: "accessibility")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("Accessibility access is needed before TuckBar can discover and press menu-bar items.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Open Settings", action: onRequestPermission)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)
            } else if store.records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text("No menu-bar items detected yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Refresh", action: onRefresh)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.records) { record in
                        SettingsItemRow(
                            record: record,
                            canMoveUp: record.sortIndex > 0,
                            canMoveDown: record.sortIndex < store.records.count - 1,
                            onPlacementChange: { store.setPlacementMode($0, for: record.id) },
                            onMoveUp: { store.moveRecord(id: record.id, direction: .up) },
                            onMoveDown: { store.moveRecord(id: record.id, direction: .down) },
                            onPress: { onPress(record.id) }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 680, minHeight: 460)
    }
}

private struct SettingsToolbar: View {
    @ObservedObject var store: IconRegistryStore
    @ObservedObject var dockIconController: DockIconController
    let onRefresh: () -> Void
    let onRequestPermission: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: StatusIconFactory.statusItemImage(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text("TuckBar")
                    .font(.headline)
                Text(store.lastScanSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Dock icon", isOn: Binding(
                get: { dockIconController.isDockIconVisible },
                set: { dockIconController.setDockIconVisible($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            if !store.hasAccessibilityPermission {
                Button(action: onRequestPermission) {
                    Label("Permission", systemImage: "lock.open")
                }
            }

            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .padding(16)
    }
}

private struct SettingsItemRow: View {
    let record: MenuBarItemRecord
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onPlacementChange: (PlacementMode) -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onPress: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.isAvailable ? "app.badge" : "app.dashed")
                .frame(width: 22)
                .foregroundStyle(record.isAvailable ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.displayName)
                    .font(.body)
                    .lineLimit(1)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Picker("Placement", selection: Binding(
                get: { record.placementMode },
                set: onPlacementChange
            )) {
                ForEach(PlacementMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .frame(width: 110)

            HStack(spacing: 4) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                }
                .disabled(!canMoveUp)
                .help("Move up")

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                }
                .disabled(!canMoveDown)
                .help("Move down")
            }
            .buttonStyle(.borderless)

            Button(action: onPress) {
                Image(systemName: "cursorarrow.click")
            }
            .disabled(!record.isAvailable)
            .help("Click backing menu-bar item")
        }
        .padding(.vertical, 7)
        .opacity(record.isAvailable ? 1.0 : 0.55)
    }

    private var statusText: String {
        var parts = [record.processName]
        if !record.isAvailable {
            parts.append("not running")
        } else if record.hideSupportStatus == .virtualOnlyUnsupported, record.placementMode == .virtualMenu {
            parts.append("real icon remains visible")
        }
        return parts.joined(separator: " - ")
    }
}
