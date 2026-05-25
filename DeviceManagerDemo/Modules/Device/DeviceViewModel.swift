//
//  DeviceViewModel.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/24.
//

import Foundation

final class DeviceViewModel {
    
    // MARK: - Request Key
    
    enum RequestKey {
        case productList
        case userInfo
        case banner
        case recommendProducts
        case unreadCount
    }
    
    // MARK: - Dependencies
    
    private let service: ProductServiceProtocol
    
    // MARK: - Request State
    
    private var taskMap: [RequestKey: URLSessionDataTask] = [:]
    private var requestIDMap: [RequestKey: UUID] = [:]
    
    // MARK: - Data
    
    /// 首页商品列表数据。
    ///
    /// 这里只用于首页聚合展示或调试，
    /// 不参与 ProductListViewController 的分页主链路。
    private(set) var homeProducts: [Product] = []
    
    /// 用户信息。
    private(set) var userInfo: UserInfo?
    
    /// Banner 数据。
    private(set) var banners: [Banner] = []
    
    /// 推荐商品。
    private(set) var recommendProducts: [Product] = []
    
    /// 未读消息数。
    private(set) var unreadCount: Int = 0
    
    // MARK: - Output
    
    /// 首页数据发生变化。
    ///
    /// HomeVC 可以在这里刷新 Header 或局部 UI。
    var onHomeDataChanged: (() -> Void)?
    
    // MARK: - Init
    
    init(service: ProductServiceProtocol = ProductService()) {
        self.service = service
    }
    
    deinit {
        cancelAllRequests()
    }
    
    // MARK: - Public Methods
    
    /// 加载首页五个接口。
    func loadHomeData() {
        loadProductList()
        loadUserInfo()
        loadBanners()
        loadRecommendProducts()
        loadUnreadCount()
    }
    
    /// 加载首页辅助接口。
    ///
    /// 这个方法不请求 productList，适合 HomeVC 只想刷新用户、Banner、推荐、未读数时使用。
    func loadAuxiliaryData() {
        loadUserInfo()
        loadBanners()
        loadRecommendProducts()
        loadUnreadCount()
    }
    
    /// 取消所有首页请求。
    func cancelAllRequests() {
        taskMap.values.forEach { task in
            task.cancel()
        }
        
        taskMap.removeAll()
        
        RequestKey.allCasesForHome.forEach { key in
            requestIDMap[key] = UUID()
        }
    }
    
    // MARK: - Request Methods
    
    private func loadProductList() {
        startRequest(
            key: .productList,
            request: { [service] completion in
                service.fetchList(page: 1, pageSize: 10, completion: completion)
            },
            success: { [weak self] pageData in
                self?.homeProducts = pageData.list
                print("Home productList 成功，数量: \(pageData.list.count)")
            },
            failure: { error in
                print("Home productList 失败: \(error)")
            }
        )
    }
    
    private func loadUserInfo() {
        startRequest(
            key: .userInfo,
            request: service.fetchUserInfo,
            success: { [weak self] userInfo in
                self?.userInfo = userInfo
                print("Home userInfo 成功: \(userInfo.name)")
            },
            failure: { error in
                print("Home userInfo 失败: \(error)")
            }
        )
    }
    
    private func loadBanners() {
        startRequest(
            key: .banner,
            request: service.fetchBanners,
            success: { [weak self] banners in
                self?.banners = banners
                print("Home banner 成功，数量: \(banners.count)")
            },
            failure: { error in
                print("Home banner 失败: \(error)")
            }
        )
    }
    
    private func loadRecommendProducts() {
        startRequest(
            key: .recommendProducts,
            request: service.fetchRecommendProducts,
            success: { [weak self] products in
                self?.recommendProducts = products
                print("Home recommendProducts 成功，数量: \(products.count)")
            },
            failure: { error in
                print("Home recommendProducts 失败: \(error)")
            }
        )
    }
    
    private func loadUnreadCount() {
        startRequest(
            key: .unreadCount,
            request: service.fetchUnreadCount,
            success: { [weak self] unread in
                self?.unreadCount = unread.count
                print("Home unreadCount 成功: \(unread.count)")
            },
            failure: { error in
                print("Home unreadCount 失败: \(error)")
            }
        )
    }
    
    // MARK: - Request Lifecycle
    
    /// 通用请求启动方法。
    ///
    /// 只负责请求生命周期管理，不关心具体业务数据写到哪里。
    private func startRequest<T>(
        key: RequestKey,
        request: (@escaping (Result<T, NetworkError>) -> Void) -> URLSessionDataTask?,
        success: @escaping (T) -> Void,
        failure: @escaping (NetworkError) -> Void
    ) {
        taskMap[key]?.cancel()
        
        let requestID = UUID()
        requestIDMap[key] = requestID
        
        let task = request { [weak self] result in
            guard let self = self else { return }
            
            guard requestID == self.requestIDMap[key] else {
                print("Home 丢弃旧请求回调 key: \(key)")
                return
            }
            
            self.taskMap[key] = nil
            
            switch result {
            case .success(let value):
                success(value)
                
            case .failure(let error):
                failure(error)
            }
            
            self.onHomeDataChanged?()
        }
        
        taskMap[key] = task
    }
}

private extension DeviceViewModel.RequestKey {
    static var allCasesForHome: [DeviceViewModel.RequestKey] {
        return [
            .productList,
            .userInfo,
            .banner,
            .recommendProducts,
            .unreadCount
        ]
    }
}
