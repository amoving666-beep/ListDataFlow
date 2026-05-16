//
//  ListServiceProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// DataFlowAdvanced 模块的列表业务服务协议。
///
/// Service 这一层负责把底层 NetworkClient 返回的 Data，
/// 解码并转换成上层需要的 `[ListItem]`。
///
/// 注意：
/// - NetworkClient 只负责通用网络请求，返回 Data。
/// - ListService 负责列表接口业务语义，返回 ListItem。
/// - ViewModel 不应该直接接触 Data，也不应该自己 JSONDecoder。
protocol ListServiceProtocol {
    
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
}
