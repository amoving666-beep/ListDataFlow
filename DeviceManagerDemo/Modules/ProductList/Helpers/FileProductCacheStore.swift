//
//  FileProductCacheStore.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/25.
//

import Foundation

final class FileProductCacheStore: ProductCacheStoreProtocol {

    // 1. 文件操作对象。
    // 默认用 FileManager.default，测试时也可以注入。
    private let fileManager: FileManager

    // 2. 缓存文件所在目录。
    // 正式环境默认是 Caches，测试时传临时目录。
    private let directoryURL: URL

    // 3. 缓存文件名。
    // 当前只缓存 Product 列表，所以先固定一个 json 文件。
    private let fileName: String

    // 4. 最终完整文件路径。
    // directoryURL + fileName = fileURL
    private var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }

    // 5. 初始化缓存目录和文件名。
    // 不传 directoryURL 时，默认使用系统 Caches Directory。
    // 传 directoryURL 时，主要用于单元测试隔离。
    init(
        directoryURL: URL? = nil,
        fileName: String = "product_list_cache.json",
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileName = fileName

        if let directoryURL = directoryURL {
            self.directoryURL = directoryURL
        } else {
            self.directoryURL = fileManager.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            )[0]
        }
    }

    // 6. 保存缓存。
    // PageResponse<Product> -> JSON Data -> 写入本地文件。
    func savePageResponse(_ response: PageResponse<Product>) throws {
        try createDirectoryIfNeeded()

        let data = try JSONEncoder().encode(response)

        // .atomic：尽量避免写一半导致文件损坏。
        try data.write(to: fileURL, options: .atomic)
    }

    // 7. 读取缓存。
    // 文件不存在返回 nil；文件存在但 JSON 损坏时，decode 会抛错。
    func loadPageResponse() throws -> PageResponse<Product>? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(PageResponse<Product>.self, from: data)
    }

    // 8. 清除缓存。
    // 文件不存在时直接 return，避免 removeItem 抛无意义错误。
    func clear() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    // 9. 创建缓存目录。
    // 测试时传入的 UUID 临时目录通常一开始不存在，所以保存前要先创建。
    private func createDirectoryIfNeeded() throws {
        guard !fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}
