//
//  URLSessionNetworkClient.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// 基于 URLSession 的网络请求实现。
///
/// 这一层只负责通用网络请求，不关心 ListItem、分页、缓存、页面状态。
/// 它接收 Endpoint，拿到 URL 后发起请求，并把底层网络结果整理成 Result<Data, DataFlowNetworkError>。
final class URLSessionNetworkClient: NetworkClientProtocol {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    @discardableResult
    func request(
        endpoint: Endpoint,
        completion: @escaping (Result<Data, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask? {
        guard let url = endpoint.url else {
            DispatchQueue.main.async {
                completion(.failure(.invalidURL))
            }
            return nil
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.requestFailed(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidStatusCode(httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(data))
            }
        }
        
        task.resume()
        return task
    }
}
