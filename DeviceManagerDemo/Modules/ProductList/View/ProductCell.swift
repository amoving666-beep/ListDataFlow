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
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 1
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 16
        let labelWidth = contentView.bounds.width - margin * 2
        
        titleLabel.frame = CGRect(
            x: margin,
            y: 12,
            width: labelWidth,
            height: 24
        )
        
        bodyLabel.frame = CGRect(
            x: margin,
            y: titleLabel.frame.maxY + 8,
            width: labelWidth,
            height: 60
        )
    }
    
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
