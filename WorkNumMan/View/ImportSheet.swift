//
//  ImportSheet.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI


struct ImportSheet: View {
    @State var studentList: String = ""
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Text("导入学生")
                .font(.title2)
                .fontWeight(.bold)

            TextEditor(text: $studentList)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .padding()

            HStack {
                Button("导入") {
                    let studentList = importStudents(list: studentList)
                    let alert = NSAlert()
                    alert.messageText = "已导入 \(studentList.students.count) 名学生"
                    alert.runModal()

                    saveStudents(list: studentList)
                    dismiss()
                }

                Button("取消") {
                    dismiss()
                }

                Spacer()

                Button("重置") {
                    studentList = ""
                    resetStudents()
                }
            }
            .padding()
        }
        .padding()
    }
}
