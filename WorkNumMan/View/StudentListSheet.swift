//
//  StudentListSheet.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//


import SwiftUI

struct StudentListSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var studentList: StudentList = loadStudents()
    @State private var editingStudent: Student? = nil
    @State private var showEditSheet = false
    
    var body: some View {
        VStack {
            Text("学生列表")
                .font(.title2)
                .fontWeight(.bold)
            
            List(studentList.students) { student in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(student.studentId)
                                .foregroundColor(.secondary)
                            Text(student.name)
                                .fontWeight(.medium)
                        }
                        Text("宿舍: \(student.roomId) | 电话: \(student.phone)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("编辑") {
                        editingStudent = student
                        showEditSheet = true
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let student = editingStudent {
                EditStudentSheet(
                    student: student,
                    studentList: $studentList,
                    isPresented: $showEditSheet
                )
            }
        }
        .padding()
    }
}