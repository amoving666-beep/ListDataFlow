# DeviceManagerDemo

一个基于 Swift + UIKit 的列表数据流工程样本，重点练习真实业务列表页中的网络层封装、分页刷新、请求生命周期、并发安全和 ViewModel 单元测试。

## 项目重点

- Swift + UIKit 列表数据流工程
- 轻量 MVVM 拆分
- Endpoint + NetworkClient 网络层
- Supabase RPC 分页接口
- ApiResponse<T> / PageResponse<T> 通用响应模型
- initial / refresh / loadMore 请求入口管理
- currentTask / requestID 防旧请求污染
- Home 首页五接口并发请求聚合
- XCTest 覆盖 ViewModel 核心数据流


## 技术栈

**UI**
- UIKit
- UITableView
- Auto Layout

**Architecture**
- MVVM
- Protocol-based Dependency Injection
- Closure Callback

**Networking**
- URLSession
- Endpoint
- ApiResponse<T>
- PageResponse<T>
- Supabase RPC

**State & Concurrency**
- LoadMode / LoadState
- URLSessionDataTask Cancel
- requestID
- DispatchGroup

**Persistence & Testing**
- UserDefaults Cache
- XCTest
- Mock Service

## 模块结构

```text
DeviceManagerDemo
├── Modules
│   ├── Home
│   │   ├── HomeViewController.swift
│   │   └── HomeViewModel.swift
│   │
│   └── ProductList
│       ├── Controller
│       │   ├── ProductListViewController.swift
│       │   ├── ProductListViewModel.swift
│       │   └── ProductDetailViewController.swift
│       │
│       ├── Service
│       │   ├── ProductServiceProtocol.swift
│       │   ├── ProductService.swift
│       │   ├── ProductEndpoint.swift
│       │   ├── NetworkClient.swift
│       │   └── NetworkError.swift
│       │
│       ├── Model
│       ├── View
│       └── Helpers
│
└── DeviceManagerDemoTests
```
---

## 已实现能力

- 分页加载 / 下拉刷新
- 本地缓存兜底
- loading / empty / error 页面状态
- Endpoint + NetworkClient 网络层
- ApiResponse<T> / PageResponse<T>
- Supabase RPC 分页接口
- requestID 防旧回调污染
- 请求取消与并发控制
- Home 五接口并发聚合
- XCTest + MockService

## 后续优化

- Repository 层
- NetworkClient 独立测试
- Cache 协议化
- 图片缓存
- diffable data source
- SwiftLint / CI

