//
//  PageResponse.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 通用分页响应模型。
///
/// 真实业务里的列表接口通常不会只返回一个数组，还会返回分页信息，例如：
///
/// ```json
/// {
///     "list": [],
///     "page": 1,
///     "pageSize": 10,
///     "total": 100
/// }
/// ```
///
/// - `T`：表示列表里每一条数据的模型类型。
///
/// 示例：
/// - `PageResponse<Product>`：表示商品分页，`list` 的类型是 `[Product]`。
/// - `PageResponse<User>`：表示用户分页，`list` 的类型是 `[User]`。
struct PageResponse<T: Decodable>: Decodable {
    /// 当前页的数据列表。
    ///
    /// 如果是 `PageResponse<Product>`，这里就是 `[Product]`。
    let list: [T]

    /// 当前页码。
    ///
    /// 例如请求第 1 页，后端返回 `page = 1`。
    let page: Int

    /// 每页数量。
    ///
    /// 例如每页请求 10 条，后端返回 `pageSize = 10`。
    let pageSize: Int

    /// 服务端记录的总数据量。
    ///
    /// ViewModel 可以根据 `products.count < total` 判断是否还有更多数据，
    /// 比单纯依赖 `list.count < pageSize` 更接近真实业务分页。
    let total: Int
}
