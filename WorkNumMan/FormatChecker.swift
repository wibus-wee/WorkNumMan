//
//  FormatChecker.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import Foundation

struct StudentCheckResult {
    var isRightFormat: Bool
    var isSubmitted: Bool
    var diff: [DiffChar]
}

/// 检查目录是否符合格式，同时检查谁没有按时提交文件
/// - Parameters:
///   - directory: 目录
///   - checkFormat: 检查格式
///
/// Parse Format:
/// 你可以使用以下关键语法：
/// - <id> - 学号。
/// - <name> - 姓名。
/// - <any> - 任意长度的任意字符。
/// - <order> - 序号。(1, 2, 3, ...)
/// - <order_CN> - 中文序号。(一, 二, 三, ...)
///
/// for example: <id><name>实验报告.docx 则会检查学生提交的文件是否符合格式
func checkDirectoryWithCheckFormat(directory: URL, checkFormat: String) -> [String: StudentCheckResult] {
    print("[*] Checking directory: \(directory.path)")
    var result: [String: StudentCheckResult] = [:]
    let studentList = loadStudents()
    for student in studentList.students {
        let fileName = checkFormat
            .replacingOccurrences(of: "<id>", with: student.studentId)
            .replacingOccurrences(of: "<name>", with: student.name)
            .replacingOccurrences(of: "<order>", with: String(studentList.students.firstIndex(where: { $0.studentId == student.studentId })! + 1))
            .replacingOccurrences(of: "<order_CN>", with: convertToCNNumber(studentList.students.firstIndex(where: { $0.studentId == student.studentId })! + 1))

        let anyPattern = "<any>"
        let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        var foundFileName = ""
        var diffInfo: [DiffChar] = []
        var hasSubmitted = false

        if let files = files {
            for file in files {
                let fileNameWithoutPath = file.lastPathComponent
                let pattern = fileName.replacingOccurrences(of: anyPattern, with: ".*")
                if let regex = try? NSRegularExpression(pattern: "^\(pattern)$") {
                    let range = NSRange(location: 0, length: fileNameWithoutPath.utf16.count)
                    if regex.firstMatch(in: fileNameWithoutPath, range: range) != nil {
                        foundFileName = fileNameWithoutPath
                        hasSubmitted = true
                        break
                    }
                }

                // 计算最相似的文件名
                if fileNameWithoutPath.lowercased().contains(student.name.lowercased()) {
                    hasSubmitted = true
                    let expectedName = fileName.replacingOccurrences(of: anyPattern, with: "")
                    diffInfo = calculateDiff(
                        expected: expectedName.replacingOccurrences(of: " ", with: ""),
                        actual: fileNameWithoutPath.replacingOccurrences(of: " ", with: "")
                    )
                }
            }
        }

        let exists = !foundFileName.isEmpty
        result[student.name] = StudentCheckResult(
            isRightFormat: exists,
            isSubmitted: hasSubmitted,
            diff: diffInfo
        )
    }
    return result
}

// 添加一个辅助函数来转换数字为中文数字
private func convertToCNNumber(_ num: Int) -> String {
    let cnNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
                    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
    guard num > 0 && num <= cnNumbers.count else { return String(num) }
    return cnNumbers[num - 1]
}
