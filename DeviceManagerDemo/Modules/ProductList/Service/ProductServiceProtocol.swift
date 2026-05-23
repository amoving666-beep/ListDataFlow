//
//  ProductServiceProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/6.
//

import Foundation

/// ProductServiceProtocol
///
/// 作用：
/// 定义商品列表页相关的数据请求能力。
///
/// 注意：
/// ViewModel 不直接依赖 ProductService 这个具体类，
/// 而是依赖这个 protocol。
///
/// 好处：
/// 1. 真实运行时可以传 ProductService
/// 2. 单元测试时可以传 MockProductService
/// 3. ViewModel 不关心数据到底来自真实网络还是假数据
protocol ProductServiceProtocol {
    
    /// 请求商品列表。
    ///
    /// 商品列表是主接口。
    /// 失败且无缓存时，页面可以进入 error。
    /// 失败但已有旧数据时，保留旧列表并轻提示。
    ///
    /// - Parameters:
    ///   - page: 当前请求第几页。
    ///   - pageSize: 每页请求多少条。
    ///   - completion: 请求完成后的回调，成功返回 PageResponse<Product>，失败返回 NetworkError。
    /// - Returns: 返回 URLSessionDataTask，方便调用方按 RequestKey 保存和取消。
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求用户信息。
    ///
    /// 用户信息是中/强依赖接口。
    /// 普通失败不应该影响商品列表主数据展示。
    /// 后续如果模拟 token 失效，可以单独处理为跳登录。
    ///
    /// - Parameter completion: 请求完成后的回调，成功返回 UserInfo，失败返回 NetworkError。
    /// - Returns: 返回 URLSessionDataTask，方便调用方按 RequestKey 保存和取消。
    @discardableResult
    func fetchUserInfo(
        completion: @escaping (Result<UserInfo, NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求 Banner 列表。
    ///
    /// Banner 是副接口。
    /// 失败时不应该让整个页面进入 error。
    ///
    /// - Parameter completion: 请求完成后的回调，成功返回 [Banner]，失败返回 NetworkError。
    /// - Returns: 返回 URLSessionDataTask，方便调用方按 RequestKey 保存和取消。
    @discardableResult
    func fetchBanners(
        completion: @escaping (Result<[Banner], NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求推荐商品列表。
    ///
    /// 推荐商品是副接口。
    /// 失败时不影响主商品列表展示。
    ///
    /// - Parameter completion: 请求完成后的回调，成功返回 [Product]，失败返回 NetworkError。
    /// - Returns: 返回 URLSessionDataTask，方便调用方按 RequestKey 保存和取消。
    @discardableResult
    func fetchRecommendProducts(
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) -> URLSessionDataTask?
    
    /// 请求未读消息数。
    ///
    /// 未读消息数是弱接口。
    /// 失败时最多隐藏角标或显示 0。
    ///
    /// - Parameter completion: 请求完成后的回调，成功返回 UnreadCount，失败返回 NetworkError。
    /// - Returns: 返回 URLSessionDataTask，方便调用方按 RequestKey 保存和取消。
    @discardableResult
    func fetchUnreadCount(
        completion: @escaping (Result<UnreadCount, NetworkError>) -> Void
    ) -> URLSessionDataTask?
}
