import Foundation

final class ProductListViewModel {

    // MARK: - Types

    enum ViewState {
        case loading/// 首屏加载中
        case content/// 有内容，正常展示 tableView
        case empty(String)/// 请求成功但没数据，或者当前列表为空
        case error(String) /// 请求失败且当前没有旧数据可展示
    }

    enum FooterState { /// 注意：FooterState 只管底部，不管主页面。
        case hidden/// 不显示底部
        case loadingMore
        case noMoreData
    }

    enum LoadMode {/// LoadMode 表示：这一次请求“要做什么动作”。
        case initial/// 首次进入页面，请求第 1 页
        case refresh/// 用户下拉刷新，请求第 1 页
        case loadMore/// 用户上拉加载更多，请求下一页
    }

    private enum LoadState {/// LoadState 表示：当前页面“正在处于什么请求状态”。
        case idle /// 当前没有任何列表请求在进行，可以发起新请求
        case initialLoading/// 当前正在首次加载
        case refreshing/// 当前正在下拉刷新
        case loadingMore/// 当前正在上拉加载更多
    }

    // MARK: - State

    /// 外部可以读 products，但只能 ViewModel 自己改 products
    private(set) var products: [Product] = []

    private var currentPage: Int = 1
    private let pageSize: Int = 10
    private var loadState: LoadState = .idle
    private var currentTask: URLSessionDataTask?
    private var currentRequestID: Int = 0
    private var hasMoreData: Bool = true
    private let cacheKey = "ProductListCacheKey"

    /// 给 VC 的 scrollViewDidScroll 用。
    /// VC 不需要知道 loadState / hasMoreData 的细节，只问一句：现在能不能加载更多。
    var canLoadMore: Bool {
        return loadState == .idle && hasMoreData
    }

    // MARK: - Outputs

    /// products 变化时通知 VC 刷新 tableView 数据源
    var onProductsChanged: (([Product]) -> Void)?

    /// 主页面状态变化时通知 VC 渲染 loading / content / empty / error
    var onViewStateChanged: ((ViewState) -> Void)?

    /// 底部状态变化时通知 VC 渲染 footer
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
        /// 下拉刷新代表用户想要最新的第一页数据。
        /// 如果旧请求还在飞，先取消旧请求，再允许新的刷新请求发出去。
        if mode == .refresh && loadState != .idle {
            currentTask?.cancel()
            currentTask = nil
            loadState = .idle
            onFooterStateChanged?(makeFooterStateForCurrentList())
            print("下拉刷新触发：取消旧请求，准备重新请求第一页")
        }

        guard canLoadData(mode: mode) else {
            return
        }

        beginLoading(mode: mode)

        let targetPage = makeTargetPage(mode: mode)

        /// 发请求前生成本次请求的编号。
        /// 回调回来时要先比较 requestID，防止旧请求污染新数据。
        currentRequestID += 1
        let requestID = currentRequestID

        currentTask = ProductService.fetchList(page: targetPage, limit: pageSize) { [weak self] result in
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

    /// 详情页回传后，用 id 更新 ViewModel 内部的数据源和缓存。
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

