//
//  ProductService.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import Foundation

final class ProductService {
    
        static func fetchList(page: Int,
                              limit: Int,
                              completion: @escaping (Result<[Product], Error>) -> Void) {
            
            guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_page=\(page)&_limit=\(limit)") else {
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                
                //如果请求过程本身出了错，就直接把失败结果回调出去，并结束。
                //也就是说，这时候连“正常响应数据”都别想了。请求本身已经挂了。
                /*
                 比如 没网 连接超时 域名错误 服务器连不上 请求过程异常
                 */
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                //虽然前面没有网络 error，但返回的数据 data 竟然是 nil，那也算失败。
                guard let data = data else {
                    //“data 是 nil，我手动包装成一个错误对象 error，再抛给外面。”
                    let error = NSError(domain: "ProductServiceError",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "data is nil"])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                // 1. 先打印接口原始 JSON
//                    debugPrintDataJSON(data)
                do {
                    //尝试把服务器返回的 JSON 数据，解析成 [Product] 然后装到 list 数组
            
                    let list = try JSONDecoder().decode([Product].self, from: data)
                    //main.asyncAfter(deadline: .now() + 3.0) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 2. 再打印解码后的模型 JSON
//                        debugPrintModelJSON(list)
                        
                        completion(.success(list))
                    }
                } catch {
                    //如果 try 失败，就会进 catch。
                    /*
                     失败原因可能是： JSON 格式不对 字段类型对不上 结构不匹配 你 model 写错了
                     */
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
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
