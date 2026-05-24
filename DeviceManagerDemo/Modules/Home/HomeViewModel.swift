//
//  HomeViewModel.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/24.
//
import Foundation

/// HomeViewModel
///
/// 负责 Home 首页的多接口并发请求管理。
///
/// 注意：
/// 这里的 productList 只是首页聚合接口的一部分，
/// 用于学习“五接口并发请求”。
/// 正式商品列表分页、缓存、refresh、loadMore 仍然由 ProductListViewModel 管理。
final class HomeViewModel {
    
    // MARK: - Request Key
    
    enum RequestKey {
        case productList
        case userInfo
        case banner
        case recommendProducts
        case unreadCount
    }
    
    /// 首页聚合状态。
    ///
    /// productList 是主接口，决定首页主状态。
    /// 其他接口是副接口，只影响局部数据。
    enum HomeLoadState: Equatable {
        case idle
        case loading
        case content
        case partialContent(String)
        case failed(String)
    }
    
    // MARK: - Dependencies
    
    private let service: ProductServiceProtocol
    
    // MARK: - Request State
    
    private var taskMap: [RequestKey: URLSessionDataTask] = [:]
    private var requestIDMap: [RequestKey: UUID] = [:]
    
    /// 首页聚合请求 ID。
    ///
    /// loadHomeData() 每次都会生成新的 batchRequestID。
    /// group.notify 回来时，如果不是当前批次，就丢弃旧结果。
    private var batchRequestID = UUID()
    
    private(set) var loadState: HomeLoadState = .idle
    
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
    
    /// 首页聚合状态发生变化。
    ///
    /// HomeVC 可以用它展示 loading / 部分成功 / 主接口失败。
    var onHomeStateChanged: ((HomeLoadState) -> Void)?
    
    // MARK: - Init
    
    init(service: ProductServiceProtocol = ProductService()) {
        self.service = service
    }
    
    deinit {
        cancelAllRequests()
    }
    
    // MARK: - Public Methods
    
