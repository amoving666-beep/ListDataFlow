//
//  FileProductCacheStoreTests.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/25.
//

import XCTest
@testable import DeviceManagerDemo

final class FileProductCacheStoreTests: XCTestCase {

    // 每个测试用一个临时目录，避免读写真实 App 缓存。
    private var tempDirectoryURL: URL!
    // 被测试对象：这里专门测试 FileProductCacheStore 的 save / load / clear 行为。
    private var store: FileProductCacheStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // setUp 每个 test 执行前都会调用，给当前 test 准备独立目录。
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        // 注入临时目录，让测试文件写到 tmp/UUID 下，而不是系统 Caches。
        store = FileProductCacheStore(directoryURL: tempDirectoryURL)
    }

    override func tearDownWithError() throws {
        // tearDown 每个 test 执行后都会调用，清理本次测试产生的文件。
        if let tempDirectoryURL {
            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        store = nil
        tempDirectoryURL = nil

        try super.tearDownWithError()
    }

    func testSaveAndLoadPageResponse_success() throws {
        // 主路径：先准备一份分页数据，保存后再读取回来验证内容一致。
        let response = makePageResponse(
            page: 1,
            pageSize: 10,
            total: 1,
            list: [
                makeProduct(id: 1, title: "iPhone")
            ]
        )

        // 执行保存：PageResponse<Product> 会被编码成 JSON 文件。
        try store.savePageResponse(response)

        // 执行读取：从 JSON 文件解码回 PageResponse<Product>。
        let loaded = try store.loadPageResponse()

        XCTAssertEqual(loaded?.page, 1)
        XCTAssertEqual(loaded?.pageSize, 10)
        XCTAssertEqual(loaded?.total, 1)
        XCTAssertEqual(loaded?.list.count, 1)
        XCTAssertEqual(loaded?.list.first?.title, "iPhone")
    }

    func testLoadWhenFileNotExists_returnsNil() throws {
        // 首次启动/无缓存场景：文件不存在时应该安全返回 nil。
        let loaded = try store.loadPageResponse()

        XCTAssertNil(loaded)
    }

    func testClear_removesCacheFile() throws {
        // 先保存一份缓存，再 clear，最后确认读不到旧数据。
        let response = makePageResponse(
            page: 1,
            pageSize: 10,
            total: 1,
            list: [
                makeProduct(id: 1, title: "iPhone")
            ]
        )

        try store.savePageResponse(response)
        try store.clear()

        let loaded = try store.loadPageResponse()

        XCTAssertNil(loaded)
    }

    func testOverwrite_replacesOldCache() throws {
        // 覆盖场景：旧缓存保存后，再保存新缓存，新数据应该替换旧数据。
        let oldResponse = makePageResponse(
            page: 1,
            pageSize: 10,
            total: 1,
            list: [
                makeProduct(id: 1, title: "Old")
            ]
        )

        let newResponse = makePageResponse(
            page: 1,
            pageSize: 10,
            total: 1,
            list: [
                makeProduct(id: 2, title: "New")
            ]
        )

        // 连续保存两次，最终文件内容应该以最后一次保存为准。
        try store.savePageResponse(oldResponse)
        try store.savePageResponse(newResponse)

        let loaded = try store.loadPageResponse()

        XCTAssertEqual(loaded?.list.count, 1)
        XCTAssertEqual(loaded?.list.first?.id, 2)
        XCTAssertEqual(loaded?.list.first?.title, "New")
    }

    func testBrokenJSON_throws() throws {
        // 异常场景：手动写入一份损坏的 JSON，模拟缓存文件被破坏。
        try FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )

        let fileURL = tempDirectoryURL.appendingPathComponent("product_list_cache.json")
        try Data("broken json".utf8).write(to: fileURL)

        // 当前协议是 throws，文件存在但解码失败时应该抛错，而不是假装没有缓存。
        XCTAssertThrowsError(try store.loadPageResponse())
    }

    // 统一创建测试用 PageResponse，避免每个 test 重复写样板数据。
    private func makePageResponse(
        page: Int,
        pageSize: Int,
        total: Int,
        list: [Product]
    ) -> PageResponse<Product> {
        PageResponse(
            list: list, page: page,
            pageSize: pageSize,
            total: total
        )
    }

    // 统一创建测试用 Product，让测试重点留在缓存行为上。
    private func makeProduct(
        id: Int,
        title: String,
        body: String = "body"
    ) -> Product {
        Product(
            userId: 1,
            id: id,
            title: title,
            body: body
        )
    }
}
