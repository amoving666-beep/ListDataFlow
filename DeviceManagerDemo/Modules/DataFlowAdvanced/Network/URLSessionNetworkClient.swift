//
//  URLSessionNetworkClient.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// 基于 URLSession 的网络请求实现。
///
/// 这一层只负责通用网络请求，不关心 ListItem、PostResponse、分页、缓存、页面状态。
///
/// 当前支持三类能力：
/// 1. requestData：普通请求，返回原始 Data。
/// 2. request<T: Decodable>：普通请求，并泛型解码成调用方指定的 Model。
/// 3. upload<T: Decodable>：multipart/form-data 文件上传，并泛型解码响应 Model。
final class URLSessionNetworkClient: NetworkClientProtocol {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }
    
    @discardableResult
    func requestData(
        endpoint: Endpoint,
        completion: @escaping (Result<Data, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask? {
        guard let request = makeURLRequest(from: endpoint) else {
            DispatchQueue.main.async {
                completion(.failure(.invalidURL))
            }
            return nil
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            self.handleDataResponse(
                data: data,
                response: response,
                error: error,
                completion: completion
            )
        }
        
        task.resume()
        return task
    }
    
    @discardableResult
    func request<T: Decodable>(
        endpoint: Endpoint,
        responseType: T.Type,
        completion: @escaping (Result<T, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask? {
        return requestData(endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try self.decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    @discardableResult
    func upload<T: Decodable>(
        endpoint: Endpoint,
        fileData: Data,
        fieldName: String,
        fileName: String,
        mimeType: String,
        responseType: T.Type,
        completion: @escaping (Result<T, DataFlowNetworkError>) -> Void
    ) -> URLSessionTask? {
        guard let url = endpoint.url else {
            DispatchQueue.main.async {
                completion(.failure(.invalidURL))
            }
            return nil
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = makeMultipartBody(
            fileData: fileData,
            fieldName: fieldName,
            fileName: fileName,
            mimeType: mimeType,
            boundary: boundary
        )
        
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        
        let task = session.dataTask(with: request) { data, response, error in
            self.handleDataResponse(data: data, response: response, error: error) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    do {
                        let decodedObject = try self.decoder.decode(T.self, from: data)
                        completion(.success(decodedObject))
                    } catch {
                        completion(.failure(.decodingFailed(error)))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
        return task
    }
    
    private func makeURLRequest(from endpoint: Endpoint) -> URLRequest? {
        guard let url = endpoint.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func handleDataResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<Data, DataFlowNetworkError>) -> Void
    ) {
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
    
    private func makeMultipartBody(
        fileData: Data,
        fieldName: String,
        fileName: String,
        mimeType: String,
        boundary: String
    ) -> Data {
        var body = Data()
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
}

private extension Data {
    
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        append(data)
    }
}
