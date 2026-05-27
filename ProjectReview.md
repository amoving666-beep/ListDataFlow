
# ProjectReview

## 项目定位

ListDataFlow 是一个基于 Swift + UIKit 的列表数据流工程样本。

项目不追求复杂 UI，而是围绕真实业务列表页，验证以下工程能力：

- 网络层封装
- 分页与刷新数据流
- 请求生命周期管理
- 弱网与旧请求回调保护
- 本地缓存兜底
- MVVM 职责拆分
- 协议抽象与依赖注入
- ViewModel 单元测试
- 基础性能与内存排查

核心目标：把一个普通 UITableView 页面，整理成具备网络、缓存、并发安全和测试能力的小型 UIKit 工程样本。

---

## 阶段一：列表数据流闭环

### 做了什么

- UITableView 列表展示
- initial / refresh / loadMore 数据入口
- currentPage / pageSize / hasMoreData 分页状态
- loading / content / empty / error 页面状态
- footer loading / noMoreData 状态
- 详情页编辑回传

### 解决的问题

初版列表逻辑集中在 ViewController，分页、请求、状态渲染和数据更新混在一起。

本阶段先打通完整列表数据流，明确 refresh 是替换数据，loadMore 是追加数据，并保证请求失败时不直接清空已有列表。

### 关键取舍

没有在一开始引入复杂架构，而是先保证业务链路完整，再逐步拆分职责。

---

## 阶段二：真实业务网络层

### 做了什么

- Endpoint / ProductEndpoint
- HTTPMethod
- NetworkClient
- NetworkError
- ApiResponse<T>
- PageResponse<T>
- Supabase RPC 分页接口
- ProductServiceProtocol

请求链路升级为：

```text
Endpoint → NetworkClient → ProductService → ViewModel
```

### 解决的问题

原始写法中 URL、请求参数、解析逻辑都集中在 Service，扩展性和测试性差。

升级后：

- Endpoint 负责接口描述
- NetworkClient 负责请求执行与响应解析
- ProductService 负责业务接口封装
- ViewModel 只处理列表数据流

### 关键取舍

没有直接引入第三方网络库，而是基于 URLSession 实现最小可控网络层，便于理解请求构建、HTTP 状态码、业务 code、解码失败等关键路径。

---

## 阶段三：请求生命周期与并发安全

### 做了什么

- LoadMode 区分 initial / refresh / loadMore
- LoadState 控制请求入口
- currentTask 取消旧请求
- requestID 防止旧回调污染新数据
- cancelled 错误分流
- RequestKey / taskMap / requestIDMap 管理多请求
- Home 首页五接口并发聚合

### 解决的问题

真实列表页在弱网下容易出现：

- 连续刷新导致重复请求
- refresh 与 loadMore 状态冲突
- 旧请求晚返回覆盖新数据
- 多接口页面互相取消或互相污染

本阶段将“请求是否还有效”从请求结果中独立出来处理。

### 关键取舍

currentTask 只能减少无意义请求，但不能完全防止旧回调。

真正防数据污染的是 requestID：回调时先校验身份，旧请求即使返回，也没有资格写入最新数据。

---

## 阶段四：网络层与 ViewModel 测试

### 做了什么

- Endpoint 构建测试
- NetworkClient 响应解析测试
- ProductService 测试
- ProductListViewModelTests
- MockProductService
- ControlledMockProductService
- requestID 异步回调顺序测试

### 解决的问题

分页、缓存、请求取消和 requestID 叠加后，手工点击已经无法稳定验证所有分支。

测试重点放在：

- 请求成功后的数据更新
- refresh / loadMore 分支差异
- 请求失败后的状态恢复
- 旧请求晚返回是否会污染数据
- updateProduct 是否正确更新本地列表

### 关键取舍

优先测试 ViewModel 数据流，而不是 UI。

原因是核心风险集中在状态变化和异步回调顺序，UI 层只负责渲染结果。

---

## 阶段五：本地持久化升级

### 做了什么

- ProductCacheStoreProtocol
- FileManager JSON 缓存
- CoreDataStack
- ProductEntity
- Product 与 ProductEntity 映射
- CoreDataProductCacheStore
- in-memory CoreData 测试

### 解决的问题

初期缓存直接绑定具体实现，ViewModel 对缓存细节感知过多。

升级后 ViewModel 只依赖 ProductCacheStoreProtocol，不关心底层是 FileManager 还是 CoreData。

### 关键取舍

FileManager 适合轻量 JSON 缓存，CoreData 更接近真实业务持久化场景。

这里重点不是深挖 CoreData，而是验证缓存层可替换、可测试、可独立演进。

---

## 阶段六：性能与稳定性基础排查

### 做了什么

- Memory Graph 检查页面释放
- Instruments 基础排查
- closure 循环引用处理
- weak self 使用检查
- 主线程 UI 更新检查
- 大量数据下的分页与缓存验证

### 解决的问题

项目中存在多个 closure 回调：

- 网络 completion
- ViewModel 状态回调
- 详情页 onSave
- 首页并发请求回调

这些都是循环引用高发点。

本阶段重点验证页面 pop 后是否释放，以及 UI 更新是否回到主线程。

### 关键取舍

没有把项目包装成“性能优化项目”。

当前阶段只做基础稳定性治理：先能发现泄漏、能解释卡顿来源、能用工具验证问题。

---

## 阶段七：理论回补与项目对齐

### 做了什么

围绕项目中实际用到的点，回补：

- GCD / 主线程 / 队列
- ARC / weak self / 循环引用
- RunLoop
- Objective-C Runtime

### 解决的问题

避免理论和项目割裂。

比如：

- GCD 对应网络回调和主线程刷新
- ARC 对应 closure 与页面释放
- RunLoop 对应主线程卡顿、Timer、事件循环
- Runtime 对应 Objective-C 老项目维护和动态机制理解

### 关键取舍

不追源码细节，不做理论堆砌。

只补能支撑项目解释和面试追问的核心机制。

---

## 当前项目边界

ListDataFlow 当前不是完整商业 App，也不是企业级架构模板。

它更准确的定位是：

一个围绕 UIKit 列表页构建的数据流工程样本。

已经覆盖：

- 网络请求
- 分页刷新
- 请求取消
- 旧请求保护
- 本地缓存
- CoreData 持久化
- ViewModel 测试
- 基础稳定性排查

尚未覆盖：

- Repository 层完整抽象
- 图片加载与图片缓存
- UI Test
- SwiftLint / CI
- 更完整的重试策略

---

## 可延展讨论点

- requestID 如何避免旧请求污染新数据
- currentTask 与 requestID 的职责边界
- ProductServiceProtocol 如何支撑 ViewModel 单元测试
- ProductCacheStoreProtocol 如何隔离 FileManager / CoreData 实现
- 为什么优先测试 ViewModel 数据流，而不是直接测试 UI
- FileManager 缓存与 CoreData 缓存的适用边界