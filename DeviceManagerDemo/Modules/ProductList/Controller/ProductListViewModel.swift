import Foundation

final class ProductListViewModel {

    // MARK: - Types

    enum ViewState {
        case loading
        case content
        case empty(String)
        case error(String)
    }

    /// FooterState 只管底部加载区，不表达主页面状态。
    enum FooterState {
        case hidden
        case loadingMore
        case noMoreData
    }

    enum LoadMode {
        case initial
        case refresh
        case loadMore
    }

    private enum LoadState {
        case idle
        case initialLoading
        case refreshing
        case loadingMore
    }

    enum RequestKey {
        case productList
        case userInfo
        case banner
        case recommendProducts
        case unreadCount
    }
    
    // MARK: - State

    private(set) var products: [Product] = []

    /// 用户信息。
    private(set) var userInfo: UserInfo?

    /// Banner 数据。
    private(set) var banners: [Banner] = []

    /// 推荐商品。
    private(set) var recommendProducts: [Product] = []

    /// 未读消息数。
    private(set) var unreadCount: Int = 0

    private var currentPage: Int = 1
    private let pageSize: Int = 10
    private var loadState: LoadState = .idle
    
    private var taskMap: [RequestKey: URLSessionDataTask] = [:]
    private var requestIDMap: [RequestKey: UUID] = [:]
    
    private var hasMoreData: Bool = true
    private let cacheKey = "ProductListCacheKey"

    /// ViewModel 依赖协议而不是具体网络实现，便于测试注入 Mock。
    private let service: ProductServiceProtocol
    
    init(service: ProductServiceProtocol = ProductService()) {

        self.service = service

    }
    
    /// 暴露给 VC 的分页边界，避免滚动层直接依赖内部状态机。
    var canLoadMore: Bool {
        return loadState == .idle && hasMoreData
    }

    // MARK: - Outputs

    var onProductsChanged: (([Product]) -> Void)?

    var onViewStateChanged: ((ViewState) -> Void)?

    var onFooterStateChanged: ((FooterState) -> Void)?

    /// 并发 Demo 数据更新回调。
    ///
    /// 当前先不接复杂 UI，
    /// 这里只用于观察五个接口并发返回结果。
    var onDemoDataChanged: (() -> Void)?

    /// 通知 VC：本次真实网络请求已经成功刷新列表，
    /// 可以检查内容高度是否不足一屏，必要时自动补一次 loadMore。
    ///
    /// 注意：
    /// loadCache / clearCache 不能触发这个回调，
    /// 否则缓存数据或清空后的空列表会误触发 page 2。
    var onCanCheckAutoLoadMore: (() -> Void)?

    // MARK: - Public Methods

    func loadCache() {
        guard let cacheList = CacheHelper.load(key: cacheKey, as: [Product].self) else {
            onViewStateChanged?(.empty("暂无数据"))
            onFooterStateChanged?(.hidden)
            return
        }

        products = cacheList
        onProductsChanged?(products)
        onViewStateChanged?(makeViewStateForCurrentList())
        onFooterStateChanged?(makeFooterStateForCurrentList())
        print("读取缓存成功，缓存条数：\(cacheList.count)")
    }

    func clearCache() {
        CacheHelper.clear(key: cacheKey)
        products.removeAll()
        currentPage = 1
        hasMoreData = false

        onProductsChanged?(products)
        onViewStateChanged?(.empty("暂无数据"))
        onFooterStateChanged?(.hidden)
        print("缓存已删除")
    }

    func printCacheInfo() {
        guard let cacheList = CacheHelper.load(key: cacheKey, as: [Product].self) else {
            print("无缓存")
            return
        }

        print("读取缓存成功，缓存条数：\(cacheList.count)")
    }

    func loadData(mode: LoadMode) {
        prepareForNewRequestIfNeeded(mode: mode)
        
        guard canLoadData(mode: mode) else {
            return
        }

        beginLoading(mode: mode)

        let targetPage = makeTargetPage(mode: mode)

        /// requestID 用于防止旧请求回调覆盖新请求结果。
        ///
        /// 多请求版本不再使用单个 currentRequestID，
        /// 而是给每个 RequestKey 单独保存一个 requestID。
        let requestKey = RequestKey.productList
        let requestID = UUID()
        requestIDMap[requestKey] = requestID

        let task = service.fetchList(page: targetPage, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.requestIDMap[requestKey] else {
                print("丢弃旧商品列表请求回调 requestID: \(requestID), currentRequestID: \(String(describing: self.requestIDMap[requestKey]))")
                return
            }

            self.taskMap[requestKey] = nil
            self.finishLoading()

            switch result {
            case .success(let pageData):
                self.handleLoadSuccess(pageData, mode: mode, targetPage: targetPage)

            case .failure(let error):
                self.handleLoadFailure(error)
            }
        }

        taskMap[requestKey] = task
    }

