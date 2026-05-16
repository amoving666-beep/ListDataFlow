//
//  ProductRepositoryProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/15.
//

import Foundation

protocol ProductRepositoryProtocol {
    
    @discardableResult
    func fetchProducts(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) ->URLSessionTask?
    
    func loadCachedProducts() -> [Product]?
    
    func saveProductsToCache(_ products: [Product])
    
    func clearCache()
    
}
