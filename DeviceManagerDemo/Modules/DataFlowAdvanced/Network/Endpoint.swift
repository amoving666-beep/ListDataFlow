//
//  Endpoint.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// DataFlowAdvanced 模块的请求端点。
///
/// Endpoint 的职责是集中管理 URL 拼接逻辑，避免把 URL 字符串散落在 Service 或 ViewModel 里。
/// 当前第一阶段先接入 jsonplaceholder 的 posts 接口。
/// 后续如果要切换 users / randomUsers，只需要继续增加 case。
enum Endpoint {
    
    /// posts 列表接口。
    ///
    /// - page: 当前页码。
    /// - pageSize: 每页数量。
    case posts(page: Int, pageSize: Int)
    
    /// 根据当前 endpoint 生成最终请求 URL。
    var url: URL? {
        switch self {
        case .posts(let page, let pageSize):
            var components = URLComponents(string: "https://jsonplaceholder.typicode.com/posts")
            components?.queryItems = [
                URLQueryItem(name: "_page", value: "\(page)"),
                URLQueryItem(name: "_limit", value: "\(pageSize)")
            ]
            return components?.url
        }
    }
}
