//
//   MockProductService.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/6.
//

import Foundation

@testable import DeviceManagerDemo

/// 假的 ProductService。
///
/// 作用：
/// 单元测试时不真的请求网络，
/// 而是由测试用例提前设置 result，
/// 让它模拟成功或失败。
final class MockProductService: ProductServiceProtocol {

    

    /// 测试用例提前设置的返回结果。
    ///
    /// 比如：
    /// result = .success(PageResponse(list: [...], page: 1, pageSize: 10, total: 20))
    /// result = .failure(NetworkError.invalidResponse)
    var result: Result<PageResponse<Product>, NetworkError>?

    /// 记录 ViewModel 请求的是第几页。
    ///
    /// 后面测试 initial / refresh / loadMore 时，
    /// 可以用它判断 ViewModel 有没有请求正确页码。
    private(set) var requestedPage: Int?

    /// 记录 ViewModel 请求的每页数量。
    private(set) var requestedPageSize: Int?

    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        
        requestedPage = page
        requestedPageSize = pageSize

        if let result = result {
            completion(result)
        }

        /// Mock 不发真实网络请求，所以没有 URLSessionDataTask。
        return nil
    }

}
