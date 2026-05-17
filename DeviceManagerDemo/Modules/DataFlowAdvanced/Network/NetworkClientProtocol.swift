//
//  NetworkClientProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// 进阶数据流模块的网络请求协议。
///
/// Protocol 描述的是“网络请求能力”，不是某个具体实现。
/// URLSessionNetworkClient、MockNetworkClient、未来的其他网络库实现，都可以遵守这个协议。
protocol NetworkClientProtocol {
    
    /// 请求原始 Data。
    ///
    /// 适合 Service 想自己解码、自己转换模型的场景。
    ///
    /// - Parameters:
    ///   - endpoint: 请求配置，里面包含 url / method / headers / body。
    ///   - completion: 请求完成后的 Data 结果回调。
    /// - Returns: 当前请求任务，用于后续取消请求。
    @discardableResult
    func requestData(
        endpoint: Endpoint,
        completion: @escaping (Result<Data, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask?
    
    /// 请求并直接解码成指定 Decodable 类型。
    ///
    /// 这个方法解决“NetworkClient 写死某个 Model”的问题。
    /// 调用方传入什么类型，NetworkClient 就尝试解码成什么类型。
    ///
    /// 示例：
    /// request(endpoint: endpoint, responseType: [PostResponse].self) { ... }
    @discardableResult
    func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type,
        completion: @escaping (Result<T, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask?
    
    /// 上传文件，并把响应解码成指定 Decodable 类型。
    ///
    /// 用于图片、文件上传等 multipart/form-data 场景。
    @discardableResult
    func upload<T: Decodable>(
        endpoint: Endpoint,
        fileData: Data,
        fieldName: String,
        fileName: String,
        mimeType: String,
        responseType: T.Type,
        completion: @escaping (Result<T, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask?
}
