//
//  ProductService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import Foundation

/// 商品业务 Service。
final class ProductService: ProductServiceProtocol {
    
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }
    
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
