import SwiftUI

struct StatusAlertView: View {
    let header:    String
    let message:   String
    let alertState: String   // "cloudStatus-red", "cloudStatus-yellow", "cloudStatus-green"

    @AppStorage("hideUntilStatusChange") private var hideUntilStatusChange: Bool = true
    var onDismiss: () -> Void

    private var cloudImageName: String {
        switch alertState {
        case "cloudStatus-red":    return "redCloud"
        case "cloudStatus-yellow": return "yellowCloud"
        default:                   return "greenCloud"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(cloudImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                Text(message)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)

            Divider()

            Toggle("Do not redisplay status alert until there is a change",
                   isOn: $hideUntilStatusChange)
                .font(.system(size: 12))
        }
        .padding(16)
        .frame(width: 440)
    }
}

// MARK: - Panel host

final class StatusAlertPanel: NSPanel {

    private var hostingView: NSHostingView<StatusAlertView>?

    init(header: String, message: String, alertState: String) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 180),
            styleMask:   [.titled, .closable, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )

        self.title                  = header
        self.level                  = .floating
        self.isFloatingPanel        = true
        self.hidesOnDeactivate      = false
        self.becomesKeyOnlyIfNeeded = true
        self.collectionBehavior     = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = StatusAlertView(header: header, message: message, alertState: alertState) {
            self.orderOut(nil)
        }
        let hosting = NSHostingView(rootView: view)
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
        self.hostingView = hosting
        self.setContentSize(hosting.fittingSize)
    }

    func showOnActiveScreen() {
        if let screen = NSScreen.main {
            let sw = screen.frame.width
            let sh = screen.frame.height
            let ox = screen.frame.origin.x
            let oy = screen.frame.origin.y
            let x  = ox + sw - frame.width - 20
            let y  = oy + sh - frame.height - 40
            setFrameOrigin(NSPoint(x: x, y: y))
        }
        orderFrontRegardless()
    }
}
