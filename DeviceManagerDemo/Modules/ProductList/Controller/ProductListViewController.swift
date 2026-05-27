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
    
    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无数据"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    
    private let footerLoadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let footerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // MARK: - Data State
    
    /// 只负责滚动触发去重，真正的分页边界由 viewModel.canLoadMore 决定。
    private var isLoadMoreTriggered = false
    
    /// ViewModel 管理列表数据、分页状态、请求生命周期和缓存，VC 只负责渲染。
    private let viewModel = ProductListViewModel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "文章列表"
        //  确保 VC 的根视图和 TableView 的背景是动态系统背景
       view.backgroundColor = .systemBackground
       tableView.backgroundColor = .systemBackground
       
       // 如果你之前的行线写死了颜色，也可以顺手改成动态分割线
       tableView.separatorColor = .separator
        
        setupTableView()
        setupLoadingView()
        bindViewModel()
        
        /// 先展示缓存兜底，再请求第一页刷新数据。
        viewModel.loadCache()
        viewModel.loadData(mode: .initial)
    
    }
    
    deinit {
        viewModel.cancelCurrentTask()
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
        viewModel.onProductsChanged = { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        viewModel.onViewStateChanged = { [weak self] state in
            self?.updateViewState(state)
        }
        
        viewModel.onFooterStateChanged = { [weak self] state in
            self?.updateFooterState(state)
        }

        viewModel.onCanCheckAutoLoadMore = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.tableView.layoutIfNeeded()
//                self.tryAutoLoadMoreIfContentNotFull()
            }
        }
    }
}

// MARK: - Actions
extension ProductListViewController {
    
    @objc private func refreshAction() {
        print("触发下拉刷新")
        isLoadMoreTriggered = false
        
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
            refreshControl.endRefreshing()
            tableView.isHidden = false
            emptyLabel.isHidden = true
            isLoadMoreTriggered = false
            
        case .empty(let message), .error(let message):
            loadingView.stopAnimating()
            refreshControl.endRefreshing()
            tableView.isHidden = false
            emptyLabel.text = message
            emptyLabel.isHidden = false
            isLoadMoreTriggered = false
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
        return viewModel.products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProductCell.reuseIdentifier,
            for: indexPath
        ) as! ProductCell
        
        let product = viewModel.products[indexPath.row]
        cell.configure(with: product)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProductListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = viewModel.products[indexPath.row]
        let detailVC = ProductDetailViewController(product: model)
        
        /// 详情页保存后交给 ViewModel 更新数据源和缓存，避免 VC 持有列表镜像。
        detailVC.onSave = { [weak self] newProduct in
            guard let self = self else { return }
            _ = self.viewModel.updateProduct(newProduct)
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ProductListViewController {
    
    /// 已废弃：自动补满一屏会和缓存、分页状态互相影响。
    /// 当前只保留方法体用于临时调试，不再主动调用。
    private func tryAutoLoadMoreIfContentNotFull() {
        guard viewModel.canLoadMore else {
            return
        }

        let contentHeight = tableView.contentSize.height
        let frameHeight = tableView.frame.size.height

        guard contentHeight > 0, contentHeight <= frameHeight else {
            return
        }

        guard !isLoadMoreTriggered else {
            return
        }

        print("真实网络首屏内容不足一屏，自动触发加载更多")
        isLoadMoreTriggered = true
        viewModel.loadData(mode: .loadMore)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.canLoadMore else {
            return
        }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height

        // frameHeight 不是用户真正可见的滚动区域高度。
        // 导航栏、safeArea、refreshControl、contentInset 都可能影响实际可视范围。
        // 上拉加载更多应该用 adjustedContentInset 修正后的 visibleHeight 来判断。
        let visibleHeight = scrollView.bounds.height
            - scrollView.adjustedContentInset.top
            - scrollView.adjustedContentInset.bottom

        guard visibleHeight > 0 else {
            return
        }

        // 内容确实没有超过可视区域时，用户没有真正的上拉加载空间。
        guard contentHeight > visibleHeight else {
            return
        }

        let distanceToBottom = contentHeight - (offsetY + visibleHeight)

        if distanceToBottom > 80 {
            isLoadMoreTriggered = false
        }

        if scrollView.isDragging && distanceToBottom <= 80 && !isLoadMoreTriggered {
            print("触发上拉加载更多，distanceToBottom: \(distanceToBottom)")
            isLoadMoreTriggered = true
            viewModel.loadData(mode: .loadMore)
        }
    }
}
