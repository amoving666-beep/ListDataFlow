//
//  NetworkClient.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 通用网络客户端。
///
/// `NetworkClient` 负责项目里通用的网络请求流程：
/// 1. 根据 `Endpoint` 生成 `URLRequest`
/// 2. 使用 `URLSession` 发起请求
/// 3. 判断系统网络错误
/// 4. 判断 HTTP 响应和状态码
/// 5. 判断 data 是否存在
/// 6. 解码统一外壳 `ApiResponse<T>`
/// 7. 判断业务 code
/// 8. 成功时返回真正的业务数据 `T`
///
/// 注意：
/// `NetworkClient` 不负责 UI，不 reloadData，不弹窗，不跳登录页。
/// 它只负责把网络结果包装成 `Result<T, NetworkError>` 返回给上层。
final class NetworkClient {

    /// 当前练习用的基础域名。
    ///
    /// 后续如果接真实接口，只需要把这里换成真实 baseURL。
    /// 例如：`https://api.xxx.com`
    private let baseURL = "https://lgvajryebsdxjnvvgvsl.supabase.co"

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }()

    /// 发起一个通用网络请求。
    ///
    /// - Parameters:
    ///   - endpoint: 接口说明书，描述 path / method / query / headers / body。
    ///   - completion: 请求完成后的回调。成功返回真正的业务数据 `T`，失败返回 `NetworkError`。
    @discardableResult
    func request<T: Decodable>(
        endpoint: Endpoint,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) -> URLSessionDataTask? {
        let request: URLRequest

        do {
            request = try makeRequest(from: endpoint)
            
        } catch let error as NetworkError {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return nil
        } catch {
            DispatchQueue.main.async {
                completion(.failure(.requestFailed(error)))
            }
            return nil
        }

        let task = session.dataTask(with: request) { data, response, error in
            // 1. 判断 URLSession 系统错误，例如断网、超时、DNS 失败。
            if let error = error {
                DispatchQueue.main.async {
                   
                    if let urlError = error as? URLError,
                       urlError.code == .cancelled {
                        completion(.failure(NetworkError.cancelled))
                        return
                    }

                    completion(.failure(.requestFailed(error)))
                }
                return
            }

            // 2. 判断 response 是否是 HTTPURLResponse。
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }

            // 3. 登录态失效也可能直接体现在 HTTP statusCode = 401。
            if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    completion(.failure(.unauthorized(message: "登录已过期")))
                }
                return
            }

            // 4. 判断 HTTP 状态码是否正常。
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidStatusCode(httpResponse.statusCode)))
                }
                return
            }

            // 5. 判断 data 是否存在。
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            do {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(
                    withJSONObject: jsonObject,
                    options: [.prettyPrinted, .sortedKeys]
                   ),
                   let prettyJSONString = String(data: prettyData, encoding: .utf8) {
//                    print("""
//                    接口响应:
//                    method: \(request.httpMethod ?? "UNKNOWN")
//                    url: \(request.url?.absoluteString ?? "UNKNOWN")
//                    json:
//                    \(prettyJSONString)
//                    """)
                }
                
                // 6. 注意：真实业务接口不是直接解 T，而是先解统一外壳 ApiResponse<T>。
                let apiResponse = try JSONDecoder().decode(ApiResponse<T>.self, from: data)

                // 7. 业务 code = 401，也表示登录态失效。
                if apiResponse.code == 401 {
                    DispatchQueue.main.async {
                        completion(.failure(.unauthorized(message: apiResponse.message)))
                    }
                    return
                }

                // 8. 判断业务 code 是否成功。
                guard apiResponse.code == 0 else {
                    DispatchQueue.main.async {
                        completion(.failure(.businessFailed(
                            code: apiResponse.code,
                            message: apiResponse.message
                        )))
                    }
                    return
                }

                // 9. code 成功后，再取真正的 data。
                guard let realData = apiResponse.data else {
                    DispatchQueue.main.async {
                        completion(.failure(.noData))
                    }
                    return
                }

                // 10. 成功返回真正的业务数据 T，而不是 ApiResponse<T> 外壳。
                DispatchQueue.main.async {
                    completion(.success(realData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailed(error)))
                }
            }
        }

        task.resume()
        return task
    }

    /// 根据 Endpoint 生成 URLRequest。
    ///
    /// 这里统一处理：
    /// - baseURL + path
    /// - queryItems 参数编码
    /// - HTTP method
    /// - headers
    /// - body
    private func makeRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }

        components.path = endpoint.path
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = endpoint.body

        return request
    }
}
