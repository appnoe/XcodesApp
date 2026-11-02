//
//  SDKsView.swift
//  Xcodes
//
//  Created by Duong Thai on 13/10/2023.
//  Copyright © 2023 Robots and Pencils. All rights reserved.
//

import SwiftUI
import XcodesKit

struct SDKsView: View {
    let rows: [(name: String, versions: String)]

    var body: some View {
        if !rows.isEmpty {
            Section("SDKs") {
                ForEach(rows, id: \.name) { row in
                    LabeledContent(row.name) {
                        Text(verbatim: row.versions)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    init(sdks: SDKs?) {
        guard let sdks = sdks else {
            self.rows = []
            return
        }
        self.rows = Self.rows(from: sdks)
    }

    static func rows(from sdks: SDKs) -> [(name: String, versions: String)] {
        [
            ("macOS", sdks.macOS),
            ("iOS", sdks.iOS),
            ("watchOS", sdks.watchOS),
            ("tvOS", sdks.tvOS),
            ("visionOS", sdks.visionOS)
        ].compactMap { name, versions in
            let numbers = (versions ?? []).compactMap(\.number)
            guard !numbers.isEmpty else { return nil }
            return (name, numbers.joined(separator: ", "))
        }
    }
}

#Preview {
  let sdks = SDKs(
    macOS: .init(number: "11.1"),
    iOS: .init(number: "14.3"),
    watchOS: .init(number: "7.3"),
    tvOS: .init(number: "14.3"))

  return Form { SDKsView(sdks: sdks) }
    .formStyle(.grouped)
}
