//
//  CommonFormat.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI

struct CommonFormat: View {
    @State var hovering: Bool = false
    @Binding var checkFormat: String
    var format: String
    var body: some View {
        Text(format)
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
                checkFormat = format
            }
    }
}
