//
//  DeviceRowData.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/16.
//

import Foundation

struct DeviceRowData {
    var name: String
    var groupName: String
    var statusText: String
    var tagText: String
    
    var children: [DeviceRowData] = []
    var isExpanded: Bool = false
    var level: Int = 0
    var isLastChild: Bool = false
}
