///
///  ProductListViewController.swift
///  DeviceManagerDemo
///
///  Created by 天亮了 on 2026/4/19.
///

import UIKit

final class ProductListViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private enum ViewState {
        case loading     //首屏加载中
        case content     //有内容
        case empty(String)  //空数据，比如“暂无数据”
        case error(String) //错误空页，比如“网络异常，请稍后重试”
    }
    private enum FooterState {
        case hidden
        case loadingMore
        case noMoreData
    }
    private var isLoadMoreTriggered = false  //防暴力刷新
    
    //首屏加载菊花
    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
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
    
    // 空页面提示
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无数据"
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private var productList: [Product] = []
    
   
    /// 当前页
    private var currentPage: Int = 1
      /// 每页条数
    private let pageSize: Int = 10
    /// 是否正在请求中，防止重复加载
    private var isLoading: Bool = false
    /// 是否还有更多数据
    private var hasMoreData: Bool = true
    
    /// 缓存 key
    private let cacheKey = "ProductListCacheKey"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "文章列表"
        view.backgroundColor = .white
              
        setupTableView()
        
        setupLoadingView()
        
        // 1. 先读缓存，先把旧数据展示出来
        loadCache()
             
        // 2. 再请求最新第一页
        loadData(isRefresh: true)
    }

}
extension ProductListViewController {
    
    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.rowHeight = 120
        setupTableFooterView()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        // 下拉刷新
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        /// 空页面放到 tableView 的 backgroundView
        tableView.backgroundView = emptyLabel
        
        view.addSubview(tableView)
        
        
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
#if DEBUG
            navigationItem.rightBarButtonItems = [deleteItem, lookItem]
#endif
    }
    
    @objc private func refreshAction() {
            print("触发下拉刷新")
            isLoadMoreTriggered = false
            loadData(isRefresh: true)
        }
}

// MARK: - Data
extension ProductListViewController {
    
    /// 核心分页方法
    private func loadData(isRefresh: Bool) {
          
        guard canLoadData(isRefresh: isRefresh) else {
                return
            }
        
            beginLoading(isRefresh: isRefresh)
        
            let targetPage = makeTargetPage(isRefresh: isRefresh)
        
          ProductService.fetchList(page: targetPage, limit: pageSize) { [weak self] result in
              guard let self = self else { return }
              
              self.finishLoading()
              
              switch result {
              case .success(let list):
                  
                  self.handleLoadSuccess(list, isRefresh: isRefresh, targetPage: targetPage)
                  
              case .failure(let error):
                  self.handleLoadFailure(error)
              }
          }
      }
    
    /// 判断当前是否允许发起请求（拦截器）
    private func canLoadData(isRefresh: Bool) -> Bool {
        
        print("进入 canLoadData，isRefresh: \(isRefresh), isLoading: \(isLoading), hasMoreData: \(hasMoreData)")
        
        /// 正在请求中，不允许重复请求
        if isLoading {
            print("拦截：正在请求中")
            return false
        }
        
        /// 如果是上拉加载更多，并且已经没有更多数据了，也不允许请求
        if !isRefresh && !hasMoreData {
            
            print("拦截：没有更多数据")
            return false
        }
        print("允许请求")
        return true
    }
    
    ///开始请求:设置请求中的状态
    private func beginLoading(isRefresh: Bool) {
        isLoading = true

        let shouldShowFullScreenLoading = productList.isEmpty && !refreshControl.isRefreshing
        if shouldShowFullScreenLoading {
            updateViewState(.loading)
        }

        let shouldShowFooterLoading = !isRefresh && !productList.isEmpty
        updateFooterState(shouldShowFooterLoading ? .loadingMore : .hidden)
    }
    
    ///结束请求：恢复请求状态，并停止下拉刷新动画
    private func finishLoading() {
        isLoading = false
        refreshControl.endRefreshing()
        updateFooterState(makeFooterStateForCurrentList())
    }
    
