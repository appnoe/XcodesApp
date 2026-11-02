//
//  PlatformsView.swift
//  Xcodes
//
//  Created by Matt Kiazyk on 2023-12-18.
//

import Foundation
import SwiftUI
import XcodesKit

struct PlatformsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("selectedRuntimeArchitecture") private var selectedVariant: ArchitectureVariant = .defaultForMachine()

    let xcode: Xcode
 
    var body: some View {
        
        let builds = xcode.sdks?.allBuilds
        let availableRuntimes = (builds?.flatMap { sdkBuild in
            appState.downloadableRuntimes.filter {
                $0.sdkBuildUpdate?.contains(sdkBuild) ?? false
            }
        } ?? []).removingReleaseCandidateDisplayDuplicates(installedRuntimes: appState.installedRuntimes)

        let availableVariants = ArchitectureVariant.allCases.filter { variant in
            availableRuntimes.contains { $0.supports(variant) }
        }
        let displayedVariant = availableVariants.count == 1 ? availableVariants.first : selectedVariant
        let runtimes = availableRuntimes.filter { runtime in
            guard !(runtime.architectures?.isEmpty ?? true), let displayedVariant else { return true }
            return runtime.supports(displayedVariant)
        }
        
        if !runtimes.isEmpty {
            Section {
                ForEach(runtimes, id: \.identifier) { runtime in
                    runtimeRow(runtime: runtime)
                }
            } header: {
                HStack {
                    Text("Platforms")
                    Spacer()
                    if availableVariants.count > 1 {
                        Picker("Architecture", selection: $selectedVariant) {
                            ForEach(availableVariants, id: \.self) { arch in
                                Text(variantLabel(for: arch))
                                    .tag(arch)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()
                    }
                }
            }
        }
    }

    private func variantLabel(for variant: ArchitectureVariant) -> String {
        variant == .defaultForMachine() ? "\(variant.displayString) (\(localizeString("This Mac")))" : variant.displayString
    }

    @ViewBuilder
    func runtimeRow(runtime: DownloadableRuntime) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                runtime.icon()
                    .frame(width: 20)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: runtime.visibleIdentifier)
                    if let architectures = runtime.architectures, !architectures.isEmpty {
                        Text(verbatim: architectures.map(\.displayString).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(runtime.downloadFileSizeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                runtimeControl(runtime: runtime)
                    .frame(minWidth: 90, alignment: .trailing)
            }

            if case let .installing(installationStep) = runtime.installState {
                HStack(alignment: .top) {
                    RuntimeInstallationStepDetailView(installationStep: installationStep)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    CancelRuntimeInstallButton(runtime: runtime)
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func runtimeControl(runtime: DownloadableRuntime) -> some View {
        // TODO: Update the downloadableRuntimes with the appropriate installState so we don't have to check path awkwardly
        if let path = appState.runtimeInstallPath(xcode: xcode, runtime: runtime) {
            HStack(spacing: 4) {
                Label("Status.Installed", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    appState.reveal(path: path.string)
                } label: {
                    Label("RevealInFinder", systemImage: "arrow.forward.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("RevealInFinder")
            }
        } else if runtime.installState == .notInstalled {
            DownloadRuntimeButton(runtime: runtime)
                .controlSize(.small)
        }
    }
}

private struct RuntimeDisplayKey: Hashable {
    let platform: DownloadableRuntime.Platform
    let version: String
    let architectures: [String]

    init(_ runtime: DownloadableRuntime) {
        platform = runtime.platform
        version = runtime.completeVersion
        architectures = (runtime.architectures ?? []).map(\.rawValue).sorted()
    }
}

private extension DownloadableRuntime {
    func supports(_ variant: ArchitectureVariant) -> Bool {
        switch variant {
        case .universal:
            return architectures?.isUniversal ?? false
        case .appleSilicon:
            return architectures?.isAppleSilicon ?? false
        }
    }

    var isReleaseCandidate: Bool {
        name.localizedCaseInsensitiveContains("Release Candidate") ||
        identifier.localizedCaseInsensitiveContains("_rc")
    }

    func shouldReplace(_ other: DownloadableRuntime, installedRuntimes: [CoreSimulatorImage]) -> Bool {
        let isInstalled = RuntimeInstallationLookupService()
            .coreSimulatorImage(for: self, in: installedRuntimes) != nil
        let otherIsInstalled = RuntimeInstallationLookupService()
            .coreSimulatorImage(for: other, in: installedRuntimes) != nil

        if isInstalled != otherIsInstalled {
            return isInstalled
        }

        if isReleaseCandidate != other.isReleaseCandidate {
            return !isReleaseCandidate
        }

        return simulatorVersion.buildUpdate.localizedStandardCompare(other.simulatorVersion.buildUpdate) == .orderedDescending
    }
}

private extension Array where Element == DownloadableRuntime {
    func removingReleaseCandidateDisplayDuplicates(installedRuntimes: [CoreSimulatorImage]) -> [DownloadableRuntime] {
        var runtimesByKey: [RuntimeDisplayKey: DownloadableRuntime] = [:]
        var keys: [RuntimeDisplayKey] = []

        for runtime in self {
            let key = RuntimeDisplayKey(runtime)

            guard let existingRuntime = runtimesByKey[key] else {
                runtimesByKey[key] = runtime
                keys.append(key)
                continue
            }

            if runtime.shouldReplace(existingRuntime, installedRuntimes: installedRuntimes) {
                runtimesByKey[key] = runtime
            }
        }

        return keys.compactMap { runtimesByKey[$0] }
    }
}

#Preview(XcodePreviewName.allCases[0].rawValue) { @MainActor in makePreviewContent(for: 0) }

@MainActor
private func makePreviewContent(for index: Int) -> some View {
    let name = XcodePreviewName.allCases[index]
    let runtimes = downloadableRuntimes

    return PlatformsView(xcode: xcodeDict[name]!)
        .environmentObject({ () -> AppState in
            let a = AppState()
            a.allXcodes = [xcodeDict[name]!]
            a.installedRuntimes = installedRuntimes
            a.downloadableRuntimes = runtimes
        
            return a
          
        }())
        .frame(width: 300)
        .padding()
}
