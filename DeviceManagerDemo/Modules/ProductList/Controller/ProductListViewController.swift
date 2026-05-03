///
///  ProductListViewController.swift
///  DeviceManagerDemo
///
///  Created by 天亮了 on 2026/4/19.
///

import UIKit

final class ProductListViewController: UIViewController {
    
    // MARK: - Types
    
    /// 主页面状态
    ///
    /// 这个 enum 用来统一管理列表页的几种主状态。
    ///
    /// 为什么要用 enum：
    /// - 不要到处散落 isLoading / isEmpty / isError 之类的 Bool
    /// - 页面到底处于 loading、content、empty、error，可以用一个明确的状态表达
    /// - 后面 updateViewState 只根据 ViewState 渲染 UI
    private enum ViewState {
        /// 首屏加载中
        case loading
        
        /// 有内容，正常展示 tableView
        case content
        
        /// 请求成功但没数据，或者当前列表为空
        case empty(String)
        
        /// 请求失败且当前没有旧数据可展示
        case error(String)
    }
    
    /// 底部状态
    ///
    /// 用来管理 tableView.tableFooterView 的显示。
    ///
    /// 注意：FooterState 只管底部，不管主页面。
    /// 主页面 loading / empty / error 由 ViewState 管。
    private enum FooterState {
        /// 不显示底部
        case hidden
        
        /// 正在上拉加载更多
        case loadingMore
        
        /// 没有更多数据
        case noMoreData
    }
    
    /// 列表加载类型
    ///
    /// 作用：替代 loadData(isRefresh: Bool) 里的 Bool。
    ///
    /// 为什么要替代 Bool：
    /// - isRefresh = true 只能表达“刷新”
    /// - isRefresh = false 只能被猜成“加载更多”
    /// - 但真实列表请求至少有三种：首次加载、下拉刷新、上拉加载更多
    /// - 用 enum 后，调用方一眼能看出这次请求到底是什么类型
    ///
    /// LoadMode 表示：这一次请求“要做什么动作”。
    private enum LoadMode {
        /// 首次进入页面，请求第 1 页
        case initial
        
        /// 用户下拉刷新，请求第 1 页
        case refresh
        
        /// 用户上拉加载更多，请求下一页
        case loadMore
    }
    
    /// 当前页面请求状态
    ///
    /// LoadState 表示：当前页面“正在处于什么请求状态”。
    ///
    /// LoadMode 和 LoadState 的区别：
    /// - LoadMode 是本次请求的动作参数，比如 .refresh / .loadMore
    /// - LoadState 是页面当前状态，比如 .refreshing / .loadingMore
    ///
    /// 举例：
    /// - 用户触发下拉刷新时，loadData(mode: .refresh)
    /// - beginLoading 后，loadState = .refreshing
    private enum LoadState {
        /// 当前没有任何列表请求在进行，可以发起新请求
        case idle
        
        /// 当前正在首次加载
        case initialLoading
        
        /// 当前正在下拉刷新
        case refreshing
        
        /// 当前正在上拉加载更多
        case loadingMore
    }
    
    // MARK: - UI Components
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    
    /// 首屏加载菊花
    ///
    /// 只用于首次进入且没有缓存数据时。
    /// 如果已经有缓存或旧数据，就不应该盖一个全屏 loading，避免影响用户体验。
    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// 空页面 / 错误页面提示
    ///
    /// 当前项目用一个 label 承载 empty 和 error 的提示文案。
    ///
    /// 注意：
    /// - empty：请求成功但没有数据，显示“暂无数据”
    /// - error：请求失败且当前没有旧数据，显示“网络异常，请稍后重试”
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无数据"
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    /// 上拉加载更多的底部容器
    private let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    
    /// 底部加载菊花
    private let footerLoadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// 底部提示文案
    private let footerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // MARK: - Data State
    
    /// 当前列表数据源
    ///
    /// tableView 的 numberOfRows 和 cellForRowAt 都基于它。
    /// 请求成功、缓存读取、详情页回传都会修改它。
    private var productList: [Product] = []
    
