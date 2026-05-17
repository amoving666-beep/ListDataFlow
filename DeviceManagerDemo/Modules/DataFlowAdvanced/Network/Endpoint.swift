//
//  Endpoint.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// HTTP 请求方法。
///
/// Endpoint 不再用“一个接口一个 case”的枚举写法，
/// 而是变成通用请求配置对象。
/// method 用来描述这次请求是 GET、POST、PUT 还是 DELETE。
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// DataFlowAdvanced 模块的通用请求配置。
///
/// Endpoint 现在只描述一次请求需要的基础信息：
/// - url：最终请求地址
/// - method：HTTP 方法
/// - headers：请求头
/// - body：请求体
///
/// 这样设计后，不需要为每一个接口都新增一个 enum case，
/// Service 层可以根据业务需要通过 `Endpoint.get(...)`、`Endpoint.postJSON(...)` 等方法创建请求配置。
struct Endpoint {
    let url: URL?
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
}

extension Endpoint {
    
    /// 创建 GET 请求配置。
    ///
    /// - Parameters:
    ///   - urlString: 基础 URL 字符串。
    ///   - queryItems: query 参数。
    static func get(
        _ urlString: String,
        queryItems: [URLQueryItem] = []
    ) -> Endpoint {
        var components = URLComponents(string: urlString)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        return Endpoint(
            url: components?.url,
            method: .get,
            headers: [:],
            body: nil
        )
    }
    
    /// 创建 JSON POST 请求配置。
    ///
    /// - Parameters:
    ///   - urlString: 请求 URL 字符串。
    ///   - jsonObject: 要作为 JSON body 发送的数据。
    ///   - headers: 额外请求头。
    static func postJSON(
        _ urlString: String,
        jsonObject: [String: Any],
        headers: [String: String] = [:]
    ) -> Endpoint {
        var finalHeaders = headers
        finalHeaders["Content-Type"] = "application/json"
        
        let body = try? JSONSerialization.data(withJSONObject: jsonObject)
        
        return Endpoint(
            url: URL(string: urlString),
            method: .post,
            headers: finalHeaders,
            body: body
        )
    }
    
    /// 创建普通 POST 请求配置。
    ///
    /// 适合 body 已经由外部准备好的场景，比如加密参数、表单数据等。
    static func post(
        _ urlString: String,
        body: Data?,
        headers: [String: String] = [:]
    ) -> Endpoint {
        return Endpoint(
            url: URL(string: urlString),
            method: .post,
            headers: headers,
            body: body
        )
    }
}
