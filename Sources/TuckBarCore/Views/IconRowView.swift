import SwiftUI

struct IconRowView: View {
    let record: MenuBarItemRecord
    let onPress: () -> Void
    let onPlacementChange: (PlacementMode) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPress) {
                HStack(spacing: 10) {
                    Image(systemName: record.isAvailable ? "app.badge" : "app.dashed")
                        .frame(width: 18, height: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.displayName)
                            .font(.body)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(!record.isAvailable)

            Picker("", selection: Binding(
                get: { record.placementMode },
                set: onPlacementChange
            )) {
                ForEach(PlacementMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .frame(width: 78)
        }
        .padding(.vertical, 6)
        .opacity(record.isAvailable ? 1.0 : 0.45)
    }

    private var subtitle: String {
        var parts = [record.processName]
        if record.hideSupportStatus == .virtualOnlyUnsupported, record.placementMode == .virtualMenu {
            parts.append("real icon remains visible")
        }
        return parts.joined(separator: " - ")
    }
}
