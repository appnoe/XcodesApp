import Foundation
import SwiftUI
import XcodesKit

enum XcodeListCategory: String, CaseIterable, Identifiable, CustomStringConvertible {
    case all
    case release
    case beta
    
    var id: Self { self }
    
    var description: String {
        switch self {
            case .all: return localizeString("All")
            case .release: return localizeString("Release")
            case .beta: return localizeString("Beta")
        }
    }

    var isManaged: Bool { PreferenceKey.xcodeListCategory.isManaged() }

    var versionFilter: XcodeListVersionFilter {
        switch self {
        case .all:
            return .all
        case .release:
            return .release
        case .beta:
            return .prerelease
        }
    }
}

enum XcodeListArchitecture: String, CaseIterable, Identifiable, CustomStringConvertible {
    case universal
    case appleSilicon
    
    var id: Self { self }

    static var defaultForCurrentMachine: Self {
        switch ArchitectureVariant.defaultForMachine() {
        case .universal:
            return .universal
        case .appleSilicon:
            return .appleSilicon
        }
    }
    
    var description: String {
        switch self {
            case .universal: return localizeString("Universal")
            case .appleSilicon: return localizeString("Apple Silicon")
        }
    }

    var menuDescription: String {
        isCurrentMachineDefault ? "\(description) (\(localizeString("This Mac")))" : description
    }
    
    var isCurrentMachineDefault: Bool {
        self == Self.defaultForCurrentMachine
    }
    
    var isManaged: Bool { PreferenceKey.xcodeListArchitectures.isManaged() }

    var architectureFilters: [ArchitectureFilter] {
        switch self {
        case .universal:
            return [.variant(.universal)]
        case .appleSilicon:
            return [.variant(.appleSilicon)]
        }
    }
}

/// The navigation destinations shown in the sidebar of the main window.
/// Maps onto the persisted category and "installed only" preferences.
enum LibraryScope: String, CaseIterable, Identifiable {
    case all
    case release
    case beta
    case installed

    var id: Self { self }

    init(category: XcodeListCategory, isInstalledOnly: Bool) {
        if isInstalledOnly {
            self = .installed
            return
        }
        switch category {
        case .all: self = .all
        case .release: self = .release
        case .beta: self = .beta
        }
    }

    var category: XcodeListCategory {
        switch self {
        case .all, .installed: return .all
        case .release: return .release
        case .beta: return .beta
        }
    }

    var isInstalledOnly: Bool { self == .installed }

    var title: LocalizedStringKey {
        switch self {
        case .all: return "Scope.All"
        case .release: return "Scope.Releases"
        case .beta: return "Scope.Betas"
        case .installed: return "Scope.Installed"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "square.stack.3d.up"
        case .release: return "shippingbox"
        case .beta: return "testtube.2"
        case .installed: return "internaldrive"
        }
    }
}
