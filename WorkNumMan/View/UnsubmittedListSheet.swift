//
//  UnsubmittedListSheet.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI

struct UnsubmittedListSheet: View {
    let checkResult: [String: StudentCheckResult]
    @Environment(\.dismiss) var dismiss
    
    var unsubmittedStudents: [(String, StudentCheckResult)] {
        checkResult.filter { !$0.value.isSubmitted }
            .sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack {
            Text("未提交名单")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Text("共 \(unsubmittedStudents.count) 人未提交")
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            List(unsubmittedStudents, id: \.0) { name, result in
                Text(name)
            }

            Divider()

            TextEditor(text: .constant(unsubmittedStudents.map { "\($0.0)," }.joined()))
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
            
            Button("关闭") {
                dismiss()
            }
            .padding()
        }
    }
}


