//
//  ListItem.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/16.
//

import Foundation

/// DataFlowAdvanced 模块使用的通用列表模型。
///
/// 这里不继续使用 Product，是为了让进阶模块不绑定具体业务名称。
/// 后续无论数据来自 posts、users，还是其他接口，都可以先转换成 ListItem，
/// 再交给 ListViewModel 和 ListViewController 展示。
struct ListItem: Codable, Equatable {
    
    /// 列表数据的唯一标识。
    let id: Int
    
    /// 主标题，用于 cell 的第一行展示。
    let title: String
    
    /// 副标题，用于 cell 的第二行展示。
    let subtitle: String
}
