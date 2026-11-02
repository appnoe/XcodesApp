import Path
import SwiftUI
import Version
import XcodesKit

struct XcodeListViewRow: View {
    let xcode: Xcode
    let latestReleaseForSelectedPrerelease: Xcode?

    init(xcode: Xcode, latestReleaseForSelectedPrerelease: Xcode? = nil) {
        self.xcode = xcode
        self.latestReleaseForSelectedPrerelease = latestReleaseForSelectedPrerelease
    }

    var body: some View {
        HStack(spacing: 10) {
            XcodeAppIcon(xcode: xcode, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Xcode \(xcode.description)")
                    .lineLimit(1)

                if case let .installing(installationStep) = xcode.installState {
                    InstallationStepRowView(installationStep: installationStep)
                } else {
                    Text(verbatim: subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if !xcode.identicalBuildsForCurrentVariant.isEmpty {
                Image(systemName: "square.on.square")
                    .foregroundStyle(.secondary)
                    .help("IdenticalBuilds.help")
                    .accessibilityLabel(Text("IdenticalBuilds"))
            }

            activeIndicator
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let build = xcode.version.buildMetadataIdentifiers.joined(separator: " ")
        return [build, XcodeStatus(xcode).text].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    @ViewBuilder
    private var activeIndicator: some View {
        if xcode.selected, let latestReleaseForSelectedPrerelease {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .help(staleSelectedHelpText(latestRelease: latestReleaseForSelectedPrerelease))
                .accessibilityLabel(staleSelectedHelpText(latestRelease: latestReleaseForSelectedPrerelease))
        } else if xcode.selected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
                .help("ActiveVersionDescription")
                .accessibilityHidden(true)
        }
    }

    private func staleSelectedHelpText(latestRelease: Xcode) -> Text {
        Text(String(format: localizeString("StaleSelection.Help"), xcode.description, latestRelease.description))
    }
}

/// The app icon of an Xcode; uninstalled versions show a dimmed placeholder.
struct XcodeAppIcon: View {
    let xcode: Xcode
    let size: CGFloat

    var body: some View {
        Group {
            if let path = xcode.installedPath {
                Image(nsImage: xcode.icon ?? NSWorkspace.shared.icon(forFile: path.string))
                    .resizable()
            } else {
                Image(xcode.version.isPrerelease ? "xcode-beta" : "xcode")
                    .resizable()
                    .opacity(0.35)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Human-readable install state, always expressed as text plus symbol rather than color alone.
struct XcodeStatus {
    let text: String
    let systemImage: String
    let isActive: Bool

    init(_ xcode: Xcode) {
        switch xcode.installState {
        case .installed where xcode.selected:
            text = localizeString("Active")
            systemImage = "checkmark.circle.fill"
            isActive = true
        case .installed:
            text = localizeString("Status.Installed")
            systemImage = "checkmark.circle"
            isActive = false
        case .notInstalled:
            text = localizeString("Status.NotInstalled")
            systemImage = "arrow.down.circle"
            isActive = false
        case .installing:
            text = localizeString("Status.Installing")
            systemImage = "arrow.down.circle.dotted"
            isActive = false
        case .uninstalling:
            text = localizeString("Uninstalling")
            systemImage = "trash"
            isActive = false
        }
    }
}

struct XcodeStatusLabel: View {
    let xcode: Xcode

    var body: some View {
        let status = XcodeStatus(xcode)
        Label(status.text, systemImage: status.systemImage)
            .foregroundStyle(status.isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
    }
}

struct XcodeListViewRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            XcodeListViewRow(
                xcode: Xcode(version: Version("12.3.0")!, installState: .installed(Path("/Applications/Xcode-12.3.0.app")!), selected: true, icon: nil),
            )

            XcodeListViewRow(
                xcode: Xcode(version: Version("12.2.0")!, installState: .notInstalled, selected: false, icon: nil),
            )

            XcodeListViewRow(
                xcode: Xcode(version: Version("12.1.0")!, installState: .installing(.downloading(progress: configure(Progress(totalUnitCount: 100)) { $0.completedUnitCount = 40 })), selected: false, icon: nil),
            )

            XcodeListViewRow(
                xcode: Xcode(version: Version("12.0.0")!, installState: .installed(Path("/Applications/Xcode-12.3.0.app")!), selected: false, icon: nil),
            )

            XcodeListViewRow(
                xcode: Xcode(version: Version("12.0.0+1234A")!, installState: .installed(Path("/Applications/Xcode-12.3.0.app")!), selected: false, icon: nil),
            )

            XcodeListViewRow(
                xcode: Xcode(version: Version("12.0.0+1234A")!, identicalBuilds: [XcodeID(version: Version("12.0.0-RC+1234A")!)], installState: .installed(Path("/Applications/Xcode-12.3.0.app")!), selected: false, icon: nil),
            )
        }
    }
}
