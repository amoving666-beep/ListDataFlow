//
//  ProductEntity+Mapping.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/26.
//

import Foundation

extension ProductEntity {

    // Entity -> Product
    // 从 CoreData 读取出来后，转成业务层能用的 Product
    func toProduct() -> Product {
        Product(
            userId: Int(userId),
            id: Int(id),
            title: title ?? "",
            body: body ?? ""
        )
    }

    // Product -> Entity
    // 保存缓存时，把业务模型字段写入 CoreData 对象
    func update(from product: Product) {
        self.id = Int64(product.id)
        self.userId = Int64(product.userId)
        self.title = product.title
        self.body = product.body
        self.cachedAt = Date()
    }
}
