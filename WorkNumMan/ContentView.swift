//
//  ContentView.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/9.
//

import SwiftUI


struct ContentView: View {
    // MARK: - State

    @State var studentList: StudentList = loadStudents()
    @State var checkDirectory: URL? = nil // 需要检查的目录
    @State var checkResult: [String: StudentCheckResult] = [:] // 检查结果
    @State var checkFormat: String = "" // 检查格式
    @State private var directoryHistory: DirectoryHistory = loadDirectoryHistory()

    // MARK: - UI State

    @State var showImportSheet: Bool = false
    @State var showResultSheet: Bool = false
    @State var showStudentListSheet: Bool = false
    @State var showUnsubmittedSheet: Bool = false

    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
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
                

                // 在目录选择区域下方添加
                if !directoryHistory.paths.isEmpty {
                    VStack(alignment: .leading) {
                        Text("最近使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(directoryHistory.paths, id: \.self) { path in
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text(path)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                checkDirectory = URL(fileURLWithPath: path)
                            }
                        }
                    }
                    .padding()
                }

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
                        if let directory = checkDirectory {
                            checkResult = checkDirectoryWithCheckFormat(directory: directory, checkFormat: checkFormat)
                            showResultSheet = true
                            saveDirectory(directory)
                        } else {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.messageText = "请选择一个目录. 或者拖拽文件夹到这里"
                            alert.runModal()
                        }
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
                        Button("查看未提交名单") {
                            showUnsubmittedSheet = true
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
        .sheet(isPresented: $showUnsubmittedSheet) {
            UnsubmittedListSheet(checkResult: checkResult)
                .frame(width: 400, height: 600)
        }
        .padding()
    }

    // 在选择目录后保存历史记录
    func saveDirectory(_ url: URL) {
        checkDirectory = url
        directoryHistory.add(url.path)
        saveDirectoryHistory(directoryHistory)
    }
}
