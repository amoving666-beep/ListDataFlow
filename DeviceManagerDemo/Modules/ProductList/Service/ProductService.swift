//
//  ProductService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import Foundation

final class ProductService: ProductServiceProtocol {
    
    @discardableResult
    func fetchList(page: Int, pageSize: Int, completion: @escaping (Result<PageResponse<Product>, NetworkError>) -> Void) -> URLSessionDataTask? {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_page=\(page)&_limit=\(pageSize)") else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidURL))
            }
            
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
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
            
            do {
                let list = try JSONDecoder().decode([Product].self, from: data)

                // jsonplaceholder 当前返回的是裸数组 `[Product]`，不是我们后面真实业务接口里的：
                // `ApiResponse<PageResponse<Product>>`。
                //
                // 但 ProductServiceProtocol 现在已经升级为返回 `PageResponse<Product>`，
                // 所以这里先把裸数组包成分页对象，保证旧接口还能继续跑，
                // 同时让 ViewModel 按真实分页结构继续改造。
                //
                // jsonplaceholder 会在响应头里返回 `x-total-count`，可以用来表示总数量。
                // 如果取不到，就先用当前 list.count 兜底。
                let totalString = httpResponse.value(forHTTPHeaderField: "x-total-count")
                let total = Int(totalString ?? "") ?? list.count

                let pageData = PageResponse(
                    list: list,
                    page: page,
                    pageSize: pageSize,
                    total: total
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(.success(pageData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.decodingFailed(error)))
                }
            }
        }
        
        task.resume()
        
        // 调用方会持有 task，用于刷新或页面销毁时取消请求。
        return task
    }
}
    
// MARK: - Debug

private func debugPrintDataJSON(_ data: Data) {
    do {
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(
            withJSONObject: obj,
            options: [.prettyPrinted, .fragmentsAllowed]
        )

        if let prettyString = String(data: prettyData, encoding: .utf8) {
            print("===== 原始 JSON =====")
            print(prettyString)
        }
    } catch {
        print("JSON 格式化失败: \(error)")
    }
}

private func debugPrintModelJSON<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

    do {
        let data = try encoder.encode(value)
        if let jsonString = String(data: data, encoding: .utf8) {
            print("===== 模型转 JSON =====")
            print(jsonString)
        }
    } catch {
        print("模型转 JSON 失败: \(error)")
    }
}