    /// 当前已成功加载到第几页
    ///
    /// 注意：
    /// currentPage 只代表“已经成功加载完成的页”。
    /// 不能在请求发出前提前 +1，否则请求失败会导致页码错乱。
    private var currentPage: Int = 1
    
    /// 每页条数
    private let pageSize: Int = 10
    
    /// 当前列表请求状态
    ///
    /// 初始是 idle，表示当前没有请求在飞。
    /// 发起首次加载时改成 .initialLoading。
    /// 发起下拉刷新时改成 .refreshing。
    /// 发起上拉加载更多时改成 .loadingMore。
    /// 请求结束后再改回 .idle。
    ///
    /// 作用：
    /// - 替代单纯 isLoading Bool
    /// - 让代码知道当前到底是首次加载、刷新，还是加载更多
    /// - 控制同一时间只允许一个列表请求在飞
    private var loadState: LoadState = .idle
    
    /// 当前列表请求对应的 URLSessionDataTask
    ///
    /// 为什么要保存 task：
    /// - 请求发出去以后，如果页面销毁了，旧请求已经没有意义
    /// - 如果用户下拉刷新想要最新数据，旧请求可以 cancel
    /// - 这一步是从“只会发请求”升级到“管理请求生命周期”
    private var currentTask: URLSessionDataTask?
    
    /// 当前页面最新有效的请求编号
    ///
    /// 作用：防止旧请求晚回来后，影响新请求的数据和 UI 状态。
    ///
    /// 工作方式：
    /// 1. 每次真正发起请求前，currentRequestID 都会 +1
    /// 2. 当前这次请求会把当时的编号保存成局部 requestID
    /// 3. 网络回调 closure 会捕获这个 requestID
    /// 4. 回调回来时，先判断 requestID 是否还等于 currentRequestID
    /// 5. 不相等，说明这个回调已经过期，直接丢弃
    ///
    /// 重点：
    /// requestID 不是服务器返回的，也不是回调参数带回来的。
    /// 它是请求发出前生成，并被 closure 捕获保存下来的。
    private var currentRequestID: Int = 0
    
    /// 是否还有更多数据
    ///
    /// 当前判断方式：
    /// - 如果本页返回数量 == pageSize，认为可能还有更多
    /// - 如果本页返回数量 < pageSize，认为没有更多
    ///
    /// 真实项目中，如果接口返回 totalPage / totalCount，应该优先使用服务端分页信息。
    private var hasMoreData: Bool = true
    
    /// 防止 scrollViewDidScroll 在触底区域内重复触发 loadMore
    ///
    /// scrollViewDidScroll 会高频触发。
    /// 如果用户停留在底部触发区域，不加这个开关，可能连续触发多次 loadMore。
    private var isLoadMoreTriggered = false
    
    /// 缓存 key
    private let cacheKey = "ProductListCacheKey"
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "文章列表"
        view.backgroundColor = .white
        
        setupTableView()
        setupLoadingView()
        
        // 1. 先读缓存，先把旧数据展示出来
        loadCache()
        
        // 2. 再请求最新第一页
        loadData(mode: .initial)
    }
    
    deinit {
        /// 页面销毁时，取消当前还没完成的列表请求。
        ///
        /// 为什么要取消：
        /// - 用户已经离开当前页面，请求结果不再需要
        /// - 取消后可以减少无意义的网络回调
        /// - 避免旧请求回来后还试图影响已经销毁或即将销毁的页面逻辑
        currentTask?.cancel()
        print("ProductListViewController deinit，取消未完成请求")
    }
}

// MARK: - Setup
extension ProductListViewController {
    
    private func setupTableView() {
        tableView.frame = view.bounds
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        setupTableFooterView()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        /// 空页面放到 tableView 的 backgroundView。
        ///
        /// tableView 有数据时，backgroundView 会被内容盖住。
        /// productList 为空时，emptyLabel 可以作为空页面提示。
        tableView.backgroundView = emptyLabel
        
        view.addSubview(tableView)
        setupDebugNavigationItems()
    }
    
