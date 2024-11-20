//
//  DiffView.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI

struct DiffView: View {
    let diff: [DiffChar]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(diff) { char in
                Text(char.char)
                    .font(.system(.body, design: .monospaced))
                    .background(backgroundColor(for: char.type))
            }
        }
    }

    private func backgroundColor(for type: DiffType) -> Color {
        switch type {
        case .normal:
            return .clear
        case .added:
            return .green.opacity(0.3)
        case .deleted:
            return .red.opacity(0.3)
        case .modified:
            return .yellow.opacity(0.3)
        }
    }
}