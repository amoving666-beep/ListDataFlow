//
//  ListRepository.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// DataFlowAdvanced 模块的数据仓库实现。
///
/// Repository 负责把网络数据和缓存数据组合成统一的数据入口，
/// 上层的 ListViewModel 只依赖 ListRepositoryProtocol，
/// 不需要直接知道 ListService 和 CacheStore 的存在。
///
/// 当前阶段的策略：
/// - fetchList：从网络请求列表数据，请求成功后保存缓存。
/// - loadCachedList：读取本地缓存。
/// - clearCachedList：清除本地缓存。
final class ListRepository: ListRepositoryProtocol {
    
    //负责网络请求 + Data 解码成 [ListItem]
    private let service: ListServiceProtocol
    //负责本地缓存 save / load / remove
    private let cacheStore: CacheStoreProtocol
    private let cacheKey = "DataFlowAdvanced.ListItems"
    
    init(
        service: ListServiceProtocol = ListService(),
        cacheStore: CacheStoreProtocol = UserDefaultsCacheStore()
    ) {
        self.service = service
        self.cacheStore = cacheStore
    }
    
    @discardableResult
    func fetchList(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<[ListItem], DataFlowNetworkError>) -> Void
    ) -> URLSessionTask? {
        return service.fetchList(page: page, pageSize: pageSize) { [weak self] result in
            switch result {
            case .success(let items):
                self?.cacheStore.save(items, forKey: self?.cacheKey ?? "DataFlowAdvanced.ListItems")
                completion(.success(items))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func loadCachedList() -> [ListItem]? {
        cacheStore.load(forKey: cacheKey, as: [ListItem].self)
    }
    
    func clearCachedList() {
        cacheStore.remove(forKey: cacheKey)
    }
}
