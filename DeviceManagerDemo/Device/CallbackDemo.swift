//
//  CallbackDemo.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/17.
//

import Foundation

final class CallbackDemo {
    
    // 第 1 层：最上层，模拟 ViewModel 调用 Repository
    func start() {
        print("1. start 开始")
        
        fetchFromRepository { result in
            print("8. start 收到最终结果：\(result)")
        }
        
        print("2. start 继续往下执行，不等结果")
    }
    
    // 第 2 层：模拟 Repository
    func fetchFromRepository(completion: @escaping (String) -> Void) {
        print("3. Repository 开始")
        
        fetchFromService { serviceResult in
            print("6. Repository 收到 Service 结果：\(serviceResult)")
            
            let repositoryResult = "Repository 加工后的数据：\(serviceResult)"
            
            completion(repositoryResult)
        }
        
        print("4. Repository 方法结束，但结果还没回来")
    }
    
    // 第 3 层：模拟 Service / Network
    func fetchFromService(completion: @escaping (String) -> Void) {
        print("5. Service 开始模拟网络请求")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let networkData = "服务器返回的数据"
            completion(networkData)
        }
    }
}
