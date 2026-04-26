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
    private var isLoadMoreTriggered = false  ///防暴力刷新
    /// 空页面提示
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
        
        /// 1. 先读缓存，先把旧数据展示出来
            loadCache()
             
        
        /// 2. 再请求最新第一页
        loadData(isRefresh: true)
    }

}
extension ProductListViewController {
    
    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.tableFooterView = UIView()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProductCell")
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
        
            beginLoading()
        
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
    private func beginLoading() {
        isLoading = true
    }
    
    ///结束请求：恢复请求状态，并停止下拉刷新动画
    private func finishLoading() {
        isLoading = false
        refreshControl.endRefreshing()
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
    private func handleLoadSuccess(_ list: [Product],isRefresh: Bool,targetPage: Int) {
        
        if isRefresh {
            ///下拉刷新：直接替换数据
            productList = list
            currentPage = 1
        }else{
            ///上拉加载更多：把新数据追加到旧数据后面
            productList.append(contentsOf: list)
            currentPage = targetPage
        }
        
        /// 如果这一页返回的数据数量 < pageSize,说明后面没更多了
        hasMoreData = list.count == pageSize
        
        /// 请求成功后，保存最新缓存
        saveCache()
        
        reloadListUI()
        
        print("当前页: \(self.currentPage), 当前总条数: \(self.productList.count)")
        
    }
    /// 请求失败后的处理
    private func handleLoadFailure(_ error: Error) {
        print("请求失败：\(error.localizedDescription)")
    }
    
    /// 刷新列表相关 UI
    private func reloadListUI() {
        tableView.reloadData()
        updateEmptyView()
    }


}
extension ProductListViewController{
    
    ///保存缓存
    private func saveCache() {
        do{
            
            let data = try JSONEncoder().encode(productList)
            UserDefaults.standard.set(data, forKey: cacheKey)
        }catch{
            print("缓存保存失败：\(error.localizedDescription)")
        }
    }
    ///加载缓存
    private func loadCache() {
        
        guard let data = UserDefaults.standard.data(forKey: cacheKey)else{
            updateEmptyView()
            return
        }
        do{
            let cacheList = try JSONDecoder().decode([Product].self, from: data)
         
            productList = cacheList
            reloadListUI()
            print("读取缓存成功，缓存条数：\(cacheList.count)")
        }catch{
            print("缓存读取失败：\(error.localizedDescription)")
            updateEmptyView()
        }
        
    }
    ///清楚缓存
    private func clearCache() {
        
        UserDefaults.standard.removeObject(forKey: cacheKey)
        print("缓存已删除")
    }
    
    @objc func clearCacheBtnAction() {
        clearCache()
    }
    @objc func lookButtonTapped() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey)else{
            print("无缓存")
            return
        }
        do{
            let cacheList = try JSONDecoder().decode([Product].self, from: data)
         
            print("读取缓存成功，缓存条数：\(cacheList.count)")
        }catch{
            print("缓存读取失败：\(error.localizedDescription)")
        }
        
    }
}
// MARK: - Empty View
extension ProductListViewController {
    
    private func updateEmptyView(){
        emptyLabel.isHidden = !productList.isEmpty
        
    }
    
}
    
extension ProductListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
        
        let model = productList[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
            content.text = model.title
            
            content.secondaryText = model.body
            content.secondaryTextProperties.numberOfLines = 0
            cell.contentConfiguration = content
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
extension ProductListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = productList[indexPath.row]
        let detailVC = ProductDetailViewController(product: model)
        detailVC.onSave = {[weak self] newProduct in
            self?.productList[indexPath.row] = newProduct
    
            self?.saveCache()
            
///            self?.tableView.reloadData()
            self?.tableView.reloadRows(at: [indexPath], with:.automatic)
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
