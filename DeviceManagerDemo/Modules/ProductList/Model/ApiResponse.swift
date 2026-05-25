//
//  ApiResponse.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 真实业务接口的统一响应外壳。
///
struct ApiResponse<T: Decodable>: Decodable {
    /// 业务状态码。
    let code: Int

    let message: String

    let data: T?
}
