//
//  ListViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import UIKit

/// DataFlowAdvanced 模块的列表页面。
///
/// 当前页面已经从“占位数据”升级为绑定 ListViewModel：
/// - ViewController 只负责 UI、交互和渲染。
/// - ListViewModel 负责数据流、分页、状态和请求生命周期。
/// - Repository / Service / NetworkClient / CacheStore 负责底层数据来源。
final class ListViewController: UIViewController {
    
    private let viewModel = ListViewModel()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlChanged), for: .valueChanged)
        return refreshControl
    }()
    
    private let stateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    private static let cellIdentifier = "AdvancedListCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadCachedDataIfNeeded()
        viewModel.loadData(mode: .initial)
    }
    
    private func setupUI() {
        title = "进阶数据流版"
        view.backgroundColor = .systemBackground
        
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        view.addSubview(stateLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    private func bindViewModel() {
        viewModel.onItemsChanged = { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        viewModel.onViewStateChanged = { [weak self] state in
            self?.updateViewState(state)
        }
        
        viewModel.onFooterStateChanged = { [weak self] state in
            self?.updateFooterState(state)
        }
        
        viewModel.onMessage = { [weak self] message in
            self?.showMessage(message)
        }
    }
    
    @objc private func refreshControlChanged() {
        viewModel.loadData(mode: .refresh)
    }
    
    private func updateViewState(_ state: ListViewModel.ViewState) {
        refreshControl.endRefreshing()
        
        switch state {
        case .loading:
            tableView.isHidden = true
            stateLabel.isHidden = false
            stateLabel.text = "加载中..."
            
        case .content:
            tableView.isHidden = false
            stateLabel.isHidden = true
            stateLabel.text = nil
            
        case .empty(let message):
            tableView.isHidden = true
            stateLabel.isHidden = false
            stateLabel.text = message
            
        case .error(let message):
            tableView.isHidden = true
            stateLabel.isHidden = false
            stateLabel.text = message
        }
    }
    
    private func updateFooterState(_ state: ListViewModel.FooterState) {
        switch state {
        case .hidden:
            tableView.tableFooterView = nil
            
        case .loadingMore:
            tableView.tableFooterView = makeFooterLabel(text: "加载更多中...")
            
        case .noMoreData:
            tableView.tableFooterView = makeFooterLabel(text: "没有更多数据了")
        }
    }
    
    private func makeFooterLabel(text: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        label.text = text
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }
    
    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let item = viewModel.items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        
        guard contentHeight > visibleHeight else { return }
        
        if offsetY > contentHeight - visibleHeight - 80 {
            viewModel.loadData(mode: .loadMore)
        }
    }
}
