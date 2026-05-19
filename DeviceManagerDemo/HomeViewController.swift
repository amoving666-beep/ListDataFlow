//
//  HomeViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import UIKit

/// App 首页入口。
///
/// 这个页面不承载具体业务逻辑，只负责作为 Demo 入口：
/// 1. 普通列表版：进入当前已经完成的 ProductList 数据流闭环。
/// 2. 进阶数据流版：后续进入 DataFlowAdvanced，用来练 Repository / NetworkClient / CacheStore。
final class HomeViewController: UIViewController {
    
    private enum DemoEntry: CaseIterable {
        case productList
        case dataFlowAdvanced
        case deviceList
        case loginList
        
        var title: String {
            switch self {
            case .productList:
                return "普通列表版"
            case .dataFlowAdvanced:
                return "进阶数据流版"
            case .deviceList:
                return "设备列表"
            case .loginList:
                return "模拟登录"
            }
        }
        
        var subtitle: String {
            switch self {
            case .productList:
                return "ProductList：网络请求 / 分页 / 缓存 / 状态 / 单元测试"
            case .dataFlowAdvanced:
                return "DataFlowAdvanced：Repository / NetworkClient / CacheStore"
            case .deviceList:
                return "模拟设备列表,模拟对设备进行操作"
            case .loginList:
                return "模拟注册登录"
            }
            
        }
    }
    
    private let entries = DemoEntry.allCases
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        return tableView
    }()
    
    private static let cellIdentifier = "HomeEntryCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "DeviceManagerDemo"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func openEntry(_ entry: DemoEntry) {
        switch entry {
        case .productList:
            let viewController = ProductListViewController()
            navigationController?.pushViewController(viewController, animated: true)
            
        case .dataFlowAdvanced:
            let alert = UIAlertController(
                title: "进阶模块",
                message: "入口已预留。下一步会接入 进阶模块 链路。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "知道了", style: .destructive))
            present(alert, animated: true)
        case .deviceList:
            let viewController = DeviceListViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
            
        case .loginList:
            
            let alert = UIAlertController(
                title: "注册模块",
                message: "入口已预留。下一步会接入 注册登录 链路。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "知道了", style: .destructive))
            present(alert, animated: true)
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let entry = entries[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = entry.title
        content.secondaryText = entry.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openEntry(entries[indexPath.row])
    }
}
