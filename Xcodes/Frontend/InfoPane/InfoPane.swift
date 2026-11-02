import AppKit
import XcodesKit
import Path
import SwiftUI
import Version

struct InfoPane: View {
    @EnvironmentObject var appState: AppState
    let xcode: Xcode

    var body: some View {
        Form {
            Section {
                header
            }

            if case let .installing(installationStep) = xcode.installState {
                Section("Status.Installing") {
                    InstallationStepDetailView(installationStep: installationStep)
                    HStack {
                        Spacer()
                        CancelInstallButton(xcode: xcode)
                    }
                }
            }

            Section("General") {
                generalRows
            }

            PlatformsView(xcode: xcode)
            IdenticalBuildsView(builds: xcode.identicalBuildsForCurrentVariant)
            SDKsView(sdks: xcode.sdks)
            CompilersView(compilers: xcode.compilers)
        }
        .formStyle(.grouped)
    }

    private var header: some View {
        HStack(spacing: 16) {
            XcodeAppIcon(xcode: xcode, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "Xcode \(xcode.description)")
                    .font(.title)
                    .fontWeight(.semibold)
                    .textSelection(.enabled)

                if !xcode.version.buildMetadataIdentifiers.isEmpty {
                    Text(verbatim: xcode.version.buildMetadataIdentifiers.joined(separator: " "))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .accessibilityLabel(Text("Build \(xcode.version.buildMetadataIdentifiers.joined(separator: " "))"))
                }

                XcodeStatusLabel(xcode: xcode)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var generalRows: some View {
        if let path = xcode.installedPath {
            LabeledContent("Location") {
                HStack(spacing: 6) {
                    Text(verbatim: path.string)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    Button {
                        appState.reveal(path)
                    } label: {
                        Label("RevealInFinder", systemImage: "arrow.forward.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .help("RevealInFinder")
                }
            }
        }

        if let releaseDate = xcode.releaseDate {
            LabeledContent("ReleaseDate") {
                Text(releaseDate, style: .date)
            }
        }

        if let url = xcode.releaseNotesURL {
            LabeledContent("ReleaseNotes") {
                Link(destination: url) {
                    Label("ReleaseNotes.help", systemImage: "arrow.up.forward.square")
                        .labelStyle(.titleAndIcon)
                }
                .contextMenu {
                    CopyReleaseNoteButton(url: url)
                }
            }
        }

        if let requiredMacOSVersion = xcode.requiredMacOSVersion {
            LabeledContent("Compatibility") {
                let requirement = String(format: localizeString("MacOSRequirement"), requiredMacOSVersion)
                // hasMinSupportedOS returns true when this Mac does NOT meet the requirement.
                if appState.hasMinSupportedOS(requiredMacOSVersion: requiredMacOSVersion) {
                    Label(requirement, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .help("Compatibility.Unsupported")
                } else {
                    Text(requirement)
                }
            }
        }

        if let architectures = xcode.architectures, !architectures.isEmpty {
            LabeledContent("Architecture") {
                Text(architectures.isAppleSilicon ? "Apple Silicon" : "Universal")
            }
        }

        if xcode.installState == .notInstalled, let size = xcode.downloadFileSizeString {
            LabeledContent("DownloadSize", value: size)
        }
    }
}

#Preview(XcodePreviewName.allCases[0].rawValue) { makePreviewContent(for: 0) }
#Preview(XcodePreviewName.allCases[1].rawValue) { makePreviewContent(for: 1) }
#Preview(XcodePreviewName.allCases[2].rawValue) { makePreviewContent(for: 2) }
#Preview(XcodePreviewName.allCases[3].rawValue) { makePreviewContent(for: 3) }
#Preview(XcodePreviewName.allCases[4].rawValue) { makePreviewContent(for: 4) }
#Preview(XcodePreviewName.allCases[5].rawValue) { makePreviewContent(for: 5) }

@MainActor
private func makePreviewContent(for index: Int) -> some View {
    let name = XcodePreviewName.allCases[index]
    return InfoPane(xcode: xcodeDict[name]!)
        .environmentObject(configure(AppState()) {
            $0.allXcodes = [xcodeDict[name]!]
        })
        .frame(width: 520, height: 600)
}

enum XcodePreviewName: String, CaseIterable, Identifiable {
    case Populated_Installed_Selected
    case Populated_Installed_Unselected
    case Populated_Uninstalled
    case Basic_Installed
    case Basic_Installing
    case Basic_Unarchiving
    
    var id: XcodePreviewName { self }
}

@MainActor
let xcodeDict: [XcodePreviewName: Xcode] = [
    .Populated_Installed_Selected: .init(
        version: _versionNoMeta,
        installState: .installed(Path(_path)!),
        selected: true,
        icon: NSWorkspace.shared.icon(forFile: _path),
        requiredMacOSVersion: _requiredMacOSVersion,
        releaseNotesURL: URL(string: "https://developer.apple.com/documentation/xcode-release-notes/xcode-12_3-release-notes/")!,
        releaseDate: Date(),
        sdks: _sdks,
        compilers: _compilers,
        downloadFileSize: _downloadFileSize
    ),
    .Populated_Installed_Unselected: .init(
        version: _versionNoMeta,
        installState: .installed(Path(_path)!),
        selected: false,
        icon: NSWorkspace.shared.icon(forFile: _path),
        sdks: _sdks,
        compilers: _compilers,
        downloadFileSize: _downloadFileSize
    ),
    .Populated_Uninstalled: .init(
        version: Version(major: 12, minor: 3, patch: 0),
        installState: .notInstalled,
        selected: false,
        icon: nil,
        sdks: _sdks,
        compilers: _compilers,
        downloadFileSize: _downloadFileSize
    ),
    .Basic_Installed: .init(
        version: _versionWithMeta,
        installState: .installed(Path(_path)!),
        selected: false,
        icon: nil,
        sdks: nil,
        compilers: nil
    ),
    .Basic_Installing: .init(
        version: _versionWithMeta,
        installState: .installing(.downloading(
            progress: configure(Progress()) {
                $0.kind = .file
                $0.fileOperationKind = .downloading
                $0.estimatedTimeRemaining = 123
                $0.totalUnitCount = 11_944_848_484
                $0.completedUnitCount = 848_444_920
                $0.throughput = 9_211_681
            }
        )),
        selected: false,
        icon: nil,
        sdks: nil,
        compilers: nil
    ),
    .Basic_Unarchiving: .init(
        version: _versionWithMeta,
        installState: .installing(.unarchiving),
        selected: false,
        icon: nil,
        sdks: nil,
        compilers: nil
    ),
]

@MainActor
let downloadableRuntimes: [DownloadableRuntime] = {
    var runtimes = try! JSONDecoder().decode([DownloadableRuntime].self, from: Current.files.contents(atPath: Path.runtimeCacheFile.string)!)
    // set iOS to installed
    let iOSIndex = 0//runtimes.firstIndex { $0.sdkBuildUpdate.contains == "19E239" }!
    var iOSRuntime = runtimes[iOSIndex]
    iOSRuntime.installState = .installed
    runtimes[iOSIndex] = iOSRuntime
    
    let watchOSIndex = 0//runtimes.firstIndex { $0.sdkBuildUpdate.first == "20R362" }!
    var runtime = runtimes[watchOSIndex]
    runtime.installState = .installing(
        RuntimeInstallationStep.downloading(
            progress:configure(Progress()) {
                $0.kind = .file
                $0.fileOperationKind = .downloading
                $0.estimatedTimeRemaining = 123
                $0.totalUnitCount = 11_944_848_484
                $0.completedUnitCount = 848_444_920
                $0.throughput = 9_211_681
            }
        )
    )
    runtimes[watchOSIndex] = runtime
    
    return runtimes
}()

@MainActor
let installedRuntimes: [CoreSimulatorImage] = {
    [CoreSimulatorImage(uuid: "85B22F5B-048B-4331-B6E2-F4196D8B7475", path: ["relative" : "file:///Library/Developer/CoreSimulator/Images/85B22F5B-048B-4331-B6E2-F4196D8B7475.dmg"], runtimeInfo: CoreSimulatorRuntimeInfo(build: "19E240")),
     CoreSimulatorImage(uuid: "85B22F5B-048B-4331-B6E2-F4196D8B7473", path: ["relative" : "file:///Library/Developer/CoreSimulator/Images/85B22F5B-048B-4331-B6E2-F4196D8B7475.dmg"], runtimeInfo: CoreSimulatorRuntimeInfo(build: "21N5233f"))]
}()


@MainActor
private let _versionNoMeta = Version(major: 12, minor: 3, patch: 0)
@MainActor
private let _versionWithMeta = Version(major: 12, minor: 3, patch: 1, buildMetadataIdentifiers: ["1234A"])
private let _path = "/Applications/Xcode-12.3.0.app"
private let _requiredMacOSVersion = "10.15.4"
private let _sdks = SDKs(
    macOS: .init(number: "11.1"),
    iOS: .init(number: "15.4", "19E239"),
    watchOS: .init(number: "7.3", "20R362"),
    tvOS: .init(number: "14.3", "20K67"),
    visionOS: .init(number: "1.0", "21N5233e")
)
private let _compilers = Compilers(
    gcc: .init(number: "4"),
    llvm_gcc: .init(number: "213"),
    llvm: .init(number: "2.3"),
    clang: .init(number: "7.3"),
    swift: .init(number: "5.3.2")
)
private let _downloadFileSize: Int64 = 242_342_424
