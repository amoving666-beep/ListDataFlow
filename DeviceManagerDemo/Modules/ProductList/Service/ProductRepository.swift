//
//  ProductRepository.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/15.
//

import Foundation

final class ProductRepository: ProductRepositoryProtocol {
   
    private let service: ProductServiceProtocol
    private let cacheKey = "ProductListCacheKey"
    
    init(service: ProductServiceProtocol = ProductService()) {
        self.service = service
    }
    //如果调用者没有接收这个方法的返回值，请不要报警告
    @discardableResult
    func fetchProducts(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) -> URLSessionTask? {
        return service.fetchList(
            page: page,
            pageSize: pageSize,
            completion: completion
        )
    }
    
    func loadCachedProducts() -> [Product]? {
        return CacheHelper.load(key: cacheKey, as: [Product].self)
    }
    
    func saveProductsToCache(_ products: [Product]) {
        CacheHelper.save(products, key: cacheKey)
    }
    
    func clearCache() {
        CacheHelper.clear(key: cacheKey)
    }
    
}
