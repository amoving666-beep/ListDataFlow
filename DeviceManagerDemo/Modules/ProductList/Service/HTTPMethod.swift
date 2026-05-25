//
//  HTTPMethod.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// HTTP 请求方法。
/// 
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
