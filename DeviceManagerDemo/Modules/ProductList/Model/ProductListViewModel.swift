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

    // MARK: - State

    private(set) var products: [Product] = []

    private var currentPage: Int = 1
    private let pageSize: Int = 10
    private var loadState: LoadState = .idle
    private var currentTask: URLSessionDataTask?
    private var currentRequestID: Int = 0
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
        hasMoreData = true

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
        currentRequestID += 1
        let requestID = currentRequestID

        currentTask = service.fetchList(page: targetPage, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }

            guard requestID == self.currentRequestID else {
                print("丢弃旧请求回调 requestID: \(requestID), currentRequestID: \(self.currentRequestID)")
                return
            }

            self.currentTask = nil
            self.finishLoading()

            switch result {
            case .success(let list):
                self.handleLoadSuccess(list, mode: mode, targetPage: targetPage)

            case .failure(let error):
                self.handleLoadFailure(error)
            }
        }
    }

    private func prepareForNewRequestIfNeeded(mode: LoadMode) {
        /// refresh 代表用户主动拉取第一页，可以取消旧请求；loadMore 是分页追加，必须串行处理。
        guard mode == .refresh, loadState != .idle else {
            return
        }

        currentTask?.cancel()
        currentTask = nil
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
        currentTask?.cancel()
        currentTask = nil
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

    private func handleLoadSuccess(_ list: [Product], mode: LoadMode, targetPage: Int) {
        switch mode {
        case .initial, .refresh:
            products = list
            currentPage = 1

        case .loadMore:
            products.append(contentsOf: list)
            currentPage = targetPage
        }

        hasMoreData = list.count == pageSize
        saveCache()

        onProductsChanged?(products)
        onViewStateChanged?(makeViewStateForCurrentList())
        onFooterStateChanged?(makeFooterStateForCurrentList())

        print("当前页: \(currentPage), 当前总条数: \(products.count), 是否还有更多: \(hasMoreData)")
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
