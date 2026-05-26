//
//  ControlledMockProductService.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/24.
//

import Foundation

@testable import DeviceManagerDemo

final class ControlledMockProductService: ProductServiceProtocol {
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
    
    
    struct PendingRequest {
        let page: Int
        let pageSize: Int
        let completion: (Result<PageResponse<Product>, NetworkError>) -> Void
    }
    
    private(set) var pendingRequests: [PendingRequest] = []
    
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        
        pendingRequests.append(
            PendingRequest(
                page: page,
                pageSize: pageSize,
                completion: completion
            )
        )
        
        return nil
    }
    
    func completeRequest(
        at index: Int,
        with result: Result<PageResponse<Product>, NetworkError>
    ) {
        let request = pendingRequests[index]
        request.completion(result)
    }
}
