//
//  DirectoryHistory.swift
//  WorkNumMan
//
//  Created by wibus on 2024/11/20.
//

import Foundation


struct DirectoryHistory: Codable {
    var paths: [String] = []
    var maxCount = 5
    
    mutating func add(_ path: String) {
        // 移除已存在的相同路径
        paths.removeAll { $0 == path }
        // 添加新路径到开头
        paths.insert(path, at: 0)
        // 保持最大数量为5
        if paths.count > maxCount {
            paths = Array(paths.prefix(maxCount))
        }
    }
}

func loadDirectoryHistory() -> DirectoryHistory {
    let defaults = UserDefaults.standard
    let decoder = JSONDecoder()
    if let savedDirectoryHistory = defaults.object(forKey: "directoryHistory") as? Data {
        return try! decoder.decode(DirectoryHistory.self, from: savedDirectoryHistory)
    }
    return DirectoryHistory()
}

func saveDirectoryHistory(_ history: DirectoryHistory) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(history) {
        defaults.set(encoded, forKey: "directoryHistory")
    }
}
