//
//  ApiResponse.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 真实业务接口的统一响应外壳。
///
/// 很多后端接口不会直接返回真正的数据，而是会包一层：
///
/// ```json
/// {
///     "code": 0,
///     "message": "success",
///     "data": ...
/// }
/// ```
///
/// - `code`：业务状态码，例如 `0` 表示业务成功。
/// - `message`：业务提示文案，例如 `success`、`登录已过期`。
/// - `data`：真正的业务数据，类型由泛型 `T` 决定。
///
/// 示例：
/// - `ApiResponse<Product>`：表示 `data` 是一个 `Product`。
/// - `ApiResponse<[Product]>`：表示 `data` 是一个 `[Product]` 数组。
/// - `ApiResponse<PageResponse<Product>>`：表示 `data` 是一个商品分页对象。
struct ApiResponse<T: Decodable>: Decodable {
    /// 业务状态码。
    ///
    /// 注意：这是业务层 code，不是 HTTP statusCode。
    /// HTTP 200 只代表通信成功，业务是否成功还要看这个 `code`。
    let code: Int

    /// 业务提示文案。
    ///
    /// 例如：`success`、`登录已过期`、`商品不存在`。
    let message: String

    /// 真正的业务数据。
    ///
    /// 写成可选类型，是因为业务失败时，后端经常会返回：
    ///
    /// ```json
    /// {
    ///     "code": 401,
    ///     "message": "登录已过期",
    ///     "data": null
    /// }
    /// ```
    ///
    /// 如果这里写成非可选 `T`，遇到 `data: null` 时会直接解码失败，
    /// 这样就无法正确区分“业务失败”和“JSON 格式错误”。
    let data: T?
}
