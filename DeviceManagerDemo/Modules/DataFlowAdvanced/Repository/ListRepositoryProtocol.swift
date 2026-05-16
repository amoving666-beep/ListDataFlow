//
//  ListRepositoryProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// DataFlowAdvanced 模块的数据仓库协议。
///
/// Repository 这一层负责给 ViewModel 提供统一的数据入口。
/// 它会组合网络数据和缓存数据，但 ViewModel 不需要知道数据具体来自 Service 还是 CacheStore。
///
/// 当前阶段先定义三个能力：
/// 1. 请求列表数据
/// 2. 读取缓存列表
/// 3. 清除缓存
protocol ListRepositoryProtocol {
    
    /// 请求列表数据。
    ///
    /// - Parameters:
    ///   - page: 当前页码。
    ///   - pageSize: 每页数量。
    ///   - completion: 请求完成后的结果回调。
    /// - Returns: 当前请求任务，用于后续取消请求。
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<[ListItem], DataFlowNetworkError>) -> Void
    ) -> URLSessionTask?
    
    /// 读取本地缓存的列表数据。
    ///
    /// - Returns: 如果有缓存，返回 `[ListItem]`；否则返回 nil。
    func loadCachedList() -> [ListItem]?
    
    /// 清除本地缓存的列表数据。
    func clearCachedList()
}
