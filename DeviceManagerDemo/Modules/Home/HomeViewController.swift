//
//  HomeViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import UIKit

final class HomeViewController: UIViewController {
    
    /// HomeVC 当前复用 ProductListViewModel 。
    private let homeViewModel = HomeViewModel()
    
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
        tableView.refreshControl = refreshControl
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private let homeHeaderView = HomeHeaderView()
    private var didSetupHeaderView = false
    
    private static let cellIdentifier = "HomeEntryCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HomeViewController viewDidLoad")
        setupUI()
        bindHomeViewModel()
        loadHomeData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard tableView.bounds.width > 0 else {
            return
        }

        if !didSetupHeaderView {
            setupHeaderView()
            didSetupHeaderView = true
        }

        updateTableHeaderLayoutIfNeeded()
    }
    
    private func setupUI() {
        title = "DeviceManagerDemo"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .always
        
        view.addSubview(tableView)
        refreshControl.addTarget(self, action: #selector(refreshHomeData), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeaderView() {
        homeHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 285)
        tableView.tableHeaderView = homeHeaderView
    }

    private func updateTableHeaderLayoutIfNeeded() {
        guard tableView.tableHeaderView === homeHeaderView else {
            return
        }

        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else {
            return
        }

        let targetSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = homeHeaderView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        let targetHeight = max(285, fittingSize.height)
        guard homeHeaderView.frame.width != targetWidth || homeHeaderView.frame.height != targetHeight else {
            return
        }

        homeHeaderView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        tableView.tableHeaderView = homeHeaderView
    }
    
    private func bindHomeViewModel() {
        homeViewModel.onHomeDataChanged = { [weak self] in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            self.updateHeaderView()
            self.tableView.reloadData()
        }

        homeViewModel.onHomeStateChanged = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                self.homeHeaderView.configureStatus(
                    title: "首页辅助接口待加载",
                    subtitle: "等待 userInfo / banner / recommend / unreadCount"
                )

            case .loading:
                self.homeHeaderView.configureStatus(
                    title: "首页辅助接口加载中",
                    subtitle: "正在并发请求 productList / userInfo / banner / recommend / unreadCount"
                )

            case .content:
                self.homeHeaderView.configureStatus(
                    title: "接口状态：全部成功",
                    subtitle: "主接口成功，副接口也全部返回"
                )

            case .partialContent(let message):
                self.homeHeaderView.configureStatus(
                    title: "接口状态：部分成功",
                    subtitle: message
                )

            case .failed(let message):
                self.homeHeaderView.configureStatus(
                    title: "接口状态：主接口失败",
                    subtitle: message
                )
            }

            self.updateTableHeaderLayoutIfNeeded()
        }
    }
    
    private func loadHomeData() {
        homeViewModel.loadHomeData()
    }
    
    @objc private func refreshHomeData() {
        loadHomeData()
    }
    
    private func updateHeaderView() {
        homeHeaderView.configure(
            userInfo: homeViewModel.userInfo,
            unreadCount: homeViewModel.unreadCount,
            banners: homeViewModel.banners,
            recommendProducts: homeViewModel.recommendProducts,
            productCount: homeViewModel.homeProducts.count
        )
        updateTableHeaderLayoutIfNeeded()
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
//            let viewController = DeviceListViewController()
//            self.navigationController?.pushViewController(viewController, animated: true)
            
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return entries.count
        case 1:
            return min(homeViewModel.recommendProducts.count, 2)
        case 2:
            return min(homeViewModel.homeProducts.count, 3)
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "工程模块入口"
        case 1:
            return homeViewModel.recommendProducts.isEmpty ? nil : "推荐商品接口返回"
        case 2:
            return homeViewModel.homeProducts.isEmpty ? nil : "商品列表接口预览"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.secondaryTextProperties.color = .secondaryLabel
        content.imageProperties.tintColor = .systemBlue
        
        switch indexPath.section {
        case 0:
            let entry = entries[indexPath.row]
            content.text = entry.title
            content.secondaryText = entry.subtitle
            content.image = UIImage(systemName: iconName(for: entry))
            cell.accessoryType = .disclosureIndicator
            
        case 1:
            let product = homeViewModel.recommendProducts[indexPath.row]
            content.text = product.title
            content.secondaryText = product.body
            content.image = UIImage(systemName: "star.circle.fill")
            cell.accessoryType = .none
            
        case 2:
            let product = homeViewModel.homeProducts[indexPath.row]
            content.text = product.title
            content.secondaryText = product.body
            content.image = UIImage(systemName: "shippingbox.fill")
            cell.accessoryType = .none
            
        default:
            break
        }
        
        cell.contentConfiguration = content
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.layer.cornerRadius = 12
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    private func iconName(for entry: DemoEntry) -> String {
        switch entry {
        case .productList:
            return "list.bullet.rectangle"
        case .dataFlowAdvanced:
            return "point.3.connected.trianglepath.dotted"
        case .deviceList:
            return "externaldrive.connected.to.line.below"
        case .loginList:
            return "person.crop.circle.badge.checkmark"
        }
    }
}


extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 30
        default:
            return 38
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 else {
            return
        }
        
        openEntry(entries[indexPath.row])
    }
}
