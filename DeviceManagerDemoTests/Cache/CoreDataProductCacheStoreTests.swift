//
//  CoreDataProductCacheStoreTests.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/26.
//

import XCTest
@testable import DeviceManagerDemo

final class CoreDataProductCacheStoreTests: XCTestCase {

    private var stack: CoreDataStack!
    private var store: CoreDataProductCacheStore!

    override func setUp() {
        super.setUp()

        stack = CoreDataStack(inMemory: true)
        store = CoreDataProductCacheStore(stack: stack)
    }

    override func tearDown() {
        store = nil
        stack = nil

        super.tearDown()
    }

    func testSaveAndLoadPageResponse_success() throws {
        // 保存顺序故意写成 2、1，用来验证读取时是否按 id 排序。
        let response = makePageResponse([
            makeProduct(id: 2, title: "MacBook Pro", body: "Apple laptop"),
            makeProduct(id: 1, title: "iPhone", body: "Apple phone")
        ])

        // 写入 CoreData 缓存。
        try store.savePageResponse(response)

        // 再从 CoreData 读取，验证 save -> load 的完整闭环。
        let cached = try store.loadPageResponse()

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.list.count, 2)

        // load 时按 id 升序返回，所以 id = 1 在前。
        XCTAssertEqual(cached?.list[0].id, 1)
        XCTAssertEqual(cached?.list[0].title, "iPhone")
        XCTAssertEqual(cached?.list[0].body, "Apple phone")

        XCTAssertEqual(cached?.list[1].id, 2)
        XCTAssertEqual(cached?.list[1].title, "MacBook Pro")
        XCTAssertEqual(cached?.list[1].body, "Apple laptop")
    }

    func testLoadWhenEmpty_returnsNil() throws {
        // 空缓存场景：没有任何 ProductEntity 时，应该返回 nil。
        let cached = try store.loadPageResponse()

        XCTAssertNil(cached)
    }

    func testClear_removesProducts() throws {
        let response = makePageResponse([
            makeProduct(id: 1, title: "iPhone", body: "Apple phone")
        ])

        // 先写入一份缓存，再执行 clear。
        try store.savePageResponse(response)
        try store.clear()

        // clear 后再次读取，应该读不到任何缓存。
        let cached = try store.loadPageResponse()

        XCTAssertNil(cached)
    }

    func testSavePageResponse_replacesOldProducts() throws {
        let oldResponse = makePageResponse([
            makeProduct(id: 1, title: "Old iPhone", body: "Old body")
        ])

        let newResponse = makePageResponse([
            makeProduct(id: 2, title: "New iPad", body: "New body")
        ])

        // 当前缓存策略是 replace：第二次保存应该替换第一次保存的数据。
        try store.savePageResponse(oldResponse)
        try store.savePageResponse(newResponse)

        // 读取结果里只能有新数据，不能残留旧数据。
        let cached = try store.loadPageResponse()

        XCTAssertEqual(cached?.list.count, 1)
        XCTAssertEqual(cached?.list.first?.id, 2)
        XCTAssertEqual(cached?.list.first?.title, "New iPad")
    }

    func testLoadedProducts_areSortedById() throws {
        // 保存时故意打乱 id 顺序，验证 load 时的排序规则稳定。
        let response = makePageResponse([
            makeProduct(id: 3, title: "C", body: "body C"),
            makeProduct(id: 1, title: "A", body: "body A"),
            makeProduct(id: 2, title: "B", body: "body B")
        ])

        try store.savePageResponse(response)

        let cached = try store.loadPageResponse()

        // 缓存读取统一按 id 升序返回，避免 UI 展示顺序随机。
        XCTAssertEqual(cached?.list.map { $0.id }, [1, 2, 3])
    }

    // MARK: - Helpers

    // 测试辅助方法：减少每个测试里创建 Product 的重复代码。
    private func makeProduct(
        userId: Int = 1,
        id: Int,
        title: String,
        body: String
    ) -> Product {
        return Product(
            userId: userId,
            id: id,
            title: title,
            body: body
        )
    }

    // 当前 CoreData 缓存测试重点是 list，所以 page/pageSize/total 使用最小默认值。
    private func makePageResponse(_ products: [Product]) -> PageResponse<Product> {
        return PageResponse(
            list: products,
            page: 1,
            pageSize: products.count,
            total: products.count
        )
    }
}
