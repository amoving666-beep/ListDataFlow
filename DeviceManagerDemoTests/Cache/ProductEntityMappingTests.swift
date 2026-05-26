//
//  ProductEntityMappingTests.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/26.
//

import XCTest
import CoreData
@testable import DeviceManagerDemo

final class ProductEntityMappingTests: XCTestCase {

    // 每个测试都单独创建一套 in-memory CoreData 环境。
    // 这样测试之间互不影响，也不会污染真实 App 数据。
    private var coreDataStack: CoreDataStack!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        // 使用 in-memory CoreData，测试数据只存在内存里。
        // 测试结束后销毁，不会写入真实 sqlite 文件。
        coreDataStack = CoreDataStack(inMemory: true)

        // viewContext 是 CoreDataStack 暴露给外部使用的主 context。
        // 这里直接用它创建 ProductEntity，模拟真实缓存写入时的对象环境。
        context = coreDataStack.viewContext
    }

    override func tearDown() {
        // 主动释放，避免上一个测试的数据或 context 状态影响下一个测试。
        context = nil
        coreDataStack = nil

        super.tearDown()
    }

    func testUpdateFromProduct_mapsFieldsCorrectly() {
        // 目标：验证 Product -> ProductEntity。
        // 也就是业务模型写入 CoreData 对象时，字段有没有丢、有没有写错。

        // Product 是业务模型，正常来自网络层 / ViewModel。
        let product = Product(
            userId: 10,
            id: 100,
            title: "iPhone 17",
            body: "Apple 新款手机"
        )

        // ProductEntity 是 CoreData 管理的数据库对象。
        // 必须通过 context 创建，不能直接 ProductEntity() 初始化。
        let entity = ProductEntity(context: context)

        // update(from:) 是本模块的核心写入映射方法。
        entity.update(from: product)

        // 验证 Product -> ProductEntity 字段映射是否正确。
        // 注意：Product 里的 Int 写入 Entity 后会变成 Int64。
        XCTAssertEqual(entity.userId, 10)
        XCTAssertEqual(entity.id, 100)
        XCTAssertEqual(entity.title, "iPhone 17")
        XCTAssertEqual(entity.body, "Apple 新款手机")
    }

    func testToProduct_mapsFieldsCorrectly() {
        // 目标：验证 ProductEntity -> Product。
        // 也就是从 CoreData 读出缓存后，能不能还原成业务层可用的 Product。

        // 手动准备一个 CoreData 对象，模拟数据库里已经存在一条缓存数据。
        let entity = ProductEntity(context: context)
        entity.userId = 20
        entity.id = 200
        entity.title = "MacBook Pro 14"
        entity.body = "适合移动开发和高性能办公"
        entity.cachedAt = Date()

        // toProduct() 是本模块的核心读取映射方法。
        let product = entity.toProduct()

        // 验证 ProductEntity -> Product 字段映射是否正确。
        // 这里也顺便验证了 Int64 -> Int 的转换是否符合预期。
        XCTAssertEqual(product.userId, 20)
        XCTAssertEqual(product.id, 200)
        XCTAssertEqual(product.title, "MacBook Pro 14")
        XCTAssertEqual(product.body, "适合移动开发和高性能办公")
    }

    func testUpdateFromProduct_setsCachedAt() {
        // 目标：验证 update(from:) 不只写业务字段，也会写入缓存时间。
        // cachedAt 后面可以用于缓存过期、调试、排序等场景。

        let product = Product(
            userId: 30,
            id: 300,
            title: "iPad Pro",
            body: "轻量办公与内容创作设备"
        )

        let entity = ProductEntity(context: context)

        // update 前还没有缓存时间。
        XCTAssertNil(entity.cachedAt)

        entity.update(from: product)

        // update 后必须有缓存时间，证明这条 Entity 已经被当作本地缓存写入过。
        XCTAssertNotNil(entity.cachedAt)
    }
}
