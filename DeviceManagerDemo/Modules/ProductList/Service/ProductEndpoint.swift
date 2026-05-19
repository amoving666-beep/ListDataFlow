//
//  ProductEndpoint.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 商品模块的接口说明。
///
/// `ProductEndpoint` 不负责真正发请求，它只负责描述商品相关接口的信息。
///
/// 例如商品列表接口需要：
/// - 接口路径：`/products`
/// - 请求方法：`GET`
/// - 查询参数：`page`、`pageSize`
/// - 请求头：例如 `Accept: application/json`
/// - 请求体：GET 请求通常没有 body
///
/// 真正发请求的是 `NetworkClient`。
enum ProductEndpoint: Endpoint {
    /// 商品列表接口。
    ///
    /// - `page`：请求第几页。
    /// - `pageSize`：每页请求多少条。
    case list(page: Int, pageSize: Int)

    /// 接口路径。
    ///
    /// 这里先用 `/products` 表示商品列表接口路径。
    /// 真正完整 URL 会由 `NetworkClient` 使用 baseURL + path 拼出来。
    var path: String {
        switch self {
        case .list:
            return "/products"
        }
    }

    /// 请求方法。
    ///
    /// 商品列表是查询数据，所以使用 GET。
    var method: HTTPMethod {
        switch self {
        case .list:
            return .get
        }
    }

    /// URL 查询参数。
    ///
    /// GET 请求的分页参数通常放在 URL 后面，例如：
    /// `/products?page=1&pageSize=10`
    var queryItems: [URLQueryItem] {
        switch self {
        case .list(let page, let pageSize):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            ]
        }
    }

    /// 请求头。
    ///
    /// `Accept: application/json` 表示希望服务器返回 JSON 格式数据。
    /// 如果后续接口需要 token，可以在 `NetworkClient` 或统一鉴权层里追加 Authorization。
    var headers: [String: String] {
        return [
            "Accept": "application/json"
        ]
    }

    /// 请求体。
    ///
    /// 商品列表是 GET 请求，参数放在 query 中，所以这里没有 body。
    var body: Data? {
        return nil
    }
}
