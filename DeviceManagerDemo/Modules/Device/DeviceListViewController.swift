//
//  DeviceListViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/16.
//

import UIKit

final class DeviceListViewController: UIViewController {
      
   // 当前页面内部细节，写 private
    private let tableView = UITableView(frame: .zero, style: .plain)
   
    //列表真正的数据源
    private var rowDataList:[DeviceRowData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadData()
    }
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "设备列表"
        
        //导航栏按钮：新增、修改、删除
        let addItem = UIBarButtonItem(title: "新增设备", style: .plain, target: self, action: #selector(addButtonTapped))
        
        let updateItem = UIBarButtonItem(
            title: "修改", style: .plain, target: self, action: #selector(updateBttonTapped))
        
        let deleteItem = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteButtonTapped))
        navigationItem.rightBarButtonItems = [deleteItem, updateItem, addItem]
    }
    
    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 90
        
        // 注册自定义 cell
        tableView.register(DeviceCell.self, forCellReuseIdentifier: "DeviceCell")
        view.addSubview(tableView)
    }
    
    private func loadData() {
        rowDataList = [
        DeviceRowData(name: "A-深圳南山01", groupName: "南山商圈", statusText: "在线", tagText: "主屏"),
        DeviceRowData(name: "A-福田中心02", groupName: "福田商圈", statusText: "离线", tagText: "备用"),
        DeviceRowData(name: "A-宝安机场03", groupName: "机场线", statusText: "在线", tagText: "高优先")
        
        ]
        tableView.reloadData()
    }
    
    // MARK: - Day7 动作方法
    private func addOneItem() {
        let newRow = DeviceRowData(
            name: "A-新增设备",
            groupName: "未分组",
            statusText: "在线",
            tagText: "新设备"
        )
        rowDataList.append(newRow)
        tableView.reloadData()
    }
    private func updateFirstItem() {
        guard !rowDataList.isEmpty else {
            return
        }
        rowDataList[0].tagText = "重点巡检"
        tableView.reloadData()
        
    }
    private func removeLastItem() {
        guard !rowDataList.isEmpty else {
            return
        }
        rowDataList.removeLast()
        tableView.reloadData()
    }
    // MARK: - 按钮入口方法
    
    @objc private func addButtonTapped() {
        addOneItem()
    }
    @objc private func updateBttonTapped() {
        updateFirstItem()
    }
    @objc private func deleteButtonTapped() {
        removeLastItem()
    }
}

// MARK: - UITableViewDataSource
extension DeviceListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as? DeviceCell else { return UITableViewCell()
        }
        let row = rowDataList[indexPath.row]
        cell.configure(with: row)
        
        return cell
        
    }
}
// MARK: - UITableViewDelegate
extension DeviceListViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //当前点击这一行的数据
        let row = rowDataList[indexPath.row]
        
        //创建详情页
        let detailVC = DeviceDetailViewController()
        detailVC.rowData = row
        
        // Day8 回传：详情页保存后，把新数据传回列表页
        detailVC.onSave = { [weak self] newRowData in self?.rowDataList[indexPath.row] = newRowData
            self?.tableView.reloadData()
            
        }
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
