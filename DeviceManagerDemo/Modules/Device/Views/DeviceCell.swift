//
//  DeviceCell.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/16.
//

import UIKit

final class DeviceCell: UITableViewCell {
    // 这些 label 只是 cell 自己内部用，所以写 private
    private let nameLabel = UILabel()
    private let groupLabel = UILabel()
    private let statusLabel = UILabel()
    private let tagLabel = UILabel()
    private var rowData: DeviceRowData?
    private let treeLineLayer = CAShapeLayer()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        groupLabel.font = UIFont.systemFont(ofSize: 13)
        statusLabel.font = UIFont.systemFont(ofSize: 13)
        tagLabel.font = UIFont.systemFont(ofSize: 12)
        
        groupLabel.textColor = .gray
        statusLabel.textColor = .systemBlue
        tagLabel.textColor = .systemRed
        
        // 加到 cell 的内容区域
        contentView.addSubview(nameLabel)
        contentView.addSubview(groupLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(tagLabel)
        treeLineLayer.strokeColor = UIColor.systemGray3.cgColor
        treeLineLayer.fillColor = UIColor.clear.cgColor
        treeLineLayer.lineWidth = 1
        contentView.layer.addSublayer(treeLineLayer)
    }
    
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        let level = rowData?.level ?? 0
        let indent = CGFloat(level) * 24
        let left: CGFloat = 16 + indent + 18
        let right: CGFloat = 16
        let width = contentView.bounds.width - left - right
        
        nameLabel.frame = CGRect(x: left, y: 10, width: width, height: 22)
        groupLabel.frame = CGRect(x: left, y: 36, width: width, height: 20)
        statusLabel.frame = CGRect(x: left, y: 60, width: 120, height: 20)
        tagLabel.frame = CGRect(x: contentView.bounds.width - 100, y: 60, width: 84, height: 20)
        updateTreeLinePath()
    }
    func configure(with row: DeviceRowData ) {
        rowData = row
        nameLabel.text = row.name
        groupLabel.text = "分组：\(row.groupName)"
        statusLabel.text = "状态：\(row.statusText)"
        tagLabel.text = row.tagText
        setNeedsLayout()
    }

    private func updateTreeLinePath() {
        guard let rowData = rowData, rowData.level > 0 else {
            treeLineLayer.path = nil
            return
        }
        
        let path = UIBezierPath()
        let level = CGFloat(rowData.level)
        let startX: CGFloat = 16 + level * 24
        let midY = contentView.bounds.height / 2
        
        // 当前节点竖线：如果是最后一个子节点，只画到当前行中间。
        path.move(to: CGPoint(x: startX, y: 0))
        path.addLine(to: CGPoint(x: startX, y: rowData.isLastChild ? midY : contentView.bounds.height))
        
        // 当前节点横线：从竖线连到文字前面。
        path.move(to: CGPoint(x: startX, y: midY))
        path.addLine(to: CGPoint(x: startX + 14, y: midY))
        
        treeLineLayer.path = path.cgPath
    }
    
}
