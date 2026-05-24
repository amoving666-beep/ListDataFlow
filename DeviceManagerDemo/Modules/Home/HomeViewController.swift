//
//  HomeViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import UIKit

/// App 首页入口。
///
/// 这个页面负责展示当前工程 Demo 的主入口，
/// 同时承载首页副接口并发请求结果：
/// 1. 用户信息
/// 2. Banner 信息
/// 3. 推荐商品
/// 4. 未读消息数
///
/// 注意：
/// 商品列表分页主链路仍然由 ProductListViewController 管理，
/// HomeVC 只消费首页辅助接口，不接管 ProductList 的 products 数据源。
final class HomeViewController: UIViewController {
    
    /// HomeVC 当前复用 ProductListViewModel 的首页辅助接口能力。
    ///
    /// 当前阶段先不新增 HomeViewModel，
    /// 目的是集中学习 taskMap / requestIDMap 的多请求管理。
    /// 后续如果首页逻辑继续增多，应单独拆出 HomeViewModel。
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
        return tableView
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private let headerContainerView = UIView()
    private let projectTitleLabel = UILabel()
    private let projectSubtitleLabel = UILabel()
    private let unreadBadgeLabel = UILabel()
    private let statusCardView = UIView()
    private let statusTitleLabel = UILabel()
    private let statusSubtitleLabel = UILabel()
    private let bannerCardView = UIView()
    private let bannerTitleLabel = UILabel()
    private let bannerSubtitleLabel = UILabel()
    private let recommendTitleLabel = UILabel()
    private var didSetupHeaderView = false
    
