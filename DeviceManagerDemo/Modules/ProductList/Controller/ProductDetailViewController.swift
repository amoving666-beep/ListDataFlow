//
//  ProductDetailViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/19.
//

import UIKit

final class ProductDetailViewController: UIViewController {
    
    // MARK: - Types
    
    private enum ProductValidationError: Error {
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
    
    // MARK: - Data
    
    private var product: Product
    
    var onSave: ((Product) -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    
    private let contentView = UIView()
    
    /// 用 stackView 承载详情和编辑控件，便于错误提示显隐时自动收起空间。
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    private let titleTF = UITextField()
    
    private let bodyTextView = UITextView()
    
    private let titleErrorLabel = UILabel()
    private let bodyErrorLabel = UILabel()
    
    private lazy var saveButtonItem = UIBarButtonItem(
        title: "保存",
        style: .plain,
        target: self,
        action: #selector(saveButtonTapped)
    )
    
    // MARK: - Init
    
    init(product: Product) {
        self.product = product
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "详情"
        view.backgroundColor = .white
        
        setupUI()
        loadData()
    }
}

// MARK: - Setup
extension ProductDetailViewController {
    
    private func setupUI() {
        navigationItem.rightBarButtonItem = saveButtonItem
        
        setupScrollView()
        setupStackView()
        setupFields()
        setupErrorLabels()
        setupDelegates()
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            /// 固定 contentView 宽度，避免多行文本高度计算不稳定。
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupStackView() {
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            /// 让 scrollView 能根据内容计算可滚动高度。
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(titleTF)
        stackView.addArrangedSubview(titleErrorLabel)
        stackView.addArrangedSubview(bodyTextView)
        stackView.addArrangedSubview(bodyErrorLabel)
        
        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        bodyLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        
        titleTF.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        bodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
    }
    
    private func setupFields() {
        setupField(titleTF, placeholder: "标题")
        setupBodyTextView()
    }
    
    private func setupField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.autocapitalizationType = .none
    }
    
    private func setupBodyTextView() {
        bodyTextView.font = .systemFont(ofSize: 16)
        bodyTextView.textColor = .black
        bodyTextView.layer.borderWidth = 1
        bodyTextView.layer.borderColor = UIColor.systemGray4.cgColor
        bodyTextView.layer.cornerRadius = 6
        bodyTextView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        bodyTextView.isScrollEnabled = false
        bodyTextView.backgroundColor = .white
    }
    
    private func setupErrorLabels() {
        setupErrorLabel(titleErrorLabel)
        setupErrorLabel(bodyErrorLabel)
    }
    
    private func setupErrorLabel(_ label: UILabel) {
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
    }
    
    private func setupDelegates() {
        titleTF.delegate = self
        bodyTextView.delegate = self
    }
}

// MARK: - Data Fill
extension ProductDetailViewController {
    
    private func loadData() {
        titleLabel.text = "标题：\(product.title)"
        bodyLabel.text = "内容：\(product.body)"
        fillData()
    }
    
    private func fillData() {
        titleTF.text = product.title
        bodyTextView.text = product.body
        updateTitleValidationUI()
        updateBodyValidationUI()
        updateSaveButtonState()
    }
}

// MARK: - Validation
extension ProductDetailViewController {
    
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
        let body = bodyTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        let body = bodyTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let titleError = validateTitle() {
            return .failure(titleError)
        }
        
        if let bodyError = validateBody() {
            return .failure(bodyError)
        }
        
        return .success((title: title, body: body))
    }
}

// MARK: - Validation UI
extension ProductDetailViewController {
    
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
            bodyTextView.layer.borderWidth = 1
            bodyTextView.layer.borderColor = UIColor.systemRed.cgColor
            bodyTextView.layer.cornerRadius = 6
        } else {
            bodyErrorLabel.text = nil
            bodyErrorLabel.isHidden = true
            bodyTextView.layer.borderWidth = 0
            bodyTextView.layer.borderColor = nil
        }
    }
    
    private func updateSaveButtonState() {
        let titleIsValid = validateTitle() == nil
        let bodyIsValid = validateBody() == nil
        saveButtonItem.isEnabled = titleIsValid && bodyIsValid
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

// MARK: - Actions
extension ProductDetailViewController {
    
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
}

// MARK: - UITextFieldDelegate
extension ProductDetailViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        switch textField {
        case titleTF:
            titleLabel.text = "标题：\(titleTF.text ?? "")"
            updateTitleValidationUI()
            updateSaveButtonState()
            
        default:
            break
        }
    }
}

// MARK: - UITextViewDelegate
extension ProductDetailViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        guard textView === bodyTextView else { return }
        
        bodyLabel.text = "内容：\(bodyTextView.text ?? "")"
        
        updateBodyValidationUI()
        updateSaveButtonState()
    }
}
