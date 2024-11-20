//
//  ResultView.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import SwiftUI

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