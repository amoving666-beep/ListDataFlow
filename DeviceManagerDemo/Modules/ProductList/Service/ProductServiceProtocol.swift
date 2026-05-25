//
//  ProductServiceProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/6.
//

import Foundation

/// ProductServiceProtocol

protocol ProductServiceProtocol {
    
    /// 请求商品列表。

    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求用户信息。

    @discardableResult
    func fetchUserInfo(
        completion: @escaping (Result<UserInfo, NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求 Banner 列表。
    
    @discardableResult
    func fetchBanners(
        completion: @escaping (Result<[Banner], NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求推荐商品列表。

    @discardableResult
    func fetchRecommendProducts(
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求未读消息数。

    @discardableResult
    func fetchUnreadCount(
        completion: @escaping (Result<UnreadCount, NetworkError>) -> Void
    ) -> URLSessionDataTask?
}
