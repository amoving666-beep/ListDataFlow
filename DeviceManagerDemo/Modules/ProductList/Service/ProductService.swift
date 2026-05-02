//
//  ProductService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import Foundation

final class ProductService {
    
    /// 请求商品列表
    ///
    /// 返回值：URLSessionDataTask?
    ///
    /// 为什么要返回 task：
    /// - 以前这个方法只负责发请求，外部无法取消
    /// - 现在把 task 返回给 VC，VC 就可以在需要时 cancel
    /// - 例如：页面销毁、用户重新下拉刷新、旧请求不再需要时，都可以取消旧请求
    ///
    /// 为什么是可选：
    /// - 如果 URL 创建失败，请求根本不会发出去，也就没有 task 可以返回
    @discardableResult
    static func fetchList(page: Int,
                          limit: Int,
                          completion: @escaping (Result<[Product], Error>) -> Void) -> URLSessionDataTask? {
        
        // 第 1 关：创建 URL。
        // 如果 URL 字符串本身不合法，URL(string:) 会返回 nil。
        // 这时候请求还没有发出去，所以要回调 invalidURL。
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_page=\(page)&_limit=\(limit)") else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidURL))
            }
            
            // URL 创建失败，请求没有真正发出去，所以没有 URLSessionDataTask 可以返回。
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // 第 2 关：判断 URLSession / 系统网络层 error。
            // 例如：断网、超时、DNS 失败、服务器连不上。
            // 这里的 error 是系统给的原始 Error，要包进 requestFailed 里。
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.requestFailed(error)))
                }
                return
            }
            
            // 第 3 关：确认 response 是 HTTPURLResponse。
            // 因为只有 HTTPURLResponse 才有 statusCode。
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidResponse))
                }
                return
            }
            
            // 第 4 关：判断 HTTP 状态码是否成功。
            // 200...299 才表示 HTTP 层成功。
            // 例如 404、500 都会进入 invalidStatusCode。
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidStatusCode(httpResponse.statusCode)))
                }
                return
            }
            
            // 第 5 关：确认 data 存在。
            // 这里暂时不新增 noData case，今晚先用 invalidResponse 表示“响应不完整”。
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidResponse))
                }
                return
            }
            
            // 第 6 关：JSON 解码。
            // 网络已经成功，HTTP 状态码也成功，data 也存在。
            // 如果这里失败，说明是 JSON 结构和 Product 模型对不上。
            do {
                let list = try JSONDecoder().decode([Product].self, from: data)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(.success(list))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.decodingFailed(error)))
                }
            }
        }
        
        task.resume()
        
        // 把 task 返回给调用方。
        // 调用方可以保存这个 task，后续根据需要调用 task.cancel() 取消请求。
        return task
    }
    
}
// MARK: - Debug

private func debugPrintDataJSON(_ data: Data) {
    
do {
    let obj = try JSONSerialization.jsonObject(with: data, options: [])
    let prettyData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .fragmentsAllowed])

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



