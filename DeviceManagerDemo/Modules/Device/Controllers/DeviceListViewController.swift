//
//  DeviceListViewController.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/16.
//

import UIKit

final class DeviceListViewController: UIViewController {
      
    private var treeArray: [DeviceRowData] = []
    private var displayArray: [DeviceRowData] = []
    
   // 当前页面内部细节，写 private
    private let tableView = UITableView(frame: .zero, style: .plain)
   
    
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
        
        // 导航栏按钮：全部展开、新增、修改、删除
        let expandItem = UIBarButtonItem(title: "全部展开", style: .plain, target: self, action: #selector(expandAllButtonTapped))
        
        let addItem = UIBarButtonItem(title: "新增设备", style: .plain, target: self, action: #selector(addButtonTapped))
        
        let updateItem = UIBarButtonItem(
            title: "修改", style: .plain, target: self, action: #selector(updateBttonTapped))
        
        let deleteItem = UIBarButtonItem(title: "删除", style: .plain, target: self, action: #selector(deleteButtonTapped))
        navigationItem.rightBarButtonItems = [deleteItem, updateItem, addItem, expandItem]
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
    
    private func loadData()
    {
        treeArray = [
            DeviceRowData(
                name: "南山商圈",
                groupName: "一级分组",
                statusText: "在线",
                tagText: "父节点",
                children: [
                    DeviceRowData(name: "A-深圳南山01", groupName: "南山商圈", statusText: "在线", tagText: "主屏"),
                    DeviceRowData(name: "A-深圳南山02", groupName: "南山商圈", statusText: "离线", tagText: "备用")
                ]
            ),
            DeviceRowData(
                name: "福田商圈",
                groupName: "一级分组",
                statusText: "在线",
                tagText: "父节点",
                children: [
                    DeviceRowData(name: "A-福田中心02", groupName: "福田商圈", statusText: "离线", tagText: "备用")
                ]
            ),
            DeviceRowData(
                name: "机场线",
                groupName: "一级分组",
                statusText: "在线",
                tagText: "父节点",
                children: [
                    DeviceRowData(name: "A-宝安机场03", groupName: "机场线", statusText: "在线", tagText: "高优先")
                ]
            )
        ]
        treeArray = expandAll(treeArray)
        reloadDisplayArray()
    }
    
    // MARK: - Day7 动作方法
    private func addOneItem() {
        let newRow = DeviceRowData(
            name: "A-新增设备",
            groupName: "未分组",
            statusText: "在线",
            tagText: "新设备"
        )
        treeArray.append(newRow)
        reloadDisplayArray()
    }
    private func updateFirstItem()
    {
        guard !treeArray.isEmpty else {
            return
        }
        treeArray[0].tagText = "重点巡检"
        reloadDisplayArray()
    }
    private func removeLastItem()
    {
        guard !treeArray.isEmpty else {
            return
        }
        treeArray.removeLast()
        reloadDisplayArray()
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
    
    @objc private func expandAllButtonTapped() {
        treeArray = expandAll(treeArray)
        reloadDisplayArray()
    }
    
    
    private func expandAll(_ nodes: [DeviceRowData]) -> [DeviceRowData] {
        return nodes.map { node in
            var newNode = node
            newNode.isExpanded = true
            newNode.children = expandAll(node.children)
            return newNode
        }
    }

    private func reloadDisplayArray() {
        displayArray.removeAll()
        buildDisplayArray(from: treeArray, level: 0)
        tableView.reloadData()
    }

    private func buildDisplayArray(from nodes: [DeviceRowData], level: Int) {
        for index in nodes.indices {
            var node = nodes[index]
            node.level = level
            node.isLastChild = index == nodes.index(before: nodes.endIndex)
            displayArray.append(node)

            if node.isExpanded {
                buildDisplayArray(from: node.children, level: level + 1)
            }
        }
    }
    
    private func updateNode(named oldName: String, with newRow: DeviceRowData, in nodes: inout [DeviceRowData]) -> Bool {
        for index in nodes.indices {
            if nodes[index].name == oldName {
                var updatedRow = newRow
                updatedRow.children = nodes[index].children
                updatedRow.isExpanded = nodes[index].isExpanded
                nodes[index] = updatedRow
                return true
            }

            if updateNode(named: oldName, with: newRow, in: &nodes[index].children) {
                return true
            }
        }

        return false
    }
    
}

// MARK: - UITableViewDataSource
extension DeviceListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as? DeviceCell else { return UITableViewCell()
        }
        let row = displayArray[indexPath.row]
        cell.configure(with: row)
        
        return cell
        
    }
}
// MARK: - UITableViewDelegate
extension DeviceListViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //当前点击这一行的数据
        let row = displayArray[indexPath.row]
        
        //创建详情页
        let detailVC = DeviceDetailViewController()
        detailVC.rowData = row
        
        // Day8 回传：详情页保存后，把新数据传回列表页
        detailVC.onSave = { [weak self] newRowData in
            guard let self = self else { return }
            _ = self.updateNode(named: row.name, with: newRowData, in: &self.treeArray)
            self.reloadDisplayArray()
        }
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
