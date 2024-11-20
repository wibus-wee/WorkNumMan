//
//  CheckResultItem.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import Foundation

struct CheckResultItem: Identifiable {
    let id = UUID()
    let name: String
    let result: StudentCheckResult
}
