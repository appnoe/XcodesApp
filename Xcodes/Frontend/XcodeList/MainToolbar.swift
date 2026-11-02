import SwiftUI
import XcodesKit

/// Toolbar of the version list column: refreshing and filtering the list.
struct MainToolbarModifier: ViewModifier {
    @EnvironmentObject var appState: AppState
    @Binding var architectures: XcodeListArchitecture

    func body(content: Content) -> some View {
        content
            .toolbar { toolbar }
    }

    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            ProgressButton(
                isInProgress: appState.isUpdating,
                action: appState.update
            ) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("RefreshDescription")

            Menu {
                Picker("Architecture", selection: $architectures) {
                    ForEach(XcodeListArchitecture.allCases) { architecture in
                        Text(architecture.menuDescription)
                            .tag(architecture)
                    }
                }
                .pickerStyle(.inline)
                .disabled(architectures.isManaged)
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
            .symbolVariant(architectures.isCurrentMachineDefault ? .none : .fill)
            .help("FilterArchitecturesDescription")
        }
    }
}

/// Toolbar of the detail column: the most common actions for the selected Xcode, plus the account.
struct DetailToolbarModifier: ViewModifier {
    @EnvironmentObject var appState: AppState
    let xcode: Xcode?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if let xcode {
                        actions(for: xcode)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    accountButton
                }
            }
    }

    @ViewBuilder
    private func actions(for xcode: Xcode) -> some View {
        switch xcode.installState {
        case .notInstalled:
            Button {
                appState.checkMinVersionAndInstall(id: xcode.id)
            } label: {
                Label("Install", systemImage: "arrow.down.circle")
            }
            .help("InstallDescription")
        case .installing:
            Button {
                appState.presentedAlert = .cancelInstall(xcode: xcode)
            } label: {
                Label("StopInstallation", systemImage: "xmark.circle")
            }
            .help("StopInstallation")
        case .installed:
            openButton(for: xcode)

            Button {
                appState.select(xcode: xcode)
            } label: {
                Label("MakeActive", systemImage: "checkmark.circle")
            }
            .disabled(xcode.selected)
            .help("MakeActiveVersionDescription")

            Menu {
                XcodeActionsMenu(xcode: xcode, includesPrimaryActions: false)
            } label: {
                Label("MoreActions", systemImage: "ellipsis.circle")
            }
            .help("MoreActions")
        case .uninstalling:
            EmptyView()
        }
    }

    @ViewBuilder
    private func openButton(for xcode: Xcode) -> some View {
        if appState.showOpenInRosettaOption && HostHardware.isAppleSilicon() {
            Menu {
                Button("Open") { appState.open(xcode: xcode) }
                Button("Open In Rosetta") { appState.open(xcode: xcode, openInRosetta: true) }
            } label: {
                Label("Open", systemImage: "hammer")
            } primaryAction: {
                appState.open(xcode: xcode)
            }
            .help("OpenDescription")
        } else {
            Button {
                appState.open(xcode: xcode)
            } label: {
                Label("Open", systemImage: "hammer")
            }
            .help("OpenDescription")
        }
    }

    private var accountButton: some View {
        Button {
            appState.presentedSheet = .signIn
        } label: {
            Label {
                if let authenticatedUserName {
                    Text(verbatim: authenticatedUserName)
                } else {
                    Text("Login")
                }
            } icon: {
                Image(systemName: "person.crop.circle")
            }
        }
        .help("LoginDescription")
    }

    private var authenticatedUserName: String? {
        guard case let .authenticated(appleSession) = appState.authenticationState else {
            return nil
        }
        return appleSession.user.fullName ?? appState.savedUsername
    }
}

extension View {
    func mainToolbar(architecture: Binding<XcodeListArchitecture>) -> some View {
        modifier(MainToolbarModifier(architectures: architecture))
    }

    func detailToolbar(xcode: Xcode?) -> some View {
        modifier(DetailToolbarModifier(xcode: xcode))
    }
}
