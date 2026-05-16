//
//  NetworkClientProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// 进阶数据流模块的网络请求协议。
///
/// NetworkClientProtocol 只定义“网络客户端应该具备什么能力”，
/// 不关心具体是 URLSession、第三方库，还是测试里的 MockNetworkClient。
///
/// 这样上层 Service 依赖协议，而不是依赖具体 URLSessionNetworkClient，
/// 后续测试和替换网络实现会更容易。
protocol NetworkClientProtocol {
    
    /// 根据 Endpoint 发起网络请求，并返回原始 Data。
    ///
    /// - Parameters:
    ///   - endpoint: 请求端点，内部负责生成 URL。
    ///   - completion: 请求完成后的结果回调。
    /// - Returns: 当前请求任务，用于后续取消请求。
    @discardableResult
    func request(
        endpoint: Endpoint,
        completion: @escaping (Result<Data, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask?
}
