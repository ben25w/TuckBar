import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: IconRegistryStore

    var body: some View {
        Form {
            Section("Items") {
                ForEach(store.records) { record in
                    HStack {
                        Text(record.displayName)
                        Spacer()
                        Text(record.placementMode.label)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(width: 420)
    }
}
