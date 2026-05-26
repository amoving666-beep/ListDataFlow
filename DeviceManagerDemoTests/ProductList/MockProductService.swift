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
    
    func fetchUserInfo(completion: @escaping (Result<DeviceManagerDemo.UserInfo, DeviceManagerDemo.NetworkError>) -> Void) -> URLSessionDataTask? {
        return nil
    }
    
    func fetchBanners(completion: @escaping (Result<[DeviceManagerDemo.Banner], DeviceManagerDemo.NetworkError>) -> Void) -> URLSessionDataTask? {
        return nil
    }
    
    func fetchRecommendProducts(completion: @escaping (Result<[DeviceManagerDemo.Product], DeviceManagerDemo.NetworkError>) -> Void) -> URLSessionDataTask? {
        return nil
    }
    
    func fetchUnreadCount(completion: @escaping (Result<DeviceManagerDemo.UnreadCount, DeviceManagerDemo.NetworkError>) -> Void) -> URLSessionDataTask? {
        return nil
    }
    

    

    /// 测试用例提前设置的返回结果。
    ///
    /// 比如：
    /// result = .success(PageResponse(list: [...], page: 1, pageSize: 10, total: 20))
    /// result = .failure(NetworkError.invalidResponse)
    var result: Result<PageResponse<Product>, NetworkError>?

    /// 记录 ViewModel 请求的是第几页。
    private(set) var requestedPage: Int?

    /// 记录 ViewModel 请求的每页数量。
    private(set) var requestedPageSize: Int?

    //
    var shouldDelayCompletion = false
    var pendingCompletion: ((Result<PageResponse<Product>, NetworkError>) -> Void)?

    /// 清空请求记录，方便测试判断下一次 loadData 是否真的发起请求。
    func resetRequestRecord() {
        requestedPage = nil
        requestedPageSize = nil
    }

    /// 手动触发被延迟保存的 completion。
    func completePendingRequest() {
        guard let result = result else { return }
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?(result)
    }
    
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        
        requestedPage = page
        requestedPageSize = pageSize

        if shouldDelayCompletion {
            pendingCompletion = completion
            return nil
        }

        if let result = result {
            completion(result)
        }

        /// Mock 不发真实网络请求，所以没有 URLSessionDataTask。
        return nil
    }

}
