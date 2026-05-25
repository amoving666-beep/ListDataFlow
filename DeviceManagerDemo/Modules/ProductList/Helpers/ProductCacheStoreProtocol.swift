//
//  ProductCacheStoreProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/25.
//

import Foundation

protocol ProductCacheStoreProtocol {
    func savePageResponse(_ response: PageResponse<Product>) throws
    func loadPageResponse() throws -> PageResponse<Product>?
    func clear() throws
}
