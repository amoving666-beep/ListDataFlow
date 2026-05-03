//
//  ProductCell.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/27.
//

import UIKit

final class ProductCell: UITableViewCell {

    static let reuseIdentifier = "ProductCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .black
        label.numberOfLines = 0
        label.backgroundColor = .systemRed
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.backgroundColor = .yellow
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        /// 这里开始不用 layoutSubviews 手动写 frame，改成 Auto Layout。
        ///        /// 一次性激活所有 Auto Layout 约束。
        /// 原因：
        /// - frame 写死高度时，文字一长就会被裁剪
        /// - Auto Layout 可以根据 label 内容自动计算 cell 高度
        /// - 配合 tableView.rowHeight = .automaticDimension，就能实现自适应高度 cell
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        /// 这里的核心目标：
        /// - titleLabel 固定在 cell 内容区域顶部
        /// - bodyLabel 放在 titleLabel 下面
        /// - 两个 label 左右对齐
        /// - bodyLabel 的底部连到 contentView 底部
        ///
        /// 为什么最后一条 bottom 约束很重要：
        /// tableView 自动计算 cell 高度时，需要知道内容从哪里开始、到哪里结束。
        /// titleLabel.topAnchor 告诉系统“内容从上面 12 开始”；
        /// bodyLabel.bottomAnchor 告诉系统“内容到下面 -12 结束”。
        /// 这样系统才能根据 titleLabel + bodyLabel 的实际文字高度，算出整个 cell 应该多高。
        NSLayoutConstraint.activate([
            /// titleLabel 顶部距离 contentView 顶部 12。
            /// 作用：让标题不要贴着 cell 顶部，留出上边距。
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            /// titleLabel 左边距离 contentView 左边 16。
            /// 作用：让标题左侧有统一内边距。
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            /// titleLabel 右边距离 contentView 右边 16。
            /// 注意这里 constant 是 -16，因为 trailingAnchor 往左缩进要用负数。
            /// 作用：限制标题最大宽度，文字超出宽度后会自动换行。
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            /// bodyLabel 顶部连接到 titleLabel 底部，并间隔 8。
            /// 作用：正文显示在标题下面，并留出标题和正文之间的间距。
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            /// bodyLabel 左边和 titleLabel 左边对齐。
            /// 作用：保证标题和正文左侧起点一致。
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            /// bodyLabel 右边和 titleLabel 右边对齐。
            /// 作用：保证正文宽度和标题宽度一致，换行区域一致。
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            /// bodyLabel 底部距离 contentView 底部 12。
            /// 注意这里 constant 是 -12，因为 bottomAnchor 往上缩进要用负数。
            ///
            /// 作用：
            /// 1. 给正文底部留出下边距
            /// 2. 告诉 Auto Layout：cell 内容到这里结束
            /// 3. 配合 tableView.rowHeight = .automaticDimension，让 cell 可以根据内容自动撑高
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        let margin: CGFloat = 16
//        let labelWidth = contentView.bounds.width - margin * 2
//
//        titleLabel.frame = CGRect(
//            x: margin,
//            y: 12,
//            width: labelWidth,
//            height: 44
//        )
//
//        bodyLabel.frame = CGRect(
//            x: margin,
//            y: titleLabel.frame.maxY + 2,
//            width: labelWidth,
//            height: 60
//        )
//    }
    
    func configure(with product: Product) {
        titleLabel.text = product.title
        bodyLabel.text = product.body
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        bodyLabel.text = nil
    }
}
