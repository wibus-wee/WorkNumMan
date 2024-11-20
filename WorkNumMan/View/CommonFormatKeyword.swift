//
//  CommonFormatKeyword.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI

struct CommonFormatKeyword: View {
    @State var hovering: Bool = false
    @Binding var checkFormat: String
    let keyword: String
    var body: some View {
        Text(keyword)
            .font(.caption)
            .padding(8)
            .background(Color.gray.opacity(hovering ? 0.2 : 0.1))
            .cornerRadius(8)
            .onHover { hovering in
                withAnimation {
                    self.hovering = hovering
                }
            }
            .onTapGesture {
                checkFormat = "\(checkFormat)\(keyword)"
            }
    }
}