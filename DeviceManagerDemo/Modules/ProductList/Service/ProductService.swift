//
//  ProductService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import Foundation

/// 商品业务 Service。
///
/// 职责边界：
/// - ProductService 只关心“商品列表应该调用哪个商品接口”。
/// - 它不再直接拼 URL。
/// - 它不再直接使用 URLSession。
/// - 它不再直接解码 ApiResponse。
///
/// 真正通用的网络流程交给 NetworkClient。
/// 商品接口信息交给 ProductEndpoint。
final class ProductService: ProductServiceProtocol {
    
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    /// 请求商品列表。
    ///
    /// 最终链路：
    /// ProductListViewModel
    /// → ProductServiceProtocol
    /// → ProductService
    /// → ProductEndpoint
    /// → NetworkClient
    /// → ApiResponse<PageResponse<Product>>
    /// → PageResponse<Product>
    ///
    /// - Returns:
    ///   返回 URLSessionDataTask?，让 ViewModel 继续保存 currentTask，
    ///   用于下拉刷新或页面销毁时取消旧请求。
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        let endpoint = ProductEndpoint.list(page: page, pageSize: pageSize)
        return networkClient.request(endpoint: endpoint, completion: completion)
    }
}
