//
//  ProductDetailViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import UIKit

final class ProductDetailViewController: UIViewController {
   
    private enum ProductValidationError : Error {
        case emptyTitle
        case emptyBody
        case titleTooLong
        case bodyTooLong
        
        var message: String {
            
            switch self {
            case .emptyTitle:
                return "标题不能为空"
                
            case .emptyBody:
                return "内容不能为空"
                
            case .titleTooLong:
                return "标题不能超过 80 个字符"
                
            case .bodyTooLong:
                return "内容不能超过 500 个字符"
                
            }
        }
    }
    private var product: Product
    
    var onSave: ((Product) -> Void)?
    
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let titleTF = UITextField()
    private let bodyTF = UITextField()
    private let titleErrorLabel = UILabel()
    private let bodyErrorLabel = UILabel()
    private lazy var saveButtonItem = UIBarButtonItem(
        title: "保存",
        style: .plain,
        target: self,
        action: #selector(saveButtonTapped)
    )
    
    
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
        navigationItem.rightBarButtonItem = saveButtonItem
        
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
        setupErrorLabel(titleErrorLabel)
        setupErrorLabel(bodyErrorLabel)
        
        titleTF.frame = CGRect(x: 20, y: bodyLabel.frame.origin.y + 300 + 50, width: view.bounds.width - 40, height: 44)
        titleErrorLabel.frame = CGRect(x: 20, y: titleTF.frame.maxY + 6, width: view.bounds.width - 40, height: 20)
        bodyTF.frame = CGRect(x: 20, y: titleErrorLabel.frame.maxY + 20, width: view.bounds.width - 40, height: 44)
        bodyErrorLabel.frame = CGRect(x: 20, y: bodyTF.frame.maxY + 6, width: view.bounds.width - 40, height: 20)

        titleTF.delegate = self
        titleTF.tag = 100
        bodyTF.delegate = self
        bodyTF.tag = 200

        view.addSubview(titleLabel)
        view.addSubview(bodyLabel)
        view.addSubview(titleTF)
        view.addSubview(titleErrorLabel)
        view.addSubview(bodyTF)
        view.addSubview(bodyErrorLabel)
    }
    private func setupField(_ field:UITextField, placeholder: String){
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.autocapitalizationType = .none
    }

    private func setupErrorLabel(_ label: UILabel) {
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.isHidden = true
    }
    private func loadData() {
        titleLabel.text = "名称：\(product.title)"
        bodyLabel.text = "价格：¥\(product.body)"
        fillData()
    }
    private func fillData () {
        titleTF.text = product.title
        bodyTF.text = product.body
        updateTitleValidationUI()
        updateBodyValidationUI()
        updateSaveButtonState()
    }
    
    private func validateTitle() -> ProductValidationError? {
        let title = titleTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if title.isEmpty {
            return .emptyTitle
        }
        
        if title.count > 80 {
            return .titleTooLong
        }
        return nil
    }
    
    private func validateBody() -> ProductValidationError? {

        let body = bodyTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if body.isEmpty {
            return .emptyBody
        }
        if body.count > 500 {
            return .bodyTooLong
        }
        return nil
    }

    private func validateInput() -> Result<(title: String, body: String), ProductValidationError> {
       
        let title = titleTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = bodyTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if let titleError = validateTitle() {
            return .failure(titleError)
        }
        
        if let bodyError = validateBody() {
            return .failure(bodyError)
        }
        
        return .success((title: title, body: body))
    }

    private func updateTitleValidationUI() {
        if let error = validateTitle() {
            titleErrorLabel.text = error.message
            titleErrorLabel.isHidden = false
            titleTF.layer.borderWidth = 1
            titleTF.layer.borderColor = UIColor.systemRed.cgColor
            titleTF.layer.cornerRadius = 6
        } else {
            titleErrorLabel.text = nil
            titleErrorLabel.isHidden = true
            titleTF.layer.borderWidth = 0
            titleTF.layer.borderColor = nil
        }
    }
    
    private func updateBodyValidationUI() {
        if let error = validateBody() {
            bodyErrorLabel.text = error.message
            bodyErrorLabel.isHidden = false
            bodyTF.layer.borderWidth = 1
            bodyTF.layer.borderColor = UIColor.systemRed.cgColor
            bodyTF.layer.cornerRadius = 6
        } else {
            bodyErrorLabel.text = nil
            bodyErrorLabel.isHidden = true
            bodyTF.layer.borderWidth = 0
            bodyTF.layer.borderColor = nil
        }
    }

    private func updateSaveButtonState() {
        let titleIsValid = validateTitle() == nil
        let bodyIsValid = validateBody() == nil
        saveButtonItem.isEnabled = titleIsValid && bodyIsValid
    }
    @objc private func saveButtonTapped() {
        switch validateInput() {
        case .success(let input):
            let newProduct = Product(
                userId: product.userId,
                id: product.id,
                title: input.title,
                body: input.body
            )
            onSave?(newProduct)
            navigationController?.popViewController(animated: true)
            
        case .failure(let error):
            showValidationError(error)
        }
    }

    private func showValidationError(_ error: ProductValidationError) {
        updateTitleValidationUI()
        updateBodyValidationUI()
        updateSaveButtonState()
        
        let alert = UIAlertController(title: "输入有误", message: error.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}
extension ProductDetailViewController:UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
     
            switch textField.tag {
            case 100:
                titleLabel.text = titleTF.text ?? ""
                updateTitleValidationUI()
            case 200:
                bodyLabel.text = bodyTF.text ?? ""
                updateBodyValidationUI()
            default:
                break
            }
            updateSaveButtonState()
    }
    
    
}
