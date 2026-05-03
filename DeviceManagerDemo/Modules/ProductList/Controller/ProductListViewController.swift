///
///  ProductListViewController.swift
///  DeviceManagerDemo
///
///  Created by 天亮了 on 2026/4/19.
///

import UIKit

final class ProductListViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    
    /// 首屏加载菊花
    ///
    /// 现在是否显示 loading，不再由 VC 自己判断。
    /// ViewModel 会通过 onViewStateChanged 通知 VC 显示 .loading / .content / .empty / .error。
    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// 空页面 / 错误页面提示
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
    
    /// VC 保留一份列表数据镜像，专门给 tableViewDataSource 使用。
    ///
    /// 真正的分页状态、请求状态、缓存状态已经交给 ProductListViewModel 管。
    /// ViewModel 的 products 一变化，会通过 onProductsChanged 回调给 VC。
    private var productList: [Product] = []
    
    /// 防止 scrollViewDidScroll 在底部触发区内重复触发 loadMore。
    ///
    /// false：还没触发，可以触发。
    /// true：已经触发过了，别重复触发。
    ///
    /// 注意：
    /// 它只管“滚动触发去重”。
    /// 是否真的允许加载更多，由 viewModel.canLoadMore 判断。
    private var isLoadMoreTriggered = false
    
    /// 页面数据状态管理者
    ///
    /// ViewModel 负责：
    /// - 加载缓存
    /// - 请求列表
    /// - 分页状态
    /// - 请求生命周期
    /// - requestID 防旧请求
    /// - 成功后 replace / append
    /// - 保存缓存
    private let viewModel = ProductListViewModel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "文章列表"
        view.backgroundColor = .white
        
        setupTableView()
        setupLoadingView()
        bindViewModel()
        
        /// 进入页面后：
        /// 1. 先让 ViewModel 读取缓存
        /// 2. 再让 ViewModel 请求最新第一页
        ///
        /// VC 不再直接 loadCache / loadData。
        viewModel.loadCache()
        viewModel.loadData(mode: .initial)
    }
    
    deinit {
        /// 页面销毁时，通知 ViewModel 取消当前未完成请求。
        viewModel.cancelCurrentTask()
        print("ProductListViewController deinit，取消未完成请求")
    }
}

// MARK: - Setup
extension ProductListViewController {
    
    private func setupTableView() {
        tableView.frame = view.bounds
        
        /// cell 高度自适应。
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        setupTableFooterView()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        tableView.refreshControl = refreshControl
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

// MARK: - Binding
extension ProductListViewController {
    
    private func bindViewModel() {
        /// ViewModel 数据源变化后，VC 更新自己的展示镜像并刷新 tableView。
        viewModel.onProductsChanged = { [weak self] products in
            guard let self = self else { return }
            self.productList = products
            self.tableView.reloadData()
        }
        
        /// ViewModel 通知页面主状态变化，VC 负责真正渲染 UI。
        viewModel.onViewStateChanged = { [weak self] state in
            self?.updateViewState(state)
        }
        
        /// ViewModel 通知底部状态变化，VC 负责真正渲染 footer。
        viewModel.onFooterStateChanged = { [weak self] state in
            self?.updateFooterState(state)
        }
    }
}

// MARK: - Actions
extension ProductListViewController {
    
    @objc private func refreshAction() {
        print("触发下拉刷新")
        isLoadMoreTriggered = false
        
        /// 下拉刷新动作转发给 ViewModel。
        /// 是否取消旧请求、是否能发新请求，由 ViewModel 判断。
        viewModel.loadData(mode: .refresh)
    }
    
    @objc private func clearCacheBtnAction() {
        isLoadMoreTriggered = false
        viewModel.clearCache()
    }
    
    @objc private func lookButtonTapped() {
        viewModel.printCacheInfo()
    }
    
#if DEBUG
    @objc private func testRequestConflictTapped() {
        print("========== DEBUG 测试：连续刷新请求开始 ==========")
        print("第一步：发起刷新请求 A")
        viewModel.loadData(mode: .refresh)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            print("第二步：模拟用户很快再次下拉刷新，触发刷新请求 B")
            self.viewModel.loadData(mode: .refresh)
        }
    }
#endif
}

// MARK: - View State
extension ProductListViewController {
    
    private func updateViewState(_ state: ProductListViewModel.ViewState) {
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
    
    private func updateFooterState(_ state: ProductListViewModel.FooterState) {
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
        
        /// 详情页保存后，把 newProduct 交给 ViewModel 更新数据源和缓存。
        /// VC 不再直接改 productList，也不再直接 saveCache。
        detailVC.onSave = { [weak self] newProduct in
            guard let self = self else { return }
            _ = self.viewModel.updateProduct(newProduct)
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ProductListViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /// 是否允许加载更多，由 ViewModel 根据 loadState / hasMoreData 判断。
        guard viewModel.canLoadMore else {
            return
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if contentHeight <= frameHeight {
            return
        }
        
        let triggerY = contentHeight - frameHeight - 80
        
        if offsetY < triggerY {
            isLoadMoreTriggered = false
        }
        
        if scrollView.isDragging && offsetY > triggerY && !isLoadMoreTriggered {
            print("触发上拉加载更多")
            isLoadMoreTriggered = true
            viewModel.loadData(mode: .loadMore)
        }
    }
}
