//
//  HTTPMethod.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// HTTP 请求方法。
///
/// 用来描述一次请求想对服务器做什么。
///
/// 常见理解：
/// - `GET`：查询 / 获取数据，例如获取商品列表、商品详情。
/// - `POST`：提交 / 新增数据，例如登录、注册、创建订单。
/// - `PUT`：整体更新数据。
/// - `DELETE`：删除数据。
///
/// 这里用 `String` 作为 RawValue，是因为 `URLRequest.httpMethod` 需要的是字符串，
/// 例如 `"GET"`、`"POST"`。
enum HTTPMethod: String {
    /// 获取数据。
    case get = "GET"

    /// 提交数据。
    case post = "POST"

    /// 更新数据。
    case put = "PUT"

    /// 删除数据。
    case delete = "DELETE"
}
