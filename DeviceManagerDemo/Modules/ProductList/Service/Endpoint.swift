//
//  Endpoint.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 接口说明书协议。
///
/// `Endpoint` 不负责真正发请求，只负责描述一次网络请求需要的信息。

protocol Endpoint {
    /// 接口路径。
    var path: String { get }

    /// 请求方法。
    var method: HTTPMethod { get }

    /// URL 查询参数。
    var queryItems: [URLQueryItem] { get }

    /// 请求头。
    ///
    /// 常见内容：
    /// - `Authorization`：登录 token
    /// - `Content-Type`：请求体格式，例如 `application/json`
    /// - `Accept`：希望服务器返回的数据格式
    var headers: [String: String] { get }

    /// 请求体。
    ///
    /// 主要用于 POST / PUT 请求，例如登录、注册、保存表单。
    ///
    /// GET 请求通常不需要 body，返回 `nil` 即可。
    var body: Data? { get }
}