    private func setupLoadingView() {
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableFooterView() {
        footerView.addSubview(footerLoadingView)
        footerView.addSubview(footerLabel)
        
        footerLoadingView.translatesAutoresizingMaskIntoConstraints = false
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            footerLoadingView.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            footerLoadingView.trailingAnchor.constraint(equalTo: footerLabel.leadingAnchor, constant: -8),
            footerLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            footerLabel.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])
        
        tableView.tableFooterView = UIView()
    }
    
    private func setupDebugNavigationItems() {
#if DEBUG
        let deleteItem = UIBarButtonItem(
            title: "删除缓存",
            style: .plain,
            target: self,
            action: #selector(clearCacheBtnAction)
        )
        
        let lookItem = UIBarButtonItem(
            title: "查看缓存",
            style: .plain,
            target: self,
            action: #selector(lookButtonTapped)
        )
        
        let testRequestItem = UIBarButtonItem(
            title: "测试请求",
            style: .plain,
            target: self,
            action: #selector(testRequestConflictTapped)
        )
        
        navigationItem.rightBarButtonItems = [deleteItem, lookItem, testRequestItem]
#endif
    }
}

// MARK: - Actions
extension ProductListViewController {
    
    @objc private func refreshAction() {
        print("触发下拉刷新")
        isLoadMoreTriggered = false
        
        /// 下拉刷新代表用户想要最新的第一页数据。
        ///
        /// 如果当前已经有请求在进行中，旧请求结果已经不重要了。
        /// 这里先取消旧请求，并把状态恢复成 idle，确保新的刷新请求可以发出去。
        ///
        /// 注意：
        /// 旧请求即使被 cancel，回调仍然可能回来。
        /// 所以下面 loadData 里还会用 currentRequestID 再拦一次旧回调。
        if loadState != .idle {
            currentTask?.cancel()
            currentTask = nil
            loadState = .idle
            refreshControl.endRefreshing()
            updateFooterState(makeFooterStateForCurrentList())
            print("下拉刷新触发：取消旧请求，准备重新请求第一页")
        }
        
        loadData(mode: .refresh)
    }
    
    @objc private func clearCacheBtnAction() {
        clearCache()
    }
    
    @objc private func lookButtonTapped() {
        guard let cacheList = CacheHelper.load(key: cacheKey, as: [Product].self) else {
            print("无缓存")
            return
        }
        
        print("读取缓存成功，缓存条数：\(cacheList.count)")
    }
    
#if DEBUG
    /// 测试请求取消 + requestID 防旧回调
    ///
    /// 这个方法只用于 DEBUG 测试，不属于正式业务逻辑。
    ///
    /// 测试目的：
    /// 1. 先发起一次刷新请求 A
    /// 2. 很短时间后，再触发一次下拉刷新 B
    /// 3. B 会取消 A，并生成新的 requestID
    /// 4. 如果 A 的回调之后才回来，应该被 requestID 判断丢弃
    ///
    /// 你可以重点看控制台日志：
    /// - “下拉刷新触发：取消旧请求，准备重新请求第一页”
    /// - “丢弃旧请求回调 requestID...”
    /// - “请求已取消，不作为失败处理”
    @objc private func testRequestConflictTapped() {
        print("========== DEBUG 测试：连续刷新请求开始 ==========")
        print("第一步：发起刷新请求 A")
        loadData(mode: .refresh)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            print("第二步：模拟用户很快再次下拉刷新，触发刷新请求 B")
            self.refreshAction()
        }
    }
#endif
}

// MARK: - Data Loading
extension ProductListViewController {
    
