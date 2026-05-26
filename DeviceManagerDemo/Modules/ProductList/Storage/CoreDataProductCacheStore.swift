
//
//  CoreDataProductCacheStore.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/26.
//

import Foundation
import CoreData

final class CoreDataProductCacheStore: ProductCacheStoreProtocol {

    // CoreData 的实际操作入口。
    // 这里通过 CoreDataStack 注入，方便正式环境和 in-memory 测试环境切换。
    private let context: NSManagedObjectContext

    // 默认使用 shared stack；单元测试时可以传入 in-memory stack，避免污染真实数据库。
    init(stack: CoreDataStack = .shared) {
        self.context = stack.viewContext
    }

    // 当前采用 replace cache：
    // 每次保存新列表时，先清空旧缓存，再写入最新列表快照。
    func savePageResponse(_ response: PageResponse<Product>) throws {
        // 当前缓存是列表快照，不做分页增量合并。
        // 所以保存新数据前先清空旧数据，保证缓存内容和最新 response 一致。
        try clear()

        for product in response.list {
            // 每个 Product 对应一条 ProductEntity，由映射方法负责字段赋值。
            let entity = ProductEntity(context: context)
            entity.update(from: product)
        }

        // 只有 context 有变更时才 save，避免无意义的数据库写入。
        if context.hasChanges {
            try context.save()
        }
    }

    func loadPageResponse() throws -> PageResponse<Product>? {
        // 读取当前缓存的所有 ProductEntity。
        let request = ProductEntity.fetchRequest()

        // 固定按 id 升序读取，避免 CoreData 返回顺序不稳定影响列表展示。
        request.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]

        // 没有缓存时返回 nil，让上层决定是否继续走网络请求或展示空态。
        guard let entities = try context.fetch(request) as? [ProductEntity],
              !entities.isEmpty else {
            return nil
        }

        // CoreData Entity 只在缓存层内部使用，对外仍然返回业务模型 Product。
        let products = entities.map { $0.toProduct() }

        // 当前版本只恢复 list。
        // page / pageSize / total 暂时用 list.count 组装。
        // 后续如果需要完整分页信息，可以新增 ProductCacheMetaEntity。
        return PageResponse(
            list: products,
            page: 1,
            pageSize: products.count,
            total: products.count
        )
    }

    func clear() throws {
        // 当前数据量较小，先采用 fetch 后逐个 delete 的方式，逻辑更直观。
        // 后续数据量变大时，再考虑 NSBatchDeleteRequest。
        let request = ProductEntity.fetchRequest()

        guard let entities = try context.fetch(request) as? [ProductEntity] else {
            return
        }

        // 删除当前缓存中的所有 ProductEntity。
        for entity in entities {
            context.delete(entity)
        }

        if context.hasChanges {
            try context.save()
        }
    }
}
