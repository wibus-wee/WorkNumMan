//
//  EditStudentSheet.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI

struct EditStudentSheet: View {
    let student: Student
    @Binding var studentList: StudentList
    @Binding var isPresented: Bool
    
    @State private var studentId: String
    @State private var name: String
    @State private var roomId: String
    @State private var phone: String
    
    init(student: Student, studentList: Binding<StudentList>, isPresented: Binding<Bool>) {
        self._studentList = studentList
        self._isPresented = isPresented
        self.student = student
        self._studentId = State(initialValue: student.studentId)
        self._name = State(initialValue: student.name)
        self._roomId = State(initialValue: student.roomId)
        self._phone = State(initialValue: student.phone)
    }
    
    var body: some View {
        VStack {
            Text("编辑学生信息")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("学号", text: $studentId)
                .textFieldStyle(.roundedBorder)
                .frame(height: 30)
            
            TextField("姓名", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(height: 30)
            
            TextField("宿舍", text: $roomId)
                .textFieldStyle(.roundedBorder)
                .frame(height: 30)
            
            TextField("电话", text: $phone)
                .textFieldStyle(.roundedBorder)
                .frame(height: 30)
            
            HStack {
                Button("保存") {
                    if let index = studentList.students.firstIndex(where: { $0.id == student.id }) {
                        studentList.students.remove(at: index)
                        let updatedStudent = Student(
                            id: student.id,
                            studentId: studentId,
                            name: name,
                            roomId: roomId,
                            phone: phone
                        )
                        studentList.students.insert(updatedStudent, at: index)
                        
                        saveStudents(list: studentList)
                    }
                    isPresented = false
                }
                
                Button("取消") {
                    isPresented = false
                }
            }
            .padding()
        }
        .padding()
    }
}