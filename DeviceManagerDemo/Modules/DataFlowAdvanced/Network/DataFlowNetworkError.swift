//
//  AdvancedNetworkError.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// 进阶数据流模块专用的网络错误类型。
///
/// 注意：这里不继续使用 ProductList 模块里的 NetworkError，
/// 是为了避免两个模块在同一个 target 里出现类型命名冲突，
/// 也让 DataFlowAdvanced 模块保持自己的独立错误表达。
enum DataFlowNetworkError: Error {
    
    /// URL 拼接失败，通常是字符串不是合法 URL。
    case invalidURL
    
    /// URLSession 返回的系统网络错误，例如断网、超时、DNS 失败、请求取消等。
    case requestFailed(Error)
    
    /// response 不是 HTTPURLResponse，说明拿不到 HTTP 状态码。
    case invalidResponse
    
    /// HTTP 状态码不是 2xx，例如 404、500。
    case invalidStatusCode(Int)
    
    /// 服务器没有返回正文数据。
    case noData
    
    /// JSON 解码失败。
    case decodingFailed(Error)
}
