//
//  CacheStoreProtocol.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//
import Foundation

/// DataFlowAdvanced 模块的缓存协议。
///
/// CacheStoreProtocol 只定义缓存应该具备的能力，
/// 不绑定具体实现是 UserDefaults、文件、SQLite 还是 CoreData。
///
/// 这样 Repository 依赖缓存协议，而不是直接依赖 UserDefaults。
/// 后续单元测试时，也可以替换成 MockCacheStore。
protocol CacheStoreProtocol {
    
    /// 保存 Codable 数据。
    ///
    /// - Parameters:
    ///   - value: 要缓存的数据。
    ///   - key: 缓存 key。
    func save<T: Codable>(_ value: T, forKey key: String)
    
    /// 读取 Codable 数据。
    ///
    /// - Parameters:
    ///   - key: 缓存 key。
    ///   - type: 要解码的数据类型。
    /// - Returns: 如果读取和解码成功，返回对应数据；否则返回 nil。
    func load<T: Codable>(forKey key: String, as type: T.Type) -> T?
    
    /// 清除指定 key 的缓存。
    ///
    /// - Parameter key: 缓存 key。
    func remove(forKey key: String)
}
