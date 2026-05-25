//
//  PageResponse.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/5/19.
//

import Foundation

/// 通用分页响应模型。

struct PageResponse<T: Codable>: Codable {

    let list: [T]

    let page: Int

    let pageSize: Int

    let total: Int
}
