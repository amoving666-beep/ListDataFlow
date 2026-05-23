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

    /// 请求用户信息。
    ///
    /// 最终链路：
    /// ProductListViewModel / 并发请求 Demo
    /// → ProductServiceProtocol
    /// → ProductService
    /// → ProductEndpoint.userInfo
    /// → NetworkClient
    /// → ApiResponse<UserInfo>
    /// → UserInfo
    @discardableResult
    func fetchUserInfo(
        completion: @escaping (Result<UserInfo, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        let endpoint = ProductEndpoint.userInfo
        return networkClient.request(endpoint: endpoint, completion: completion)
    }

    /// 请求 Banner 列表。
    ///
    /// Banner 是副接口，失败时不应该影响商品列表主数据展示。
    @discardableResult
    func fetchBanners(
        completion: @escaping (Result<[Banner], NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        let endpoint = ProductEndpoint.banners
        return networkClient.request(endpoint: endpoint, completion: completion)
    }

    /// 请求推荐商品列表。
    ///
    /// 推荐商品是副接口，失败时不应该影响商品列表主数据展示。
    @discardableResult
    func fetchRecommendProducts(
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        let endpoint = ProductEndpoint.recommendProducts
        return networkClient.request(endpoint: endpoint, completion: completion)
    }

    /// 请求未读消息数。
    ///
    /// 未读消息数是弱接口，失败时最多隐藏角标或显示 0。
    @discardableResult
    func fetchUnreadCount(
        completion: @escaping (Result<UnreadCount, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        let endpoint = ProductEndpoint.unreadCount
        return networkClient.request(endpoint: endpoint, completion: completion)
    }
}