    private func prepareForNewRequestIfNeeded(mode: LoadMode) {
        /// refresh 代表用户主动拉取第一页，可以取消旧请求；loadMore 是分页追加，必须串行处理。
        guard mode == .refresh, loadState != .idle else {
            return
        }

        taskMap[.productList]?.cancel()
        taskMap[.productList] = nil
        requestIDMap[.productList] = UUID()
        loadState = .idle
        onFooterStateChanged?(makeFooterStateForCurrentList())

        print("下拉刷新触发：取消旧请求，准备重新请求第一页")
    }
    
    @discardableResult
    func updateProduct(_ newProduct: Product) -> Int? {
        guard let index = products.firstIndex(where: { $0.id == newProduct.id }) else {
            print("保存失败：列表中找不到 id = \(newProduct.id) 的数据")
            return nil
        }

        products[index] = newProduct
        saveCache()
        onProductsChanged?(products)
        onViewStateChanged?(makeViewStateForCurrentList())
        return index
    }

    func cancelCurrentTask() {
        taskMap[.productList]?.cancel()
        taskMap[.productList] = nil
        requestIDMap[.productList] = UUID()
    }

    // MARK: - Concurrent Request Demo

    /// 五接口并发请求 Demo。
    ///
    /// 当前目标：
    /// 1. 验证多个请求可以同时进行
    /// 2. 验证 taskMap 不会互相覆盖
    /// 3. 验证 requestIDMap 不会互相污染
    /// 4. 验证副接口失败不影响主接口
    ///
    /// 注意：
    /// 这里暂时不接正式 UI，
    /// 主要用于学习并发请求管理。
    func loadHomeDataForDemo() {
        loadProductListForDemo()
        loadUserInfoForDemo()
        loadBannersForDemo()
        loadRecommendProductsForDemo()
        loadUnreadCountForDemo()
    }

    private func loadProductListForDemo() {
        let requestKey = RequestKey.productList

        taskMap[requestKey]?.cancel()

        let requestID = UUID()
        requestIDMap[requestKey] = requestID

        let task = service.fetchList(page: 1, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.requestIDMap[requestKey] else {
                print("丢弃旧 productList 回调")
                return
            }

            self.taskMap[requestKey] = nil

            switch result {
            case .success(let pageData):
                self.products = pageData.list
                self.currentPage = pageData.page
                self.hasMoreData = self.products.count < pageData.total

                print("productList 成功，数量: \(pageData.list.count)")

            case .failure(let error):
                print("productList 失败: \(error)")
            }

            self.onDemoDataChanged?()
        }

        taskMap[requestKey] = task
    }

    private func loadUserInfoForDemo() {
        let requestKey = RequestKey.userInfo

        taskMap[requestKey]?.cancel()

        let requestID = UUID()
        requestIDMap[requestKey] = requestID

        let task = service.fetchUserInfo { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.requestIDMap[requestKey] else {
                print("丢弃旧 userInfo 回调")
                return
            }

            self.taskMap[requestKey] = nil

            switch result {
            case .success(let userInfo):
                self.userInfo = userInfo
                print("userInfo 成功: \(userInfo.name)")

            case .failure(let error):
                print("userInfo 失败: \(error)")
            }

            self.onDemoDataChanged?()
        }

        taskMap[requestKey] = task
    }

    private func loadBannersForDemo() {
        let requestKey = RequestKey.banner

        taskMap[requestKey]?.cancel()

        let requestID = UUID()
        requestIDMap[requestKey] = requestID

        let task = service.fetchBanners { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.requestIDMap[requestKey] else {
                print("丢弃旧 banner 回调")
                return
            }

            self.taskMap[requestKey] = nil

            switch result {
            case .success(let banners):
                self.banners = banners
                print("banner 成功，数量: \(banners.count)")

            case .failure(let error):
                print("banner 失败: \(error)")
            }

            self.onDemoDataChanged?()
        }

        taskMap[requestKey] = task
    }

    private func loadRecommendProductsForDemo() {
        let requestKey = RequestKey.recommendProducts

        taskMap[requestKey]?.cancel()

        let requestID = UUID()
        requestIDMap[requestKey] = requestID

        let task = service.fetchRecommendProducts { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.requestIDMap[requestKey] else {
                print("丢弃旧 recommendProducts 回调")
                return
            }

            self.taskMap[requestKey] = nil

            switch result {
            case .success(let products):
                self.recommendProducts = products
                print("recommendProducts 成功，数量: \(products.count)")

            case .failure(let error):
                print("recommendProducts 失败: \(error)")
            }

            self.onDemoDataChanged?()
        }

        taskMap[requestKey] = task
    }

