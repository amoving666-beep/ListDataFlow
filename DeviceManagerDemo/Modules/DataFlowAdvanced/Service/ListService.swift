//
//  ListService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// DataFlowAdvanced 模块的列表业务服务实现。
///
/// 职责边界：
/// - NetworkClient 负责发请求并返回原始 Data。
/// - ListService 负责把接口返回的 Data 解码成业务需要的 `[ListItem]`。
/// - ListService 不负责缓存，不负责页面状态，也不负责 tableView 刷新。
final class ListService: ListServiceProtocol {
    
    private let networkClient: NetworkClientProtocol
    
    init(networkClient: NetworkClientProtocol = URLSessionNetworkClient()) {
        self.networkClient = networkClient
    }
    
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<[ListItem], DataFlowNetworkError>) -> Void
    ) -> URLSessionTask? {
        let endpoint = Endpoint.get(
            "https://jsonplaceholder.typicode.com/posts",
            queryItems: [
                URLQueryItem(name: "_page", value: "\(page)"),
                URLQueryItem(name: "_limit", value: "\(pageSize)")
            ]
        )
        
        let task = networkClient.request(
            endpoint: endpoint,
            responseType: [PostResponse].self,
            completion: { result in
                switch result {
                case .success(let responses):
                    let items = responses.map { response in
                        ListItem(
                            id: response.id,
                            title: response.title,
                            subtitle: response.body
                        )
                    }
                    completion(.success(items))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
        
        return task
    }
}

private extension ListService {
    
    /// jsonplaceholder posts 接口的原始响应模型。
    ///
    /// 接口字段是 userId / id / title / body。
    /// 这里不直接把它暴露给 ViewModel，
    /// 而是在 Service 内部转换成通用的 ListItem。
    struct PostResponse: Decodable {
        let userId: Int
        let id: Int
        let title: String
        let body: String
    }
}
