//
//  ProductDetailViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import UIKit

final class ProductDetailViewController: UIViewController {
   
    private var product: Product
    var onSave: ((Product) -> Void)?
    
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let titleTF = UITextField()
    private let bodyTF = UITextField()
    
    
    init(product: Product) {
        self.product = product
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
               title = "详情"
               view.backgroundColor = .white
               
                setupUI()
                loadData()
      
    }
    
}
extension ProductDetailViewController {
    
    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(saveButtonTapped))
        
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.numberOfLines = 0
        titleLabel.backgroundColor = .yellow
       
        
        bodyLabel.font = .systemFont(ofSize: 16)
        bodyLabel.textColor = .darkGray
        bodyLabel.backgroundColor = .blue
        bodyLabel.numberOfLines = 0
      
        titleLabel.frame = CGRect(x: 20, y: 50, width: view.bounds.width - 40, height: 80)
        bodyLabel.frame = CGRect(x: 20, y: 220, width: view.bounds.width - 40, height: 300)
        
        setupField(titleTF, placeholder: "标题")
        setupField(bodyTF, placeholder: "内容")
        titleTF.frame = CGRect(x: 20, y: bodyLabel.frame.origin.y+300+50, width: view.bounds.width - 40, height: 100)
        bodyTF.frame = CGRect(x: 20, y: titleTF.frame.origin.y+100+50, width: view.bounds.width - 40, height: 100)

        titleTF.delegate = self
        titleTF.tag = 100
        bodyTF.delegate = self
        bodyTF.tag = 200

        view.addSubview(titleLabel)
        view.addSubview(bodyLabel)
        view.addSubview(titleTF)
        view.addSubview(bodyTF)
    }
    private func setupField(_ field:UITextField, placeholder: String){
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.autocapitalizationType = .none
    }
    private func loadData() {
        titleLabel.text = "名称：\(product.title)"
        bodyLabel.text = "价格：¥\(product.body)"
        fillData()
    }
    private func fillData () {
        titleTF.text = product.title
        bodyTF.text = product.body
    }
    @objc private func saveButtonTapped() {
        
        let newProduct = Product(
            userId:product.userId, id: product.id, title: titleTF.text ?? "", body: bodyTF.text ?? ""
        )
        onSave?(newProduct)
        navigationController?.popViewController(animated: true)
    }
}
extension ProductDetailViewController:UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
     
            switch textField.tag {
            case 100:
                titleLabel.text = titleTF.text ?? ""
            case 200:
                bodyLabel.text = bodyTF.text ?? ""
            default:
                break
            }
        
    }
    
    
}
