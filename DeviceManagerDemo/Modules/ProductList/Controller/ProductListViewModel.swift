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

    private enum RequestKey {
        case productList
    }
    
    // MARK: - State

    private(set) var products: [Product] = []

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
        return loadState == .idle && hasMoreData && !products.isEmpty
    }

    // MARK: - Outputs

    var onProductsChanged: (([Product]) -> Void)?

    var onViewStateChanged: ((ViewState) -> Void)?

    var onFooterStateChanged: ((FooterState) -> Void)?

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
    }

    func clearCache() {
        CacheHelper.clear(key: cacheKey)
        products.removeAll()
        currentPage = 1
        hasMoreData = false

        onProductsChanged?(products)
        onViewStateChanged?(.empty("暂无数据"))
        onFooterStateChanged?(.hidden)
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

    }
    
    @discardableResult
    func updateProduct(_ newProduct: Product) -> Int? {
        guard let index = products.firstIndex(where: { $0.id == newProduct.id }) else {
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

    // MARK: - Private Loading Logic

    private func canLoadData(mode: LoadMode) -> Bool {
       
            switch mode {

            case .initial:
                guard loadState == .idle else {
                    print("拦截 initial：当前已有请求进行中，loadState = \(loadState)")
                    return false
                }
                
                return true
                
            case .refresh:
                // refresh 优先级最高。
                // prepareForNewRequestIfNeeded(mode:) 已经负责取消旧请求并把 loadState 重置为 idle。
                return true
                
            case .loadMore:
                guard loadState == .idle else {
                    print("拦截 loadMore：当前已有请求进行中，loadState = \(loadState)")
                    return false
                }
                guard hasMoreData else {
                    print("拦截 loadMore：没有更多数据")
                    return false
                }
                guard !products.isEmpty else {
                    print("拦截 loadMore：当前没有基础数据，不能加载下一页")
                    return false
                }
                
                return true
            }
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

    }

    private func handleLoadFailure(_ error: Error) {
        
        if let networkError = error as? NetworkError,
           case .cancelled = networkError {
            return
        }

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