    /// 核心分页方法
    ///
    /// 当前这个方法是列表请求流程的总调度。
    ///
    /// 它负责：
    /// 1. 判断能不能请求
    /// 2. 设置请求状态
    /// 3. 计算目标页码
    /// 4. 生成 requestID
    /// 5. 发起网络请求并保存 currentTask
    /// 6. 回调回来后防旧请求污染
    /// 7. 分发成功 / 失败处理
    private func loadData(mode: LoadMode) {
        guard canLoadData(mode: mode) else {
            return
        }
        
        beginLoading(mode: mode)
        
        let targetPage = makeTargetPage(mode: mode)
        
        /// 发起请求前，生成这一次请求自己的编号。
        ///
        /// currentRequestID 是页面当前最新请求编号，每发起一次新请求就 +1。
        /// requestID 是当前这一次请求自己的编号快照，会被下面的网络回调 closure 捕获。
        ///
        /// 回调回来时，如果 requestID 已经不等于 currentRequestID，说明：
        /// - 这个请求发出之后，又有更新的请求发出了
        /// - 当前回调已经过期
        /// - 不能再修改 productList / currentPage / cache / UI 状态
        currentRequestID += 1
        let requestID = currentRequestID
        
        /// ProductService.fetchList 现在会返回 URLSessionDataTask?
        ///
        /// 这里把返回的 task 保存到 currentTask。
        /// 以后如果页面销毁，或者需要主动取消旧请求，就可以调用 currentTask?.cancel()。
        currentTask = ProductService.fetchList(page: targetPage, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            
            /// 回调回来后，先判断这个请求是否仍然有效。
            ///
            /// 如果不相等，说明它是旧请求的回调。
            /// 这种回调必须直接丢弃，不能 finishLoading，也不能 handleLoadFailure，
            /// 否则可能把新请求的 loading 状态关掉，或者把新页面状态改成 error。
            guard requestID == self.currentRequestID else {
                print("丢弃旧请求回调 requestID: \(requestID), currentRequestID: \(self.currentRequestID)")
                return
            }
            
            /// 请求已经回调完成，这个 task 不再需要继续保存。
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
    
    /// 判断当前是否允许发起请求
    private func canLoadData(mode: LoadMode) -> Bool {
        print("进入 canLoadData，mode: \(mode), loadState: \(loadState), hasMoreData: \(hasMoreData)")
        
        /// 当前不是 idle，说明已经有请求在进行中。
        ///
        /// 这里直接拦截，保证 initial / refresh / loadMore 互斥。
        /// 也就是说：同一时间只允许一个列表请求在飞。
        /// 这能从源头避免多个请求返回顺序不可控导致的数据脏写。
        if loadState != .idle {
            print("拦截：当前已有请求进行中，loadState = \(loadState)")
            return false
        }
        
        /// 只有上拉加载更多需要判断 hasMoreData。
        ///
        /// initial 和 refresh 都是重新请求第 1 页，不受 hasMoreData 限制。
        if mode == .loadMore && !hasMoreData {
            print("拦截：没有更多数据")
            return false
        }
        
        print("允许请求")
        return true
    }
    
    /// 开始请求：设置请求状态，并处理 loading UI
    private func beginLoading(mode: LoadMode) {
        /// 根据当前请求类型，记录列表正在执行哪一种加载。
        switch mode {
        case .initial:
            loadState = .initialLoading
        case .refresh:
            loadState = .refreshing
        case .loadMore:
            loadState = .loadingMore
        }
        
        /// 首次进入且当前没有数据时，显示全屏 loading。
        ///
        /// 下拉刷新有 refreshControl 自带的小菊花，不需要盖全屏 loading。
        /// 上拉加载更多有 footer loading，也不需要盖全屏 loading。
        let shouldShowFullScreenLoading = productList.isEmpty && mode == .initial
        if shouldShowFullScreenLoading {
            updateViewState(.loading)
        }
        
        /// 只有上拉加载更多，才显示底部 footer loading。
        let shouldShowFooterLoading = mode == .loadMore && !productList.isEmpty
        updateFooterState(shouldShowFooterLoading ? .loadingMore : .hidden)
    }
    
    /// 结束请求：恢复请求状态，并停止下拉刷新动画
    private func finishLoading() {
        /// 请求结束后，恢复为空闲状态。
        ///
        /// 只有恢复到 .idle，下一次下拉刷新或上拉加载更多才允许发起。
        loadState = .idle
        refreshControl.endRefreshing()
        updateFooterState(makeFooterStateForCurrentList())
    }
    
    /// 根据当前加载类型计算目标页码
    private func makeTargetPage(mode: LoadMode) -> Int {
        switch mode {
        case .initial, .refresh:
            return 1
        case .loadMore:
            return currentPage + 1
        }
    }
    
    /// 请求成功后的数据处理
    private func handleLoadSuccess(_ list: [Product], mode: LoadMode, targetPage: Int) {
        switch mode {
        case .initial, .refresh:
            /// 首次加载 / 下拉刷新：直接替换数据
            productList = list
            currentPage = 1
            isLoadMoreTriggered = false
            
        case .loadMore:
            /// 上拉加载更多：把新数据追加到旧数据后面
            productList.append(contentsOf: list)
            currentPage = targetPage
        }
        
        /// 如果这一页返回的数据数量 == pageSize，说明可能还有更多。
        /// 如果少于 pageSize，说明后面大概率没有更多数据。
        hasMoreData = list.count == pageSize
        
        /// 请求成功后，保存最新缓存。
        /// 请求失败时不能保存缓存，因为没有拿到新的有效数据。
        saveCache()
        
        reloadListUI()
        updateFooterState(makeFooterStateForCurrentList())
        
        print("当前页: \(currentPage), 当前总条数: \(productList.count), 是否还有更多: \(hasMoreData)")
    }
    
    /// 请求失败后的处理
    private func handleLoadFailure(_ error: Error) {
        /// 如果请求是被主动 cancel 的，不把它当成真正的网络失败。
        ///
        /// cancel 常见场景：
        /// - 用户下拉刷新时，取消旧请求
        /// - 页面销毁时，取消未完成请求
        ///
        /// 这种情况不应该显示“网络异常”，也不应该改变当前页面状态。
        if let networkError = error as? NetworkError {
            switch networkError {
            case .requestFailed(let urlError as URLError) where urlError.code == .cancelled:
                print("请求已取消，不作为失败处理")
                return
            default:
                break
            }
        }
        
        // 这里先直接打印 error 本体，不只打印 localizedDescription。
        // 原因：NetworkError 是我们自己定义的 enum，直接打印 error，
        // 才能看到 invalidURL / requestFailed / invalidStatusCode / decodingFailed 这些具体 case。
        print("请求失败 error:", error)
        print("请求失败描述:", error.localizedDescription)
        
        /// 请求失败时：
        /// - 如果当前没有任何数据，显示错误空页面
        /// - 如果当前已有缓存或旧数据，继续显示旧数据，不切成错误页
        if productList.isEmpty {
            updateViewState(.error("网络异常，请稍后重试"))
        } else {
            updateViewState(.content)
        }
    }
}

// MARK: - Cache
extension ProductListViewController {
    
    /// 保存缓存
    private func saveCache() {
        CacheHelper.save(productList, key: cacheKey)
    }
    
    /// 加载缓存
    private func loadCache() {
        guard let cacheList = CacheHelper.load(key: cacheKey, as: [Product].self) else {
            updateViewState(.empty("暂无数据"))
            return
        }
        
        productList = cacheList
        reloadListUI()
        print("读取缓存成功，缓存条数：\(cacheList.count)")
    }
    
    /// 清除缓存
    private func clearCache() {
        CacheHelper.clear(key: cacheKey)
        productList.removeAll()
        currentPage = 1
        hasMoreData = true
        isLoadMoreTriggered = false
        tableView.reloadData()
        updateViewState(.empty("暂无数据"))
        updateFooterState(.hidden)
        print("缓存已删除")
    }
}

// MARK: - View State
extension ProductListViewController {
    
    /// 刷新列表数据，并根据数据数量更新主页面状态
    private func reloadListUI() {
        tableView.reloadData()
        updateViewState(makeViewStateForCurrentList())
    }
    
    private func makeViewStateForCurrentList() -> ViewState {
        return productList.isEmpty ? .empty("暂无数据") : .content
    }
    
    private func updateViewState(_ state: ViewState) {
        switch state {
        case .loading:
            loadingView.startAnimating()
            emptyLabel.isHidden = true
            tableView.isHidden = true
            
        case .content:
            loadingView.stopAnimating()
            tableView.isHidden = false
            emptyLabel.isHidden = true
            
        case .empty(let message), .error(let message):
            loadingView.stopAnimating()
            tableView.isHidden = false
            emptyLabel.text = message
            emptyLabel.isHidden = false
        }
    }
}

// MARK: - Footer State
extension ProductListViewController {
    
    private func updateFooterState(_ state: FooterState) {
        switch state {
        case .hidden:
            hideFooterView()
            
        case .loadingMore:
            footerLabel.text = "加载更多中..."
            footerLoadingView.startAnimating()
            tableView.tableFooterView = footerView
            
        case .noMoreData:
            footerLoadingView.stopAnimating()
            footerLabel.text = "没有更多数据"
            tableView.tableFooterView = footerView
        }
    }
    
    private func makeFooterStateForCurrentList() -> FooterState {
        guard !productList.isEmpty else {
            return .hidden
        }
        
        return hasMoreData ? .hidden : .noMoreData
    }
    
    private func hideFooterView() {
        tableView.tableFooterView = UIView()
        footerLoadingView.stopAnimating()
        footerLabel.text = nil
    }
}

// MARK: - UITableViewDataSource
extension ProductListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProductCell.reuseIdentifier,
            for: indexPath
        ) as! ProductCell
        
