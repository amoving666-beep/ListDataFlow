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
///
/// 它会告诉 `NetworkClient`：
/// - 请求哪个接口路径
/// - 使用什么请求方法
/// - URL 后面带哪些查询参数
/// - 请求头里带哪些信息
/// - 请求体里提交什么数据
///
/// 真正生成 `URLRequest`、执行 `URLSession`、解析响应数据的是 `NetworkClient`。
protocol Endpoint {
    /// 接口路径。
    ///
    /// 例如：
    /// - `/products`
    /// - `/login`
    /// - `/user/info`
    ///
    /// 注意：这里不是完整 URL，不包含 `https://xxx.com`。
    /// 完整 URL 会由 `NetworkClient` 使用 baseURL + path 拼出来。
    var path: String { get }

    /// 请求方法。
    ///
    /// 例如：
    /// - GET：查询数据
    /// - POST：提交数据
    /// - PUT：更新数据
    /// - DELETE：删除数据
    var method: HTTPMethod { get }

    /// URL 查询参数。
    ///
    /// 主要用于 GET 请求，例如：
    /// `/products?page=1&pageSize=10`
    ///
    /// 这里对应的就是：
    /// - `page = 1`
    /// - `pageSize = 10`
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