    private func loadUnreadCountForDemo() {
        let requestKey = RequestKey.unreadCount

        taskMap[requestKey]?.cancel()

        let requestID = UUID()
        requestIDMap[requestKey] = requestID

        let task = service.fetchUnreadCount { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.requestIDMap[requestKey] else {
                print("丢弃旧 unreadCount 回调")
                return
            }

            self.taskMap[requestKey] = nil

            switch result {
            case .success(let unread):
                self.unreadCount = unread.count
                print("unreadCount 成功: \(unread.count)")

            case .failure(let error):
                print("unreadCount 失败: \(error)")
            }

            self.onDemoDataChanged?()
        }

        taskMap[requestKey] = task
    }

    // MARK: - Private Loading Logic

    private func canLoadData(mode: LoadMode) -> Bool {
        print("进入 canLoadData，mode: \(mode), loadState: \(loadState), hasMoreData: \(hasMoreData)")

        if loadState != .idle {
            print("拦截：当前已有请求进行中，loadState = \(loadState)")
            return false
        }

        if mode == .loadMore && !hasMoreData {
            print("拦截：没有更多数据")
            return false
        }

        print("允许请求")
        return true
    }

    private func beginLoading(mode: LoadMode) {
        
        switch mode {
       
        case .initial:
            loadState = .initialLoading
        case .refresh:
            loadState = .refreshing
        case .loadMore:
            loadState = .loadingMore
        }

        if products.isEmpty && mode == .initial {
            onViewStateChanged?(.loading)
        }

        let shouldShowFooterLoading = mode == .loadMore && !products.isEmpty
        onFooterStateChanged?(shouldShowFooterLoading ? .loadingMore : .hidden)
    }

    private func finishLoading() {
        loadState = .idle
        onFooterStateChanged?(makeFooterStateForCurrentList())
    }

    private func makeTargetPage(mode: LoadMode) -> Int {
        switch mode {
        case .initial, .refresh:
            return 1
        case .loadMore:
            return currentPage + 1
        }
    }

    private func handleLoadSuccess(_ pageData: PageResponse<Product>, mode: LoadMode, targetPage: Int) {
        let list = pageData.list

        switch mode {
        case .initial, .refresh:
            products = list
            currentPage = pageData.page

        case .loadMore:
            products.append(contentsOf: list)
            currentPage = pageData.page
        }

        // 真实分页接口会返回 total，比单纯依赖 list.count == pageSize 更可靠。
        // products.count 表示当前已经成功展示的总条数，pageData.total 表示服务端总条数。
        hasMoreData = products.count < pageData.total
        saveCache()

        onProductsChanged?(products)
        onViewStateChanged?(makeViewStateForCurrentList())
        onFooterStateChanged?(makeFooterStateForCurrentList())

        // 只有真实网络 initial / refresh 成功后，才允许 VC 检查是否需要自动补满一屏。
        // loadMore 成功后不继续自动触发，避免接口异常或内容高度计算导致连续请求。
        // loadCache / clearCache 不会走到这里，所以不会再被缓存数据误触发 page 2。
        if mode == .initial || mode == .refresh {
            onCanCheckAutoLoadMore?()
        }

        print("当前页: \(currentPage), 当前总条数: \(products.count), 服务端总条数: \(pageData.total), 是否还有更多: \(hasMoreData)")
    }

    private func handleLoadFailure(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .requestFailed(let urlError as URLError) where urlError.code == .cancelled:
                print("请求已取消，不作为失败处理")
                return
            default:
                break
            }
        }

        print("请求失败 error:", error)
        print("请求失败描述:", error.localizedDescription)

        if products.isEmpty {
            onViewStateChanged?(.error("网络异常，请稍后重试"))
        } else {
            onViewStateChanged?(.content)
        }

        onFooterStateChanged?(makeFooterStateForCurrentList())
    }

    // MARK: - Cache

    private func saveCache() {
        CacheHelper.save(products, key: cacheKey)
    }

    // MARK: - State Makers

    private func makeViewStateForCurrentList() -> ViewState {
        return products.isEmpty ? .empty("暂无数据") : .content
    }

    private func makeFooterStateForCurrentList() -> FooterState {
        guard !products.isEmpty else {
            return .hidden
        }

        return hasMoreData ? .hidden : .noMoreData
    }
}