        let product = productList[indexPath.row]
        cell.configure(with: product)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProductListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = productList[indexPath.row]
        let detailVC = ProductDetailViewController(product: model)
        
        /// 详情页保存后，通过 onSave closure 回传新的 Product。
        ///
        /// 这里要注意：
        /// - ProductCell 不负责修改数组
        /// - DetailVC 不直接知道列表数组
        /// - 列表页拿到 newProduct 后，更新 productList 对应行
        /// - 然后 reloadRows 局部刷新当前行
        /// - 最后 saveCache 保证本地缓存也同步更新
        detailVC.onSave = { [weak self] newProduct in
            guard let self = self else { return }
           // guard indexPath.row < self.productList.count else { return }
            
            /// 不再长期依赖进入详情页时的 indexPath.row。
            ///
            /// 原因：
            /// indexPath.row 只是“当时点击的行号”，不是稳定身份。
            /// 如果详情页还没保存前，列表发生刷新、排序、删除，
            /// 原来的 row 可能已经不是原来的那条数据。
            ///
            /// 更稳的做法：
            /// 用 newProduct.id 回到当前 productList 里重新查找真实位置。
            ///
            guard let index = self.productList.firstIndex(where: { $0.id == newProduct.id }) else {
                    print("保存失败：列表中找不到 id = \(newProduct.id) 的数据")
                    return
                }
            /// 更新当前数组中真正对应的那一条数据
            self.productList[index] = newProduct
            /// 保存最新缓存，保证下次启动还能看到修改后的本地数据
            self.saveCache()
            /// 用最新 index 重新生成 IndexPath，再局部刷新当前行
            let updatedIndexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [updatedIndexPath], with: .automatic)
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ProductListViewController {
    
    /// 滚动到底部附近时，自动触发加载更多
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /// 当前已有请求在进行中，或者没有更多数据时，不处理上拉加载。
        ///
        /// loadState != .idle 表示当前可能正在首次加载、下拉刷新或上拉加载更多。
        /// 这里拦截，是为了保证分页请求串行执行，避免多页并发 append 造成列表顺序错乱。
        if loadState != .idle || !hasMoreData {
            return
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if contentHeight <= frameHeight {
            return
        }
        
        let triggerY = contentHeight - frameHeight - 80
        
        /// 离开触发区，重置开关。
        ///
        /// 用户滚出触发区后，下一次再进入触发区，才允许再次触发 loadMore。
        if offsetY < triggerY {
            isLoadMoreTriggered = false
        }
        
        /// 进入触发区时，只触发一次。
        if scrollView.isDragging && offsetY > triggerY && !isLoadMoreTriggered {
            print("触发上拉加载更多")
            isLoadMoreTriggered = true
            loadData(mode: .loadMore)
        }
    }
}
