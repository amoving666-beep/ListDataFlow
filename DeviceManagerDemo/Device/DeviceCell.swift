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
    }
    
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    override func layoutSubviews() {
           super.layoutSubviews()
           
            let left: CGFloat = 16
            let right: CGFloat = 16
            let width = contentView.bounds.width - left-right
           
            nameLabel.frame = CGRect(x: left, y: 10, width: width, height: 22)
            groupLabel.frame = CGRect(x: left, y: 36, width: width, height: 20)
            statusLabel.frame = CGRect(x: left, y: 60, width: 120, height: 20)
            tagLabel.frame = CGRect(x: contentView.bounds.width - 100, y: 60, width: 84, height: 20)
       }
    func configure(with row: DeviceRowData ) {
        nameLabel.text = row.name
        groupLabel.text = "分组：\(row.groupName)"
        statusLabel.text = "状态：\(row.statusText)"
        tagLabel.text = row.tagText
    }
    
}
