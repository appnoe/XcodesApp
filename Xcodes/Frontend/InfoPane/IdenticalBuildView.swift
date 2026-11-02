//
//  IdenticalBuildView.swift
//  Xcodes
//
//  Created by Duong Thai on 11/10/2023.
//  Copyright © 2023 Robots and Pencils. All rights reserved.
//

import SwiftUI
import Version
import XcodesKit

struct IdenticalBuildsView: View {
    let builds: [XcodeID]
    private let isEmpty: Bool
    private let accessibilityDescription: String

    var body: some View {
        if !isEmpty {
            Section {
                ForEach(builds) { build in
                    Text(verbatim: build.version.appleDescription)
                        .textSelection(.enabled)
                }
            } header: {
                Text("IdenticalBuilds")
            } footer: {
                Text("IdenticalBuilds.help")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibility(label: Text("IdenticalBuilds"))
            .accessibility(value: Text(accessibilityDescription))
        }
    }

    init(builds: [XcodeID]) {
        self.builds = builds
        self.isEmpty = builds.isEmpty
        self.accessibilityDescription = builds
            .map(\.version.appleDescription)
            .joined(separator: ", ")
    }
}

@MainActor
private let previewBuilds: [XcodeID] = [
    .init(version: .init(xcodeVersion: "15.0")!),
    .init(version: .init(xcodeVersion: "15.1")!)
]

#Preview("Has Some Builds") {
  Form { IdenticalBuildsView(builds: previewBuilds) }
    .formStyle(.grouped)
}

#Preview("No Build") {
  IdenticalBuildsView(builds: [])
    .padding()
}
