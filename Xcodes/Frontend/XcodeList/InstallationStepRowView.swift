import SwiftUI
import XcodesKit

/// Compact installation progress shown in place of the status line of a list row.
struct InstallationStepRowView: View {
    let installationStep: XcodeInstallationStep

    var body: some View {
        HStack(spacing: 6) {
            switch installationStep {
            case let .downloading(progress):
                // FB8955769 ProgressView.init(_: Progress) doesn't ensure that changes from the Progress object are applied to the UI on the main thread
                // This Progress is vended by URLSession so I don't think we can control that.
                // Use our own version of ProgressView that does this instead.
                ObservingProgressIndicator(
                    progress,
                    controlSize: .small,
                    style: .bar
                )
                .frame(maxWidth: 120)
            case .authenticating, .unarchiving, .moving, .trashingArchive, .checkingSecurity, .finishing:
                ProgressView()
                    .controlSize(.small)
            }

            Text(installationStep.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(format: localizeString("InstallationStepDescription"), installationStep.stepNumber, installationStep.stepCount, installationStep.message)))
    }
}

#Preview("Downloading") {
    InstallationStepRowView(
        installationStep: .downloading(
            progress: configure(Progress(totalUnitCount: 100)) { $0.completedUnitCount = 40 }
        )
    )
    .padding()
}

#Preview("Unarchiving") {
    InstallationStepRowView(installationStep: .unarchiving)
        .padding()
}
