//
//  ProductEndpoint.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//
import Foundation

/// 商品模块的接口说明。
///
/// 当前接入 Supabase RPC：
/// POST /rest/v1/rpc/get_posts
///
/// 请求 body：
/// {
///   "p_page": 1,
///   "p_page_size": 10
/// }
///
/// 返回结构：
/// ApiResponse<PageResponse<Product>>
enum ProductEndpoint: Endpoint {

    /// Supabase anon public key。
    ///
    /// 你自己把下面占位符替换成真实 anon public key。
    /// 注意：这是学习项目直连 Supabase 的写法。
    private static let supabaseAnonKey = LocalConfig.supabaseAnonKey

    /// 商品列表接口。
    ///
    /// - page: 请求第几页。
    /// - pageSize: 每页请求多少条。
    case list(page: Int, pageSize: Int)

    /// 接口路径。
    var path: String {
        switch self {
        case .list:
            return "/rest/v1/rpc/get_posts"
        }
    }

    /// 请求方法。
    var method: HTTPMethod {
        switch self {
        case .list:
            return .post
        }
    }

    /// URL 查询参数。
    ///
    /// Supabase RPC 使用 POST body 传参，
    /// 所以这里不再拼 page / pageSize 到 URL 后面。
    var queryItems: [URLQueryItem] {
        return []
        
    }

    /// 请求头。
    ///
    /// Supabase REST / RPC 请求必须带 apikey。
    /// Authorization 使用同一个 anon public key。
    var headers: [String: String] {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "apikey": Self.supabaseAnonKey,
            "Authorization": "Bearer \(Self.supabaseAnonKey)"
        ]
    }

    /// 请求体。
    ///
    /// 参数名必须和 Supabase RPC 函数参数一致：
    /// - p_page
    /// - p_page_size
    var body: Data? {
        switch self {
        case .list(let page, let pageSize):
            let params: [String: Any] = [
                "p_page": page,
                "p_page_size": pageSize
            ]

            return try? JSONSerialization.data(
                withJSONObject: params,
                options: []
            )
        }
    }
}
