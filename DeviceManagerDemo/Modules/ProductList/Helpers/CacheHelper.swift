//
//  CacheHelper.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/27.
//

import Foundation

enum CacheHelper {
    
    //保存缓存
    
    static func save<T: Codable>(_ value: T, key: String) {
        do{
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
        }catch{
            print("缓存保存失败：\(error.localizedDescription)")
        }
    }
    //加载缓存
    static func load<T: Codable>(key: String, as type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do{
            return try JSONDecoder().decode(T.self, from: data)
        }catch {
            print("缓存读取失败：\(error.localizedDescription)")
            return nil
        }
    }
        //清楚缓存
    static func clear(key: String) {
        UserDefaults.standard.removeObject(forKey: key)

    }
}
