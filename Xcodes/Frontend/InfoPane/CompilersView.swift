//
//  CompilersView.swift
//  Xcodes
//
//  Created by Duong Thai on 13/10/2023.
//  Copyright © 2023 Robots and Pencils. All rights reserved.
//

import SwiftUI
import XcodesKit

struct CompilersView: View {
    let compilers: Compilers?

    var body: some View {
        if let compilers = compilers {
            let rows = Self.rows(from: compilers)
            if !rows.isEmpty {
                Section("Compilers") {
                    ForEach(rows, id: \.name) { row in
                        LabeledContent(row.name) {
                            Text(verbatim: row.versions)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    static func rows(from compilers: Compilers) -> [(name: String, versions: String)] {
        [
            ("Swift", compilers.swift),
            ("Clang", compilers.clang),
            ("LLVM", compilers.llvm),
            ("LLVM GCC", compilers.llvm_gcc),
            ("GCC", compilers.gcc)
        ].compactMap { name, versions in
            let numbers = (versions ?? []).compactMap(\.number)
            guard !numbers.isEmpty else { return nil }
            return (name, numbers.joined(separator: ", "))
        }
    }
}

#Preview {
  let compilers = Compilers(
    gcc: .init(number: "4"),
    llvm_gcc: .init(number: "213"),
    llvm: .init(number: "2.3"),
    clang: .init(number: "7.3"),
    swift: .init(number: "5.3.2")
  )

  return Form { CompilersView(compilers: compilers) }
    .formStyle(.grouped)
}
