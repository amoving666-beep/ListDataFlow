//
//  HomeHeaderView.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/25.
//

import UIKit

final class HomeHeaderView: UIView {
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func configure(
        userInfo: UserInfo?,
        unreadCount: Int,
        banners: [Banner],
        recommendProducts: [Product],
        productCount: Int
    ) {
        let userName = userInfo?.name ?? "未获取用户"
        let userLevel = userInfo?.level ?? "未知等级"

        statusTitleLabel.text = "接口状态：辅助数据已返回"
        statusSubtitleLabel.text = "用户：\(userName) · 等级：\(userLevel) · 未读：\(unreadCount) · 商品：\(productCount)"

        unreadBadgeLabel.text = "\(unreadCount)"
        unreadBadgeLabel.isHidden = unreadCount <= 0

        if let firstBanner = banners.first {
            bannerTitleLabel.text = "Banner：\(firstBanner.title)"
            bannerSubtitleLabel.text = firstBanner.linkUrl
        } else {
            bannerTitleLabel.text = "Banner：暂无数据"
            bannerSubtitleLabel.text = "副接口失败或返回为空，主列表入口不受影响"
        }

        if let firstRecommend = recommendProducts.first {
            recommendTitleLabel.text = "推荐商品：\(firstRecommend.title)"
        } else {
            recommendTitleLabel.text = "推荐商品：暂无数据"
        }
    }

    func configureStatus(title: String, subtitle: String) {
        statusTitleLabel.text = title
        statusSubtitleLabel.text = subtitle
    }

    private func setupUI() {
        backgroundColor = .clear

        projectTitleLabel.text = "DeviceManagerDemo"
        projectTitleLabel.font = .boldSystemFont(ofSize: 28)
        projectTitleLabel.textColor = .label

        projectSubtitleLabel.text = "Swift + UIKit 工程 Demo 首页"
        projectSubtitleLabel.font = .systemFont(ofSize: 14)
        projectSubtitleLabel.textColor = .secondaryLabel

        unreadBadgeLabel.font = .boldSystemFont(ofSize: 13)
        unreadBadgeLabel.textColor = .white
        unreadBadgeLabel.backgroundColor = .systemRed
        unreadBadgeLabel.textAlignment = .center
        unreadBadgeLabel.layer.cornerRadius = 12
        unreadBadgeLabel.clipsToBounds = true
        unreadBadgeLabel.isHidden = true

        setupCard(statusCardView)
        setupCard(bannerCardView)

        statusTitleLabel.font = .boldSystemFont(ofSize: 16)
        statusTitleLabel.textColor = .label
        statusTitleLabel.text = "接口状态：等待加载"

        statusSubtitleLabel.font = .systemFont(ofSize: 13)
        statusSubtitleLabel.textColor = .secondaryLabel
        statusSubtitleLabel.numberOfLines = 0
        statusSubtitleLabel.text = "首页会并发请求用户、Banner、推荐、未读和商品列表"

        bannerTitleLabel.font = .boldSystemFont(ofSize: 16)
        bannerTitleLabel.textColor = .label
        bannerTitleLabel.text = "Banner：等待加载"

        bannerSubtitleLabel.font = .systemFont(ofSize: 13)
        bannerSubtitleLabel.textColor = .secondaryLabel
        bannerSubtitleLabel.numberOfLines = 0
        bannerSubtitleLabel.text = "副接口失败不影响主列表展示"

        recommendTitleLabel.font = .systemFont(ofSize: 14)
        recommendTitleLabel.textColor = .secondaryLabel
        recommendTitleLabel.numberOfLines = 1
        recommendTitleLabel.text = "推荐商品：等待加载"

        addSubview(projectTitleLabel)
        addSubview(projectSubtitleLabel)
        addSubview(unreadBadgeLabel)
        addSubview(statusCardView)
        addSubview(bannerCardView)

        statusCardView.addSubview(statusTitleLabel)
        statusCardView.addSubview(statusSubtitleLabel)

        bannerCardView.addSubview(bannerTitleLabel)
        bannerCardView.addSubview(bannerSubtitleLabel)
        bannerCardView.addSubview(recommendTitleLabel)

        [
            projectTitleLabel,
            projectSubtitleLabel,
            unreadBadgeLabel,
            statusCardView,
            bannerCardView,
            statusTitleLabel,
            statusSubtitleLabel,
            bannerTitleLabel,
            bannerSubtitleLabel,
            recommendTitleLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            projectTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            projectTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            projectTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: unreadBadgeLabel.leadingAnchor, constant: -12),

            unreadBadgeLabel.centerYAnchor.constraint(equalTo: projectTitleLabel.centerYAnchor),
            unreadBadgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            unreadBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            unreadBadgeLabel.heightAnchor.constraint(equalToConstant: 24),

            projectSubtitleLabel.topAnchor.constraint(equalTo: projectTitleLabel.bottomAnchor, constant: 6),
            projectSubtitleLabel.leadingAnchor.constraint(equalTo: projectTitleLabel.leadingAnchor),
            projectSubtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            statusCardView.topAnchor.constraint(equalTo: projectSubtitleLabel.bottomAnchor, constant: 18),
            statusCardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            statusCardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            statusTitleLabel.topAnchor.constraint(equalTo: statusCardView.topAnchor, constant: 16),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor, constant: 16),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor, constant: -16),

            statusSubtitleLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 8),
            statusSubtitleLabel.leadingAnchor.constraint(equalTo: statusTitleLabel.leadingAnchor),
            statusSubtitleLabel.trailingAnchor.constraint(equalTo: statusTitleLabel.trailingAnchor),
            statusSubtitleLabel.bottomAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: -16),

            bannerCardView.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 12),
            bannerCardView.leadingAnchor.constraint(equalTo: statusCardView.leadingAnchor),
            bannerCardView.trailingAnchor.constraint(equalTo: statusCardView.trailingAnchor),
            bannerCardView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            bannerTitleLabel.topAnchor.constraint(equalTo: bannerCardView.topAnchor, constant: 16),
            bannerTitleLabel.leadingAnchor.constraint(equalTo: bannerCardView.leadingAnchor, constant: 16),
            bannerTitleLabel.trailingAnchor.constraint(equalTo: bannerCardView.trailingAnchor, constant: -16),

            bannerSubtitleLabel.topAnchor.constraint(equalTo: bannerTitleLabel.bottomAnchor, constant: 8),
            bannerSubtitleLabel.leadingAnchor.constraint(equalTo: bannerTitleLabel.leadingAnchor),
            bannerSubtitleLabel.trailingAnchor.constraint(equalTo: bannerTitleLabel.trailingAnchor),

            recommendTitleLabel.topAnchor.constraint(equalTo: bannerSubtitleLabel.bottomAnchor, constant: 10),
            recommendTitleLabel.leadingAnchor.constraint(equalTo: bannerTitleLabel.leadingAnchor),
            recommendTitleLabel.trailingAnchor.constraint(equalTo: bannerTitleLabel.trailingAnchor),
            recommendTitleLabel.bottomAnchor.constraint(equalTo: bannerCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupCard(_ view: UIView) {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
    }
}
