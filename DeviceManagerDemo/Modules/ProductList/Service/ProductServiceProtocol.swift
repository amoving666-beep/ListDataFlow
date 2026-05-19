//
//  ProductServiceProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/6.
//

import Foundation

/// ProductServiceProtocol
///
/// 作用：
/// 定义“列表数据请求能力”的接口。
///
/// 注意：
/// ViewModel 以后不直接依赖 ProductService 这个具体类，
/// 而是依赖这个 protocol。
///
/// 好处：
/// 1. 真实运行时可以传 ProductService
/// 2. 后续测试时可以传 MockProductService
/// 3. ViewModel 不关心数据到底来自真实网络还是假数据
protocol ProductServiceProtocol {
    
    /// 请求商品列表
    ///
    /// - Parameters:
    ///   - page: 当前请求第几页
    ///   - pageSize: 每页请求多少条
    ///   - completion: 请求完成后的回调，成功返回 [Product]，失败返回 NetworkError
    ///
    /// - Returns:
    ///   返回 URLSessionDataTask，方便 ViewModel 保存 currentTask，
    ///   后续可以 cancel 取消旧请求。
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask?
}
