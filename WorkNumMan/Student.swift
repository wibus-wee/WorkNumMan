//
//  Student.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import Foundation

struct Student: Identifiable, Codable {
    var id: UUID = .init()
    var studentId: String
    var name: String
    var roomId: String
    var phone: String
}

struct StudentList: Codable {
    var students: [Student] = []
}