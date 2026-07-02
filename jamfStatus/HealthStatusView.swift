import SwiftUI

struct HealthStatusView: View {
    @ObservedObject private var store = HealthStatusStore.shared

    private let timeLabels = ["30s", "1m", "5m", "15m", "30m"]

    var body: some View {
        Group {
            if let hs = store.healthStatus {
                VStack(spacing: 0) {
                    Text("Request Acceptance Percent")
                        .font(.headline)
                        .padding(.bottom, 8)
                    headerRow
                    Divider()
                    dataRow(label: "API",        api: hs.api)
                    dataRow(label: "UI",         api: hs.ui)
                    dataRow(label: "Enrollment", api: hs.enrollment)
                    dataRow(label: "Device",     api: hs.device)
                    dataRow(label: "Default",    api: hs.healthStatusDefault)
                }
                .padding()
            } else {
                Text("No health status data yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 480)
        .onAppear { NSApp.activate(ignoringOtherApps: true) }
    }

    private var headerRow: some View {
        HStack {
            Text("").frame(width: 90, alignment: .leading)
            ForEach(timeLabels, id: \.self) { label in
                Text(label)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
        }
        .padding(.bottom, 4)
    }

    private func dataRow(label: String, api: API) -> some View {
        let values = [api.thirtySeconds, api.oneMinute, api.fiveMinutes, api.fifteenMinutes, api.thirtyMinutes]
        return HStack {
            Text(label)
                .frame(width: 90, alignment: .leading)
                .fontWeight(.medium)
            ForEach(0..<values.count, id: \.self) { i in
                let value = values[i]
                Text("\(Int(value * 100))%")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(value < 1.0 ? Color.red : Color.primary)
            }
        }
        .padding(.vertical, 3)
    }
}