    /// 根据当前操作计算目标页码
    private func makeTargetPage(isRefresh: Bool) -> Int {
        if isRefresh {
            return 1
        }else{
            return currentPage + 1
        }
        
    }
    
    /// 请求成功后的数据处理
    private func handleLoadSuccess(_ list: [Product], isRefresh: Bool, targetPage: Int) {
        if isRefresh {
            /// 下拉刷新：直接替换数据
            productList = list
            currentPage = 1
            isLoadMoreTriggered = false
        } else {
            /// 上拉加载更多：把新数据追加到旧数据后面
            productList.append(contentsOf: list)
            currentPage = targetPage
        }

        /// 如果这一页返回的数据数量 < pageSize，说明后面没更多了
        hasMoreData = list.count == pageSize

        /// 请求成功后，保存最新缓存
        saveCache()

        reloadListUI()
        updateFooterState(makeFooterStateForCurrentList())

        print("当前页: \(currentPage), 当前总条数: \(productList.count), 是否还有更多: \(hasMoreData)")
    }
    /// 请求失败后的处理
    private func handleLoadFailure(_ error: Error) {
        // 这里先直接打印 error 本体，不只打印 localizedDescription。

        // 原因：NetworkError 是我们自己定义的 enum，直接打印 error，

        // 才能看到 invalidURL / requestFailed / invalidStatusCode / decodingFailed 这些具体 case。

        print("请求失败 error:", error)
        print("请求失败描述:", error.localizedDescription)

        if productList.isEmpty {
            updateViewState(.error("网络异常，请稍后重试"))
        } else {
            updateViewState(.content)
        }
    }
    
    /// 刷新列表数据，并根据数据数量更新主页面状态
    private func reloadListUI() {
        tableView.reloadData()
        updateViewState(makeViewStateForCurrentList())
    }

    private func makeViewStateForCurrentList() -> ViewState {
        return productList.isEmpty ? .empty("暂无数据") : .content
    }


}
extension ProductListViewController{
    
    ///保存缓存
    private func saveCache() {
        CacheHelper.save(productList, key: cacheKey)
    }
    ///加载缓存
    private func loadCache() {
        guard let cacheList = CacheHelper.load(key: cacheKey, as: [Product].self) else {
               updateViewState(.empty("暂无数据"))
               return
           }
            productList = cacheList
            reloadListUI()
            print("读取缓存成功，缓存条数：\(cacheList.count)")
        
    }
    ///清除缓存
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
}
// MARK: - State Views
extension ProductListViewController {
    
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
    
    private func setupLoadingView() {

        view.addSubview(loadingView)

        loadingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        ])

    }
    
    
}
    
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
extension ProductListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = productList[indexPath.row]
        let detailVC = ProductDetailViewController(product: model)
        detailVC.onSave = { [weak self] newProduct in
            guard let self = self else { return }
            guard indexPath.row < self.productList.count else { return }

            self.productList[indexPath.row] = newProduct
            self.saveCache()
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    /// 滚动到底部附近时，自动触发加载更多
       func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
           // 正在请求中，或者没有更多数据时，不处理上拉加载
           if isLoading || !hasMoreData {
               return
           }
           
           let offsetY = scrollView.contentOffset.y
           let contentHeight = scrollView.contentSize.height
           let frameHeight = scrollView.frame.size.height
           
           if contentHeight <= frameHeight {
               return
           }
           let triggerY = contentHeight - frameHeight - 80
           
           /// 离开触发区，重置开关
            if offsetY < triggerY {
                isLoadMoreTriggered = false
            }
           
           /// 进入触发区时，只触发一次
           if scrollView.isDragging && offsetY > triggerY && !isLoadMoreTriggered {
               print("触发上拉加载更多")
               isLoadMoreTriggered = true
               loadData(isRefresh: false)
           }
           
       }
    
    
}
