//
//  NetworkError.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/28.
//

import Foundation

enum NetworkError: Error {

    /// URL 创建失败。
    case invalidURL
    
    ///取消请求
    case cancelled
    
    ///系统手机断网、超时、DNS 解析失败、服务器无法连接
    case requestFailed(Error)

    /// response 不是 HTTPURLResponse。
    case invalidResponse

    /// HTTP 状态码失败。
    ///  statusCode 不在 200...299 范围内。
    case invalidStatusCode(Int)

    /// 返回 data 为空。不是服务器返回空 list

    case noData

    /// JSON 解码失败。
    case decodingFailed(Error)

    /// 业务失败
    case businessFailed(code: Int, message: String)

    /// 登录态失效 / 未授权。
    case unauthorized(message: String)
}