    private static let cellIdentifier = "HomeEntryCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        headerContainerView.backgroundColor = .clear
        headerContainerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 285)
        
        projectTitleLabel.font = .systemFont(ofSize: 25, weight: .bold)
        projectTitleLabel.textColor = .label
        projectTitleLabel.text = "Swift 工程练习总控"
        
        projectSubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        projectSubtitleLabel.textColor = .secondaryLabel
        projectSubtitleLabel.numberOfLines = 2
        projectSubtitleLabel.text = "UIKit · 网络层 · 分页缓存 · 并发请求 · 单元测试"
        
        unreadBadgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        unreadBadgeLabel.textColor = .white
        unreadBadgeLabel.textAlignment = .center
        unreadBadgeLabel.backgroundColor = .systemRed
        unreadBadgeLabel.layer.cornerRadius = 14
        unreadBadgeLabel.layer.masksToBounds = true
        unreadBadgeLabel.text = "0"
        unreadBadgeLabel.isHidden = true
        
        statusCardView.backgroundColor = .secondarySystemGroupedBackground
        statusCardView.layer.cornerRadius = 16
        statusCardView.layer.masksToBounds = true
        
        statusTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        statusTitleLabel.textColor = .label
        statusTitleLabel.text = "首页辅助接口加载中"
        
        statusSubtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusSubtitleLabel.textColor = .secondaryLabel
        statusSubtitleLabel.numberOfLines = 2
        statusSubtitleLabel.text = "userInfo / banner / recommend / unreadCount"
        
        bannerCardView.backgroundColor = .secondarySystemGroupedBackground
        bannerCardView.layer.cornerRadius = 16
        bannerCardView.layer.masksToBounds = true
        
        bannerTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        bannerTitleLabel.textColor = .label
        bannerTitleLabel.text = "Banner 加载中"
        
        bannerSubtitleLabel.font = .systemFont(ofSize: 13)
        bannerSubtitleLabel.textColor = .secondaryLabel
        bannerSubtitleLabel.text = "等待副接口返回"
        bannerSubtitleLabel.numberOfLines = 2
        
        recommendTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        recommendTitleLabel.textColor = .secondaryLabel
        recommendTitleLabel.text = "推荐商品加载中"
        recommendTitleLabel.numberOfLines = 2
        
        [
            projectTitleLabel,
            projectSubtitleLabel,
            unreadBadgeLabel,
            statusCardView,
            bannerCardView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerContainerView.addSubview($0)
        }
        
        [
            statusTitleLabel,
            statusSubtitleLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            statusCardView.addSubview($0)
        }
        
        [
            bannerTitleLabel,
            bannerSubtitleLabel,
            recommendTitleLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            bannerCardView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            projectTitleLabel.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 18),
            projectTitleLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 20),
            projectTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: unreadBadgeLabel.leadingAnchor, constant: -12),
            
            unreadBadgeLabel.centerYAnchor.constraint(equalTo: projectTitleLabel.centerYAnchor),
            unreadBadgeLabel.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -20),
            unreadBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            unreadBadgeLabel.heightAnchor.constraint(equalToConstant: 28),
            
            projectSubtitleLabel.topAnchor.constraint(equalTo: projectTitleLabel.bottomAnchor, constant: 6),
            projectSubtitleLabel.leadingAnchor.constraint(equalTo: projectTitleLabel.leadingAnchor),
            projectSubtitleLabel.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -20),
            
            statusCardView.topAnchor.constraint(equalTo: projectSubtitleLabel.bottomAnchor, constant: 16),
            statusCardView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 20),
            statusCardView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -20),
            statusCardView.heightAnchor.constraint(equalToConstant: 68),
            
            statusTitleLabel.topAnchor.constraint(equalTo: statusCardView.topAnchor, constant: 13),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor, constant: 16),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor, constant: -16),
            
            statusSubtitleLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 5),
            statusSubtitleLabel.leadingAnchor.constraint(equalTo: statusTitleLabel.leadingAnchor),
            statusSubtitleLabel.trailingAnchor.constraint(equalTo: statusTitleLabel.trailingAnchor),
            
            bannerCardView.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 12),
            bannerCardView.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor),
            bannerCardView.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor),
            bannerCardView.heightAnchor.constraint(equalToConstant: 104),
            
            bannerTitleLabel.topAnchor.constraint(equalTo: bannerCardView.topAnchor, constant: 13),
            bannerTitleLabel.leadingAnchor.constraint(equalTo: bannerCardView.leadingAnchor, constant: 16),
            bannerTitleLabel.trailingAnchor.constraint(equalTo: bannerCardView.trailingAnchor, constant: -16),
            
            bannerSubtitleLabel.topAnchor.constraint(equalTo: bannerTitleLabel.bottomAnchor, constant: 5),
            bannerSubtitleLabel.leadingAnchor.constraint(equalTo: bannerTitleLabel.leadingAnchor),
            bannerSubtitleLabel.trailingAnchor.constraint(equalTo: bannerTitleLabel.trailingAnchor),
            
            recommendTitleLabel.topAnchor.constraint(equalTo: bannerSubtitleLabel.bottomAnchor, constant: 10),
            recommendTitleLabel.leadingAnchor.constraint(equalTo: bannerTitleLabel.leadingAnchor),
            recommendTitleLabel.trailingAnchor.constraint(equalTo: bannerTitleLabel.trailingAnchor)
        ])
        
        tableView.tableHeaderView = headerContainerView
    }

    private func updateTableHeaderLayoutIfNeeded() {
        guard tableView.tableHeaderView === headerContainerView else {
            return
        }

        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else {
            return
        }

        let targetSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = headerContainerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        let targetHeight = max(285, fittingSize.height)
        guard headerContainerView.frame.width != targetWidth || headerContainerView.frame.height != targetHeight else {
            return
        }

        headerContainerView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        tableView.tableHeaderView = headerContainerView
    }
    
    private func bindHomeViewModel() {
        homeViewModel.onHomeDataChanged = { [weak self] in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            self.updateHeaderView()
            self.tableView.reloadData()
        }
    }
    
    private func loadHomeData() {
        homeViewModel.loadHomeData()
    }
    
    @objc private func refreshHomeData() {
        loadHomeData()
    }
    
    private func updateHeaderView() {
        let userName = homeViewModel.userInfo?.name ?? "未获取用户"
        let userLevel = homeViewModel.userInfo?.level ?? "未知等级"
        
        statusTitleLabel.text = "接口状态：辅助数据已返回"
        statusSubtitleLabel.text = "用户：\(userName) · 等级：\(userLevel) · 未读：\(homeViewModel.unreadCount) · 商品：\(homeViewModel.homeProducts.count)"
        
        unreadBadgeLabel.text = "\(homeViewModel.unreadCount)"
        unreadBadgeLabel.isHidden = homeViewModel.unreadCount <= 0
        
        if let firstBanner = homeViewModel.banners.first {
            bannerTitleLabel.text = "Banner：\(firstBanner.title)"
            bannerSubtitleLabel.text = firstBanner.linkUrl
        } else {
            bannerTitleLabel.text = "Banner：暂无数据"
            bannerSubtitleLabel.text = "副接口失败或返回为空，主列表入口不受影响"
        }
        
        if let firstRecommend = homeViewModel.recommendProducts.first {
            recommendTitleLabel.text = "推荐商品：\(firstRecommend.title)"
        } else {
            recommendTitleLabel.text = "推荐商品：暂无数据"
        }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 else {
            return
        }
        
        openEntry(entries[indexPath.row])
    }
}
