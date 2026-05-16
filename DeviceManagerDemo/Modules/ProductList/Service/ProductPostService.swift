//
//  ProductPostService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

// MARK: - Protocol
protocol ProductPostServiceProtocol {
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        parameters: [String: Any],
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) -> URLSessionDataTask?
}

// MARK: - Service Implementation
final class ProductPostService: ProductPostServiceProtocol {
    
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        parameters: [String: Any],
        completion: @escaping (Result<[Product], NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        
        // 1. POST 请求的 URL 保持干净，参数不挂在外边
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidURL))
            }
            return nil
        }
        
        // 2. 建立可变的请求实体，并物理改造为 POST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. 把业务参数和分页参数打包整合
        var finalParameters = parameters
        finalParameters["page"] = page
        finalParameters["pageSize"] = pageSize
        
        // 4. 封箱，转二进制二进制 Data 并塞入 httpBody
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: finalParameters, options: [])
            request.httpBody = bodyData
        } catch {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.decodingFailed(error))) // 参数打包失败也归类为广义解析错误
            }
            return nil
        }
        
        // 5. 核心 dataTask 执行
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // --- 拦截异常的四道安全海关 ---
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.requestFailed(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidResponse))
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidStatusCode(httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            // 6. 成功拿到数据，开始解析
            do {
                let list = try JSONDecoder().decode([Product].self, from: data)
                
                DispatchQueue.main.async {
                    completion(.success(list))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.decodingFailed(error)))
                }
            }
        }
        
        task.resume()
        return task
    }
}
