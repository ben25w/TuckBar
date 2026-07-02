import SwiftUI

struct VirtualShelfView: View {
    @ObservedObject var store: IconRegistryStore
    let hasAccessibilityPermission: Bool
    let onRefresh: () -> Void
    let onRequestPermission: () -> Void
    let onPress: (String) -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ShelfToolbar(
                hasAccessibilityPermission: hasAccessibilityPermission,
                onRefresh: onRefresh,
                onRequestPermission: onRequestPermission,
                onQuit: onQuit
            )

            if let error = store.lastScanError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            if !hasAccessibilityPermission {
                PermissionView(onRequestPermission: onRequestPermission)
            } else if store.visibleShelfRecords().isEmpty {
                EmptyShelfView(onRefresh: onRefresh)
            } else {
                List {
                    ForEach(store.visibleShelfRecords()) { record in
                        IconRowView(
                            record: record,
                            onPress: { onPress(record.id) },
                            onPlacementChange: { store.setPlacementMode($0, for: record.id) }
                        )
                    }
                    .onMove(perform: store.move)
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 320, height: 460)
        .background(.regularMaterial)
    }
}

private struct ShelfToolbar: View {
    let hasAccessibilityPermission: Bool
    let onRefresh: () -> Void
    let onRequestPermission: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: StatusIconFactory.statusItemImage(size: 16))
            Text("TuckBar")
                .font(.headline)
            Spacer()
            if !hasAccessibilityPermission {
                Button(action: onRequestPermission) {
                    Image(systemName: "lock.open")
                }
                .help("Open Accessibility permission prompt")
            }
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")
            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .help("Quit")
        }
        .buttonStyle(.borderless)
        .padding(12)
    }
}

private struct PermissionView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "accessibility")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("Accessibility access is needed to read menu-bar items.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Open Settings", action: onRequestPermission)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}

private struct EmptyShelfView: View {
    let onRefresh: () -> Void

    var body: some View {
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
    }
}
