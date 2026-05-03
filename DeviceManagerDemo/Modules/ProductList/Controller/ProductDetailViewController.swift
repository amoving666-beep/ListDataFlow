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
    
    /// 保存成功后回传给列表页
    var onSave: ((Product) -> Void)?
    
    // MARK: - UI Components
    
    /// 滚动容器
    ///
    /// 为什么要加 UIScrollView：
    /// - 详情页 body 内容可能很长
    /// - 如果页面继续用固定 frame，内容超出屏幕会显示不全
    /// - 放进 scrollView 后，内容超过屏幕高度时可以上下滚动
    private let scrollView = UIScrollView()
    
    /// scrollView 内部真正承载内容的容器
    ///
    /// 注意：
    /// scrollView 负责滚动，contentView 负责装 UI。
    /// 后面所有 label / textField 都加到 contentView 或 stackView 中。
    private let contentView = UIView()
    
    /// 垂直布局容器
    ///
    /// 为什么用 UIStackView：
    /// - 当前详情页元素是从上到下排列
    /// - 用 stackView 比手写一堆 y 值更稳
    /// - label 内容变高时，下面的输入框会自动往下排
    /// - errorLabel 隐藏时，stackView 会自动收起它占用的空间
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
    
    /// 正文输入框
    ///
    /// 为什么正文不用 UITextField：
    /// - UITextField 适合单行输入，比如标题、手机号、搜索词
    /// - 正文 body 可能很长，UITextField 单行显示体验很差
    /// - UITextView 支持多行编辑，更适合文章内容、备注、描述类输入
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
            /// scrollView 贴满当前页面安全区域。
            /// 这样内容如果超过屏幕高度，就能在安全区域内滚动。
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            /// contentView 四边绑定到 scrollView 的 contentLayoutGuide。
            /// contentLayoutGuide 代表 scrollView 内部“可滚动内容区域”。
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            /// contentView 宽度等于 scrollView 的可见宽度。
            ///
            /// 这条很关键：
            /// - 没有这条，Auto Layout 不知道内容区应该多宽
            /// - label 也就不知道按多宽换行
            /// - bodyLabel 的多行高度就可能算不准
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func setupStackView() {
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            /// stackView 顶部距离 contentView 顶部 20
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            
            /// 左右各留 20 的边距
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            /// stackView 底部连到 contentView 底部
            ///
            /// 这条很重要：
            /// scrollView 需要知道内容到底到哪里结束，才能计算可滚动高度。
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        /// 从上到下加入页面元素。
        ///
        /// 顺序决定页面显示顺序：
        /// 标题展示 -> 内容展示 -> 标题输入 -> 标题错误 -> 内容输入 -> 内容错误
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(titleTF)
        stackView.addArrangedSubview(titleErrorLabel)
        stackView.addArrangedSubview(bodyTextView)
        stackView.addArrangedSubview(bodyErrorLabel)
        
        /// label 设置“最小高度”。
        ///
        /// 注意：这里不要用 equalToConstant 写死高度。
        /// 如果写成 equalToConstant，label 高度就固定死了，长文本又会显示不全。
        ///
        /// greaterThanOrEqualToConstant 的意思是：
        /// - 内容少时，至少保持这个高度，页面不会太扁
        /// - 内容多时，可以继续自动撑高，不会被裁剪
        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        bodyLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        
        /// 输入框固定高度 44。
        /// label 不固定高度，让它们根据文字内容自动撑开。
        titleTF.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        /// 正文输入区域使用 UITextView，给一个较大的最小高度。
        ///
        /// 注意这里也不要写成固定高度。
        /// greaterThanOrEqualToConstant 表示：
        /// - 内容少时，至少有 120 高度，方便输入
        /// - 内容多时，后面可以继续升级为自适应高度
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
        
        /// bodyTextView 是多行输入控件。
        /// 输入内容变化时，同步更新上方 bodyLabel 的展示文案。
        bodyLabel.text = "内容：\(bodyTextView.text ?? "")"
        
        updateBodyValidationUI()
        updateSaveButtonState()
    }
}
