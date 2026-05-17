//
//  ListViewModel.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation
/// DataFlowAdvanced 模块的列表 ViewModel。
///
/// 职责边界：
/// - ViewModel 只负责列表数据流、分页状态、页面状态和请求生命周期。
/// - ViewModel 不直接碰 URLSession，不直接 JSONDecoder，不直接 UserDefaults。
/// - 网络和缓存来源统一交给 ListRepositoryProtocol。
final class ListViewModel {
    
    /// 当前请求意图。
    enum LoadMode {
        case initial
        case refresh
        case loadMore
    }
    
    /// 当前请求进行状态。
    enum LoadState {
        case idle
        case initialLoading
        case refreshing
        case loadingMore
    }
    
    /// 页面主状态。
    enum ViewState: Equatable {
        case loading
        case content
        case empty(String)
        case error(String)
    }
    
    /// 列表底部状态。
    enum FooterState: Equatable {
        case hidden
        case loadingMore
        case noMoreData
    }
    
    private let repository: ListRepositoryProtocol
    private let pageSize: Int
    
    private(set) var items: [ListItem] = []
    private(set) var currentPage: Int = 0
    private(set) var hasMoreData: Bool = true
    private(set) var loadState: LoadState = .idle
    private(set) var viewState: ViewState = .loading
    private(set) var footerState: FooterState = .hidden
    
    private var currentTask: URLSessionTask?
    private var currentRequestID: Int = 0
    
    var onItemsChanged: (([ListItem]) -> Void)?
    var onViewStateChanged: ((ViewState) -> Void)?
    var onFooterStateChanged: ((FooterState) -> Void)?
    var onMessage: ((String) -> Void)?
    
    init(
        repository: ListRepositoryProtocol = ListRepository(),
        pageSize: Int = 20
    ) {
        self.repository = repository
        self.pageSize = pageSize
    }
    
    /// 读取缓存数据。
    ///
    /// 这个方法通常在页面首次进入时调用。
    /// 如果有缓存，先展示旧数据，再发起网络请求刷新。
    func loadCachedDataIfNeeded() {
        guard let cachedItems = repository.loadCachedList(), !cachedItems.isEmpty else {
            return
        }
        
        items = cachedItems
        viewState = .content
        onItemsChanged?(items)
        onViewStateChanged?(viewState)
    }
    
    /// 加载数据。
    ///
    /// - Parameter mode: 请求意图，区分首次加载、下拉刷新、上拉加载更多。
    func loadData(mode: LoadMode) {
       
        guard canStartLoading(mode: mode) else { return }
        
        let targetPage = makeTargetPage(mode: mode)
        beginLoading(mode: mode)
        
        currentRequestID += 1
        let requestID = currentRequestID
        
        currentTask = repository.fetchList(page: targetPage, pageSize: pageSize) { [weak self] result in
            
            guard let self = self else { return }
            
            guard requestID == self.currentRequestID else {
                return
            }
            
            self.finishLoading()
            
            switch result {
            case .success(let newItems):
                self.handleLoadSuccess(newItems, mode: mode, targetPage: targetPage)
                
            case .failure(let error):
                self.handleLoadFailure(error, mode: mode)
            }
        }
    }
    
    /// 清除进阶列表缓存。
    func clearCache() {
        repository.clearCachedList()
    }
    
    private func canStartLoading(mode: LoadMode) -> Bool {
        switch mode {
        case .initial, .refresh:
            return true
        case .loadMore:
            return loadState == .idle && hasMoreData
        }
    }
    
    private func makeTargetPage(mode: LoadMode) -> Int {
        switch mode {
        case .initial, .refresh:
            return 1
        case .loadMore:
            return currentPage + 1
        }
    }
    
    private func beginLoading(mode: LoadMode) {
        switch mode {
        case .initial:
            loadState = .initialLoading
            if items.isEmpty {
                viewState = .loading
                onViewStateChanged?(viewState)
            }
            
        case .refresh:
            currentTask?.cancel()
            currentTask = nil
            loadState = .refreshing
            
        case .loadMore:
            loadState = .loadingMore
            footerState = .loadingMore
            onFooterStateChanged?(footerState)
        }
    }
    
    private func finishLoading() {
        loadState = .idle
    }
    
    private func handleLoadSuccess(_ newItems: [ListItem], mode: LoadMode, targetPage: Int) {
        switch mode {
        case .initial, .refresh:
            items = newItems
            currentPage = targetPage
            
        case .loadMore:
            items.append(contentsOf: newItems)
            currentPage = targetPage
        }
        
        hasMoreData = newItems.count >= pageSize
        viewState = items.isEmpty ? .empty("暂无数据") : .content
        footerState = hasMoreData ? .hidden : .noMoreData
        
        onItemsChanged?(items)
        onViewStateChanged?(viewState)
        onFooterStateChanged?(footerState)
    }
    
    private func handleLoadFailure(_ error: DataFlowNetworkError, mode: LoadMode) {
        switch mode {
        case .initial:
            if items.isEmpty {
                viewState = .error("网络异常，请稍后重试")
                onViewStateChanged?(viewState)
            } else {
                viewState = .content
                onViewStateChanged?(viewState)
                onMessage?("刷新失败，请稍后重试")
            }
            
        case .refresh:
            if items.isEmpty {
                viewState = .error("网络异常，请稍后重试")
                onViewStateChanged?(viewState)
            } else {
                viewState = .content
                onViewStateChanged?(viewState)
                onMessage?("刷新失败，请稍后重试")
            }
            
        case .loadMore:
            footerState = .hidden
            onFooterStateChanged?(footerState)
            onMessage?("加载更多失败，请稍后重试")
        }
    }
}
