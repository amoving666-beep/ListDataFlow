//
//  ListViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import UIKit

/// DataFlowAdvanced 模块的列表页面。
///
/// 当前阶段先把页面入口跑通：
/// - 能从 HomeViewController push 进来
/// - 页面有明确标题
/// - tableView 能展示一组临时占位数据
///
/// 后续再逐步接入：
/// ListViewModel → ListRepository → ListService → NetworkClient / CacheStore
final class ListViewController: UIViewController {
    
    private let items = [
        "Repository 数据层",
        "NetworkClient 网络层",
        "CacheStore 缓存层",
        "Endpoint 请求配置",
        "ListViewModel 状态管理"
    ]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        return tableView
    }()
    
    private static let cellIdentifier = "AdvancedListCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "进阶数据流版"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let title = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = title
        content.secondaryText = "DataFlowAdvanced 第 \(indexPath.row + 1) 个能力点"
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    
}