    /// 加载首页五个接口。
    ///
    /// 当前用于学习：
    /// 1. 多接口并发
    /// 2. DispatchGroup 等待五个请求完成
    /// 3. taskMap 独立管理 task
    /// 4. requestIDMap 防旧回调污染
    /// 5. 主接口 / 副接口失败策略分离
    func loadHomeData() {
        cancelAllRequests()
        
        let currentBatchID = UUID()
        batchRequestID = currentBatchID
        
        updateLoadState(.loading)
        
        let group = DispatchGroup()
        
        var productResult: Result<PageResponse<Product>, NetworkError>?
        var userInfoResult: Result<UserInfo, NetworkError>?
        var bannerResult: Result<[Banner], NetworkError>?
        var recommendResult: Result<[Product], NetworkError>?
        var unreadResult: Result<UnreadCount, NetworkError>?
        
        group.enter()
        startTrackedRequest(
            key: .productList,
            request: { [service] completion in
                service.fetchList(page: 1, pageSize: 10, completion: completion)
            },
            completion: { result in
                productResult = result
                group.leave()
            }
        )
        
        group.enter()
        startTrackedRequest(
            key: .userInfo,
            request: service.fetchUserInfo,
            completion: { result in
                userInfoResult = result
                group.leave()
            }
        )
        
        group.enter()
        startTrackedRequest(
            key: .banner,
            request: service.fetchBanners,
            completion: { result in
                bannerResult = result
                group.leave()
            }
        )
        
        group.enter()
        startTrackedRequest(
            key: .recommendProducts,
            request: service.fetchRecommendProducts,
            completion: { result in
                recommendResult = result
                group.leave()
            }
        )
        
        group.enter()
        startTrackedRequest(
            key: .unreadCount,
            request: service.fetchUnreadCount,
            completion: { result in
                unreadResult = result
                group.leave()
            }
        )
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            guard self.batchRequestID == currentBatchID else {
                print("Home 丢弃旧批次请求回调")
                return
            }
            
            self.mergeHomeResults(
                productResult: productResult,
                userInfoResult: userInfoResult,
                bannerResult: bannerResult,
                recommendResult: recommendResult,
                unreadResult: unreadResult
            )
        }
    }
    
    /// 取消所有首页请求。
    func cancelAllRequests() {
        taskMap.values.forEach { task in
            task.cancel()
        }
        
        taskMap.removeAll()
        batchRequestID = UUID()
        
        RequestKey.allCasesForHome.forEach { key in
            requestIDMap[key] = UUID()
        }
    }
    
    // MARK: - Merge Strategy
    
    /// 合并首页五个请求结果。
    ///
    /// 规则：
    /// productList 是主接口。
    /// - 主接口成功：首页可以 content。
    /// - 主接口失败且没有旧数据：首页 failed。
    /// - 主接口失败但已有旧数据：首页 partialContent，保留旧数据。
    ///
    /// 其他接口是副接口。
    /// - 成功：更新局部数据。
    /// - 失败：局部降级，不覆盖首页主状态。
    private func mergeHomeResults(
        productResult: Result<PageResponse<Product>, NetworkError>?,
        userInfoResult: Result<UserInfo, NetworkError>?,
        bannerResult: Result<[Banner], NetworkError>?,
        recommendResult: Result<[Product], NetworkError>?,
        unreadResult: Result<UnreadCount, NetworkError>?
    ) {
        var localFailedMessages: [String] = []
        
        switch productResult {
        case .success(let pageData):
            homeProducts = pageData.list
            print("Home productList 成功，数量: \(pageData.list.count)")
            
        case .failure(let error):
            print("Home productList 失败: \(error)")
            
            if homeProducts.isEmpty {
                userInfo = nil
                banners = []
                recommendProducts = []
                unreadCount = 0
                updateLoadState(.failed("商品列表加载失败"))
                onHomeDataChanged?()
                return
            } else {
                localFailedMessages.append("商品列表刷新失败，已保留旧数据")
            }
            
        case .none:
            if homeProducts.isEmpty {
                updateLoadState(.failed("商品列表无返回"))
                onHomeDataChanged?()
                return
            } else {
                localFailedMessages.append("商品列表无返回，已保留旧数据")
            }
        }
        
        switch userInfoResult {
        case .success(let userInfo):
            self.userInfo = userInfo
            print("Home userInfo 成功: \(userInfo.name)")
            
        case .failure(let error):
            self.userInfo = nil
            localFailedMessages.append("用户信息加载失败")
            print("Home userInfo 失败: \(error)")
            
        case .none:
            self.userInfo = nil
            localFailedMessages.append("用户信息无返回")
        }
        
        switch bannerResult {
        case .success(let banners):
            self.banners = banners
            print("Home banner 成功，数量: \(banners.count)")
            
        case .failure(let error):
            self.banners = []
            localFailedMessages.append("Banner 加载失败")
            print("Home banner 失败: \(error)")
            
        case .none:
            self.banners = []
            localFailedMessages.append("Banner 无返回")
        }
        
        switch recommendResult {
        case .success(let products):
            self.recommendProducts = products
            print("Home recommendProducts 成功，数量: \(products.count)")
            
        case .failure(let error):
            self.recommendProducts = []
            localFailedMessages.append("推荐商品加载失败")
            print("Home recommendProducts 失败: \(error)")
            
        case .none:
            self.recommendProducts = []
            localFailedMessages.append("推荐商品无返回")
        }
        
        switch unreadResult {
        case .success(let unread):
            unreadCount = unread.count
            print("Home unreadCount 成功: \(unread.count)")
            
        case .failure(let error):
            unreadCount = 0
            localFailedMessages.append("未读数加载失败")
            print("Home unreadCount 失败: \(error)")
            
        case .none:
            unreadCount = 0
            localFailedMessages.append("未读数无返回")
        }
        
        if localFailedMessages.isEmpty {
            updateLoadState(.content)
        } else {
            updateLoadState(.partialContent(localFailedMessages.joined(separator: "；")))
        }
        
        onHomeDataChanged?()
    }
    
    // MARK: - Request Lifecycle
    
    /// 带 task / requestID 保护的底层请求方法。
    ///
    /// 只负责：
    /// 1. 取消同 key 旧请求
    /// 2. 生成 requestID
    /// 3. 丢弃旧回调
    /// 4. 清理 taskMap
    ///
    /// 它不直接更新 UI，适合 DispatchGroup 聚合场景。
    private func startTrackedRequest<T>(
        key: RequestKey,
        request: (@escaping (Result<T, NetworkError>) -> Void) -> URLSessionDataTask?,
        completion: @escaping (Result<T, NetworkError>) -> Void
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
            completion(result)
        }
        
        taskMap[key] = task
    }
    
    private func updateLoadState(_ state: HomeLoadState) {
        loadState = state
        onHomeStateChanged?(state)
    }
}

private extension HomeViewModel.RequestKey {
    static var allCasesForHome: [HomeViewModel.RequestKey] {
        return [
            .productList,
            .userInfo,
            .banner,
            .recommendProducts,
            .unreadCount
        ]
    }
}
