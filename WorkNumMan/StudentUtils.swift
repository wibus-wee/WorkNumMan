//
//  StudentUtils.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import Foundation


func importStudents(list: String) -> StudentList {
    var studentList = StudentList()
    let preList = list.split(separator: "\n")
    var nowRoomId = ""
    for item in preList {
        if item.starts(with: "4") {
            nowRoomId = String(item)
        } else {
            let student = Student(
                studentId: String(item.split(separator: ",")[0]),
                name: String(item.split(separator: ",")[1]),
                roomId: nowRoomId,
                phone: String(item.split(separator: ",")[2])
            )
            // For example: StudentID,Name,Phone
            studentList.students.append(student)
        }
    }
    print("[*] Loaded \(studentList.students.count) students")
    return studentList
}

func saveStudents(list: StudentList) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(list) {
        defaults.set(encoded, forKey: "studentList")
    }
}

func loadStudents() -> StudentList {
    let defaults = UserDefaults.standard
    let decoder = JSONDecoder()
    if let savedStudentList = defaults.object(forKey: "studentList") as? Data {
        if let loadedStudentList = try? decoder.decode(StudentList.self, from: savedStudentList) {
            return loadedStudentList
        }
    }
    return StudentList()
}

func resetStudents() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "studentList")
}