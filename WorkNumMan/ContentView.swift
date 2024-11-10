//
//  ContentView.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/9.
//

import SwiftUI

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
/// 你可以使用以下关键语法： <id> - 学号。 <name> - 姓名。<any> - 任意长度的任意字符。
/// for example: <id><name>实验报告.docx 则会检查学生提交的文件是否符合格式
func checkDirectoryWithCheckFormat(directory: URL, checkFormat: String) -> [String: StudentCheckResult] {
    print("[*] Checking directory: \(directory.path)")
    var result: [String: StudentCheckResult] = [:]
    let studentList = loadStudents()
    for student in studentList.students {
        let fileName = checkFormat
            .replacingOccurrences(of: "<id>", with: student.studentId)
            .replacingOccurrences(of: "<name>", with: student.name)

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

struct CheckResultItem: Identifiable {
    let id = UUID()
    let name: String
    let result: StudentCheckResult
}

let commonFormats = [
    "<id><name>第<any>周实验（训）报告.docx",
]

let commonKeyWords = [
    "<id>",
    "<name>",
    "<any>",
]

struct ContentView: View {
    // MARK: - State

    @State var studentList: StudentList = loadStudents()
    @State var checkDirectory: URL? = nil // 需要检查的目录
    @State var checkResult: [String: StudentCheckResult] = [:] // 检查结果
    @State var checkFormat: String = "" // 检查格式

    // MARK: - UI State

    @State var showImportSheet: Bool = false
    @State var showResultSheet: Bool = false
    @State var showStudentListSheet: Bool = false
    var body: some View {
        ScrollView {
            VStack {
                // MARK: - Directory

                VStack(alignment: .leading) {
                    Text("目录")
                        .font(.title2)
                        .fontWeight(.bold)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .frame(height: 100)
                            .foregroundColor(.gray)
                        if let directory = checkDirectory {
                            VStack {
                                Image(systemName: "folder")
                                    .font(.system(size: 30))
                                Text(directory.path)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .foregroundColor(.gray)
                        } else {
                            VStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 30))
                                Text("拖拽文件夹到这里或点击选择")
                            }
                            .foregroundColor(.gray)
                        }
                    }
                    .onTapGesture {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false

                        if panel.runModal() == .OK {
                            checkDirectory = panel.url
                        }
                    }
                    .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                        guard let provider = providers.first else { return false }

                        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, _ in
                            if let urlData = urlData as? Data,
                               let path = String(data: urlData, encoding: .utf8),
                               let url = URL(string: path)
                            {
                                var isDirectory: ObjCBool = false
                                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                                   isDirectory.boolValue
                                {
                                    DispatchQueue.main.async {
                                        checkDirectory = url
                                    }
                                }
                            }
                        }
                        return true
                    }
                }
                .padding()

                // MARK: - Check Format

                VStack(alignment: .leading) {
                    Text("检查格式")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("你可以使用以下关键语法： \(commonKeyWords.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("检查格式", text: $checkFormat)
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 30)

                    Divider()

                    VStack(alignment: .leading) {
                        Text("常用格式")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        ForEach(commonFormats, id: \.self) { format in
                            CommonFormat(checkFormat: $checkFormat, format: format)
                        }

                        Spacer()

                        HStack {
                            ForEach(commonKeyWords, id: \.self) { keyword in
                                CommonFormatKeyword(checkFormat: $checkFormat, keyword: keyword)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()

                 // MARK: - Action

                HStack {
                    Button("检查") {
                        checkResult = checkDirectoryWithCheckFormat(directory: checkDirectory!, checkFormat: checkFormat)
                        showResultSheet = true
                    }
                    Button("导入学生") {
                        showImportSheet = true
                    }
                    Button("学生列表") {
                        showStudentListSheet = true
                    }
                    if !checkResult.isEmpty {
                        Button("导出结果为图片") {
                            if let resultView = ResultView(
                                checkResult: checkResult,
                                directoryName: checkDirectory?.lastPathComponent ?? "未知目录"
                            ).exportAsImage() {
                                let savePanel = NSSavePanel()
                                savePanel.allowedContentTypes = [.png]
                                savePanel.nameFieldStringValue = "检查结果.png"
                                
                                if savePanel.runModal() == .OK {
                                    if let url = savePanel.url {
                                        if let data = resultView.tiffRepresentation,
                                           let bitmap = NSBitmapImageRep(data: data),
                                           let pngData = bitmap.representation(using: .png, properties: [:]) {
                                            try? pngData.write(to: url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()

                // MARK: - Check Result

                if checkResult.count > 0 {
                    VStack(alignment: .leading) {
                        Text("检查结果")
                            .font(.title2)
                            .fontWeight(.bold)

                        ResultView(checkResult: checkResult, directoryName: nil)
                    }
                    .padding()
                }
            }
        }
        // .sheet(isPresented: $showResultSheet) {
        //     ResultSheet(checkResult: checkResult)
        //         .frame(width: 800, height: 600)
        // }
        .sheet(isPresented: $showImportSheet) {
            ImportSheet()
        }
        .sheet(isPresented: $showStudentListSheet) {
            StudentListSheet()
                .frame(width: 800, height: 600)
        }
        .padding()
    }
}

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

struct CommonFormatKeyword: View {
    @State var hovering: Bool = false
    @Binding var checkFormat: String
    let keyword: String
    var body: some View {
        Text(keyword)
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
                checkFormat = "\(checkFormat)\(keyword)"
            }
    }
}

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

struct DiffView: View {
    let diff: [DiffChar]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(diff) { char in
                Text(char.char)
                    .font(.system(.body, design: .monospaced))
                    .background(backgroundColor(for: char.type))
            }
        }
    }

    private func backgroundColor(for type: DiffType) -> Color {
        switch type {
        case .normal:
            return .clear
        case .added:
            return .green.opacity(0.3)
        case .deleted:
            return .red.opacity(0.3)
        case .modified:
            return .yellow.opacity(0.3)
        }
    }
}

struct ResultView: View {
    let checkResult: [String: StudentCheckResult]
    let directoryName: String? // 新增属性
    
    // 添加导出图片的函数
    func exportAsImage() -> NSImage? {
        let view = self
            .frame(width: 800) // 设置固定宽度以确保导出效果
            .padding()
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // 设置2倍清晰度
        
        // 配置输出属性
        if let nsImage = renderer.nsImage {
            return nsImage
        }
        return nil
    }
    
    // 添加背景色计算函数
    private func getBackgroundColor(result: StudentCheckResult) -> Color {
        if !result.isSubmitted {
            // 未提交的显示浅红色背景
            return Color.red.opacity(0.1)
        } else if !result.isRightFormat {
            // 格式错误的显示浅黄色背景
            return Color.yellow.opacity(0.1)
        }
        // 正常的显示浅灰色背景
        return Color.gray.opacity(0.05)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let directoryName = directoryName {
                Text("\(directoryName) 的提交情况")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.vertical)
            }
                
            // MARK: - Header

            HStack {
                Text("名字")
                    .frame(width: 100, alignment: .leading) // 添加左对齐
                Text("提交情况")
                    .frame(width: 100, alignment: .center)
                Text("格式情况")
                    .frame(width: 100, alignment: .center)
                Text("差异")
                    .frame(minWidth: 200, alignment: .leading) // 使用 minWidth
                Spacer() // 添加 Spacer 确保右侧对齐
            }
            .padding(.horizontal) // 添加水平内边距
            .padding(.vertical, 8) // 添加垂直内边距
            .background(.gray.opacity(0.1))

            // MARK: - Body

            ForEach(checkResult.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .frame(width: 100, alignment: .leading)
                    HStack {
                        Image(systemName: value.isSubmitted ? "checkmark.circle" : "xmark.circle")
                            .foregroundColor(value.isSubmitted ? .green : .red)
                    }
                    .frame(width: 100)
                    HStack {
                        Image(systemName: value.isRightFormat ? "checkmark.circle" : "xmark.circle")
                            .foregroundColor(value.isRightFormat ? .green : .red)
                    }
                    .frame(width: 100)
                    if !value.isRightFormat && !value.diff.isEmpty {
                        DiffView(diff: value.diff)
                            .frame(minWidth: 200, alignment: .leading)
                    } else {
                        Text("")
                            .frame(minWidth: 200, alignment: .leading)
                    }
                    Spacer() // 添加 Spacer 确保右侧对齐
                }
                .padding(.horizontal) // 添加水平内边距
                .padding(.vertical, 8) // 添加垂直内边距
                .background(getBackgroundColor(result: value)) // 使用新的背景色
                .border(Color.gray.opacity(0.1), width: 0.5) // 添加细边框
            }
        }
        .background(Color(NSColor.textBackgroundColor)) // 自动适应深色/浅色模式
        .cornerRadius(8) // 添加圆角
        .overlay( // 添加边框
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

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


