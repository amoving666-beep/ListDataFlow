//
//  DeviceDetailViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/16.
//

import UIKit

final class DeviceDetailViewController: UIViewController {

    // 列表页传过来的旧数据
    var rowData: DeviceRowData?
    
    // 保存后，把新数据回传给列表页
    var onSave:  ((DeviceRowData) -> Void)?

    //输入框
    private let nameField = UITextField()
    private let groupField = UITextField()
    private let statusField = UITextField()
    private let tagField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fillData()
    }
    private func setupUI() {
        view.backgroundColor = .white
        title = "设备详情"
        
        //右上角保存按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存", style: .plain, target: self, action: #selector(saveButtonTapped)
        )
        
        //给输入框配基础样式
        setupField(nameField, placeholder: "设备名称")
        setupField(groupField, placeholder:  "分组状态")
        setupField(statusField, placeholder: "状态")
        setupField(tagField, placeholder: "标签")
        
        //摆位置，当前先用 frame, 狗你现在练主线
        nameField.frame = CGRect(x: 20, y: 120, width: view.bounds.width - 40, height: 40)
        groupField.frame = CGRect(x: 20, y: 180, width: view.bounds.width - 40, height: 40)
        statusField.frame = CGRect(x: 20, y: 240, width: view.bounds.width - 40, height: 40)
        tagField.frame = CGRect(x: 20, y: 300, width: view.bounds.width - 40, height: 40)
        
        view.addSubview(nameField)
        view.addSubview(groupField)
        view.addSubview(statusField)
        view.addSubview(tagField)
    }
    private func setupField(_ field:UITextField, placeholder: String){
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.autocapitalizationType = .none
    }
    

    private func fillData() {
        nameField.text = rowData?.name
        groupField.text = rowData?.groupName
        statusField.text = rowData?.statusText
        tagField.text = rowData?.tagText
    }
    
    
    @objc private func saveButtonTapped() {
        //重新组装一份新数据
        let newRow = DeviceRowData(
            name: nameField.text ?? "",
            groupName: groupField.text ?? "",
            statusText: statusField.text ?? "",
            tagText: tagField.text ?? ""
        )
        // 会传给列表页
        onSave?(newRow)
        
        //返回上一页
        navigationController?.popViewController(animated: true)
        
    }

}
