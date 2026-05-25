//
//  UserDefaultsProductCacheStore.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/25.
//

import Foundation


final class UserDefaultsProductCacheStore: ProductCacheStoreProtocol {

    private let cacheKey = "product_page_cache"

    func savePageResponse(_ response: PageResponse<Product>) throws {
        CacheHelper.save(response, key: cacheKey)
    }

    func loadPageResponse() throws -> PageResponse<Product>? {
        return CacheHelper.load(key: cacheKey, as: PageResponse<Product>.self)
    }

    func clear() throws {
        CacheHelper.clear(key: cacheKey)
    }
}
