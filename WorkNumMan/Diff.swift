//
//  Diff.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import Foundation

struct DiffChar: Identifiable {
    let id = UUID()
    let char: String
    let isDifferent: Bool
    let type: DiffType // 新增、删除或修改
}

enum DiffType {
    case normal
    case added
    case deleted
    case modified
}

func calculateDiff(expected: String, actual: String) -> [DiffChar] {
    var diff: [DiffChar] = []
    let expectedChars = Array(expected)
    let actualChars = Array(actual)

    let maxLength = max(expectedChars.count, actualChars.count)
    for i in 0 ..< maxLength {
        if i < expectedChars.count, i < actualChars.count {
            if expectedChars[i] != actualChars[i] {
                diff.append(DiffChar(char: String(actualChars[i]), isDifferent: true, type: .modified))
            } else {
                diff.append(DiffChar(char: String(actualChars[i]), isDifferent: false, type: .normal))
            }
        } else if i < actualChars.count {
            diff.append(DiffChar(char: String(actualChars[i]), isDifferent: true, type: .added))
        } else {
            diff.append(DiffChar(char: String(expectedChars[i]), isDifferent: true, type: .deleted))
        }
    }
    return diff
}