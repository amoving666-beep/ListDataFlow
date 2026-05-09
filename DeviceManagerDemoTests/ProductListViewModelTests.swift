//
//  ProductListViewModelTests.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/6.
//

// 引入 Apple 的单元测试框架。
// XCTest 提供 XCTAssertEqual / XCTAssertTrue / XCTestCase 等测试能力。
import XCTest

// 让测试 Target 可以访问主工程里的 internal 类型和方法。
// 没有 @testable，测试代码通常访问不到主工程中默认 internal 的类、方法和属性。
@testable import DeviceManagerDemo

// ProductListViewModelTests 专门测试 ProductListViewModel 的数据流逻辑。
//
// 测试边界：
// - 只测 ViewModel
// - 不测真实 URLSession
// - 不测 ProductService 底层 data / response / error
// - 不测 UI Test
//
// 测试方式：
// - MockProductService 控制输入
// - ProductListViewModel 执行业务逻辑
// - XCTest 检查输出结果
final class ProductListViewModelTests: XCTestCase {

    // MARK: - Initial
    
    func testInitialSuccess_updatesProductsAndShowsContent() {

        // Given：准备假 Service，让它模拟“首次加载请求成功”
        // 这里必须注入 MockProductService，而不是 ProductService。
        // 目的：当前测试只验证 ViewModel，不依赖真实网络。
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)
        
        let mockProducts = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]

        // 设置 MockService 的返回值。
        // 注意：这句只是告诉 MockService “下一次请求要返回什么”，不会主动触发 ViewModel 加载数据。
        mockService.result = .success(mockProducts)

        // 下面三个变量用来记录 ViewModel 是否通过输出闭包通知了外部。
        // 在真实 App 中，外部是 VC；在单元测试里，测试代码扮演这个外部接收者。
        var didCallOnProductsChanged = false
        var didReceiveContentState = false
        var didReceiveNoMoreDataFooterState = false

        // ViewModel 成功更新 products 后，会通过 onProductsChanged 把最新数组传给外部。
        viewModel.onProductsChanged = { products in
            didCallOnProductsChanged = true
            XCTAssertEqual(products.count, 2, "onProductsChanged 回调里的 products 数量应该是 2")
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .content:
                didReceiveContentState = true
            default:
                break
            }
        }

        viewModel.onFooterStateChanged = { state in
            switch state {
            case .noMoreData:
                didReceiveNoMoreDataFooterState = true
            default:
                break
            }
        }

        // When：执行首次加载
        viewModel.loadData(mode: .initial)

        // Then：验证 initial 请求第一页
        XCTAssertEqual(mockService.requestedPage, 1, "initial 模式应该请求第 1 页")

        // Then：验证 ViewModel 把 pageSize 正确传给 Service
        XCTAssertEqual(mockService.requestedPageSize, 10, "ViewModel 应该把 pageSize = 10 传给 Service")

        // Then：验证请求成功后，ViewModel 成功保存 products 数量
        XCTAssertEqual(viewModel.products.count, 2, "请求成功后，ViewModel.products 数量应该是 2")

        // Then：验证第一条 Product 的 id / title / body 都正确
        XCTAssertEqual(viewModel.products.first?.id, 1, "第一条 Product 的 id 应该正确")
        XCTAssertEqual(viewModel.products.first?.title, "标题1", "第一条 Product 的 title 应该正确")
        XCTAssertEqual(viewModel.products.first?.body, "内容1", "第一条 Product 的 body 应该正确")

        // Then：验证最后一条 Product 的 id / title / body 都正确
        XCTAssertEqual(viewModel.products.last?.id, 2, "最后一条 Product 的 id 应该正确")
        XCTAssertEqual(viewModel.products.last?.title, "标题2", "最后一条 Product 的 title 应该正确")
        XCTAssertEqual(viewModel.products.last?.body, "内容2", "最后一条 Product 的 body 应该正确")

        // Then：验证 ViewModel 请求成功后通知 VC 刷新列表
        XCTAssertTrue(didCallOnProductsChanged, "请求成功后应该触发 onProductsChanged")

        // Then：验证 initial 成功并且有数据时，页面最终进入 content 状态
        XCTAssertTrue(didReceiveContentState, "initial 成功且有数据时，ViewState 应该进入 content")

        // Then：验证返回数据数量小于 pageSize 时，footer 进入 noMoreData 状态
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "返回数据数量小于 pageSize 时，FooterState 应该进入 noMoreData")

    }

    // MARK: - Refresh
    
    func testRefreshSuccess_replacesOldProducts() {
        // Given：先准备旧数据，让 ViewModel 处于已经有列表内容的状态
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]

        // 第一次请求：让 MockService 返回旧数据。
        // 这一步是真的执行 initial 请求，目的是先把 ViewModel 填成旧列表状态。
        mockService.result = .success(oldProducts)
        viewModel.loadData(mode: .initial)

        let newProducts = [
            makeProduct(id: 3, title: "新标题3", body: "新内容3"),
            makeProduct(id: 4, title: "新标题4", body: "新内容4")
        ]

        // 第二次请求前，修改 MockService 的返回值为新数据。
        // 注意：这句不会自动改变 viewModel.products。
        // 只有下面执行 loadData(mode: .refresh) 时，ViewModel 才会拿到 3、4。
        mockService.result = .success(newProducts)

        var didCallOnProductsChanged = false
        var didReceiveContentState = false
        var didReceiveNoMoreDataFooterState = false

        viewModel.onProductsChanged = { products in
            didCallOnProductsChanged = true
            XCTAssertEqual(products.count, 2, "refresh 成功后回调出去的 products 数量应该是新数据数量")
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .content:
                didReceiveContentState = true
            default:
                break
            }
        }

        viewModel.onFooterStateChanged = { state in
            switch state {
            case .noMoreData:
                didReceiveNoMoreDataFooterState = true
            default:
                break
            }
        }

        // When：执行下拉刷新
        viewModel.loadData(mode: .refresh)

        // Then：验证 refresh 请求第一页
        XCTAssertEqual(mockService.requestedPage, 1, "refresh 模式应该重新请求第 1 页")

        // Then：验证 refresh 成功后 products 是新数据数量，不是旧数据 + 新数据
        XCTAssertEqual(viewModel.products.count, 2, "refresh 成功后应该替换旧数据，而不是 append")

        // Then：验证第一条数据已经变成新数据
        XCTAssertEqual(viewModel.products.first?.id, 3, "refresh 后第一条应该是新数据 id = 3")
        XCTAssertEqual(viewModel.products.first?.title, "新标题3", "refresh 后第一条 title 应该是新标题")
        XCTAssertEqual(viewModel.products.first?.body, "新内容3", "refresh 后第一条 body 应该是新内容")

        // Then：验证最后一条数据已经变成新数据
        XCTAssertEqual(viewModel.products.last?.id, 4, "refresh 后最后一条应该是新数据 id = 4")
        XCTAssertEqual(viewModel.products.last?.title, "新标题4", "refresh 后最后一条 title 应该是新标题")
        XCTAssertEqual(viewModel.products.last?.body, "新内容4", "refresh 后最后一条 body 应该是新内容")

        // Then：验证旧数据已经不存在，证明 refresh 是 replace，不是 append
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 1 }), "refresh 后不应该再包含旧数据 id = 1")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 2 }), "refresh 后不应该再包含旧数据 id = 2")

        // Then：验证 ViewModel 请求成功后通知 VC 刷新列表
        XCTAssertTrue(didCallOnProductsChanged, "refresh 成功后应该触发 onProductsChanged")

        // Then：验证 refresh 成功并且有数据时，页面保持 content 状态
        XCTAssertTrue(didReceiveContentState, "refresh 成功且有数据时，ViewState 应该是 content")

        // Then：验证返回数据数量小于 pageSize 时，footer 进入 noMoreData 状态
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "refresh 返回数据数量小于 pageSize 时，FooterState 应该进入 noMoreData")
    }

    // MARK: - Load More
    func testLoadMoreSuccess_appendsNewProducts() {
        // Given：先准备第一页数据，让 ViewModel 处于“还有下一页”的状态
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }

        // 第一次请求：让 MockService 返回满一页数据。
        // 这一步是真的执行 initial 请求，目的是让 hasMoreData = true，后面 loadMore 才不会被拦截。
        mockService.result = .success(oldProducts)
        viewModel.loadData(mode: .initial)

        let newProducts = [
            makeProduct(id: 11, title: "第二页标题11", body: "第二页内容11"),
            makeProduct(id: 12, title: "第二页标题12", body: "第二页内容12")
        ]

        // 第二次请求前，修改 MockService 的返回值为第二页数据。
        // 注意：这句不会自动改变 viewModel.products。
        // 只有下面执行 loadData(mode: .loadMore) 时，ViewModel 才会拿到 11、12 并追加到旧数据后面。
        mockService.result = .success(newProducts)

        var didCallOnProductsChanged = false
        var didReceiveContentState = false
        var didReceiveNoMoreDataFooterState = false

        viewModel.onProductsChanged = { products in
            didCallOnProductsChanged = true
            XCTAssertEqual(products.count, 12, "loadMore 成功后回调出去的 products 数量应该是第一页 10 条 + 第二页 2 条")
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .content:
                didReceiveContentState = true
            default:
                break
            }
        }

        viewModel.onFooterStateChanged = { state in
            switch state {
            case .noMoreData:
                didReceiveNoMoreDataFooterState = true
            default:
                break
            }
        }
        // When：执行上拉加载更多
        viewModel.loadData(mode: .loadMore)

        // Then：验证 loadMore 请求 currentPage + 1，也就是第 2 页
        XCTAssertEqual(mockService.requestedPage, 2, "loadMore 模式应该请求第 2 页")

        // Then：验证 loadMore 成功后 products 是第一页 + 第二页的总数量
        XCTAssertEqual(viewModel.products.count, 12, "loadMore 成功后应该 append 第二页数据，而不是 replace")

        // Then：验证第一页第一条数据仍然保留，证明 loadMore 不是 replace
        XCTAssertEqual(viewModel.products.first?.id, 1, "loadMore 后第一条仍然应该是第一页 id = 1")
        XCTAssertEqual(viewModel.products.first?.title, "第一页标题1", "loadMore 后第一条 title 应该保持第一页数据")
        XCTAssertEqual(viewModel.products.first?.body, "第一页内容1", "loadMore 后第一条 body 应该保持第一页数据")

        // Then：验证第二页数据追加在列表最后
        XCTAssertEqual(viewModel.products.last?.id, 12, "loadMore 后最后一条应该是第二页 id = 12")
        XCTAssertEqual(viewModel.products.last?.title, "第二页标题12", "loadMore 后最后一条 title 应该是第二页数据")
        XCTAssertEqual(viewModel.products.last?.body, "第二页内容12", "loadMore 后最后一条 body 应该是第二页数据")

        // Then：验证第一页旧数据仍然存在，证明 loadMore 是 append，不是 replace
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 1 }), "loadMore 后应该保留第一页旧数据 id = 1")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 10 }), "loadMore 后应该保留第一页旧数据 id = 10")

        // Then：验证第二页新数据已经追加进来
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 11 }), "loadMore 后应该包含第二页新数据 id = 11")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 12 }), "loadMore 后应该包含第二页新数据 id = 12")

        // Then：验证 ViewModel 请求成功后通知 VC 刷新列表
        XCTAssertTrue(didCallOnProductsChanged, "loadMore 成功后应该触发 onProductsChanged")

        // Then：验证 loadMore 成功并且有数据时，页面保持 content 状态
        XCTAssertTrue(didReceiveContentState, "loadMore 成功且有数据时，ViewState 应该是 content")

        // Then：验证第二页返回数量小于 pageSize 时，footer 进入 noMoreData 状态
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "loadMore 返回数据数量小于 pageSize 时，FooterState 应该进入 noMoreData")

    }

    // MARK: - Failure
    func testInitialFailureWithoutOldData_showsError() {
        // Given：准备一个没有旧数据的 ViewModel
        // 这里不先执行 initial success，也不手动塞 products。
        // 目的：模拟用户第一次进入页面，列表里完全没有可兜底的数据。
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        // Given：让 MockService 模拟请求失败
        // 当前测试只测 ViewModel 如何处理 failure，不测 ProductService 底层 data / response / error。
        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))

        var didReceiveErrorState = false
        var didReceiveContentState = false
        var didReceiveEmptyState = false
        var didCallOnProductsChanged = false

        viewModel.onProductsChanged = { _ in
            didCallOnProductsChanged = true
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .error:
                didReceiveErrorState = true
            case .content:
                didReceiveContentState = true
            case .empty:
                didReceiveEmptyState = true
            default:
                break
            }
        }

        // When：执行首次加载
        viewModel.loadData(mode: .initial)

        // Then：验证 initial 请求第一页
        XCTAssertEqual(mockService.requestedPage, 1, "initial failure 也应该请求第 1 页")

        // Then：验证请求失败后，products 仍然为空
        XCTAssertEqual(viewModel.products.count, 0, "无旧数据时 initial 失败，products 应该仍然为空")

        // Then：验证无旧数据的 initial failure 会进入 error 状态
        XCTAssertTrue(didReceiveErrorState, "无旧数据时 initial 请求失败，ViewState 应该进入 error")

        // Then：验证 initial failure 不应该进入 content 状态
        XCTAssertFalse(didReceiveContentState, "无旧数据时 initial 请求失败，不应该进入 content")

        // Then：验证 initial failure 不应该误判为 empty
        XCTAssertFalse(didReceiveEmptyState, "请求失败不是请求成功但空数据，不应该进入 empty")

        // Then：验证请求失败没有新数据，不应该触发 products 更新
        XCTAssertFalse(didCallOnProductsChanged, "initial 失败没有新数据，不应该触发 onProductsChanged")
    }

    func testRefreshFailureWithOldData_keepsOldProductsAndShowsMessage() {
        // Given：先准备旧数据，让 ViewModel 处于已经有内容可展示的状态。
        // refresh failure 和 initial failure 最大区别：
        // - initial failure 没有旧数据，所以应该显示 error 空页面。
        // - refresh failure 有旧数据，所以应该保留 content，不切到 error 空页面。
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]

        // 第一次请求：让 MockService 返回旧数据。
        // 这一步是真的执行 initial 请求，目的是先让 ViewModel.products 有旧数据。
        mockService.result = .success(oldProducts)
        viewModel.loadData(mode: .initial)

        // 第二次请求前，修改 MockService 的返回值为 failure。
        // 注意：这句不会自动触发请求，只是告诉 MockService 下一次请求要失败。
        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))

        var didReceiveContentState = false
        var didReceiveErrorState = false
        var didReceiveEmptyState = false
        var didCallOnProductsChanged = false
        var didReceiveNoMoreDataFooterState = false

        // refresh 失败时 products 不应该被改写，所以不应该触发 onProductsChanged。
        viewModel.onProductsChanged = { _ in
            didCallOnProductsChanged = true
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .content:
                didReceiveContentState = true
            case .error:
                didReceiveErrorState = true
            case .empty:
                didReceiveEmptyState = true
            default:
                break
            }
        }

        viewModel.onFooterStateChanged = { state in
            switch state {
            case .noMoreData:
                didReceiveNoMoreDataFooterState = true
            default:
                break
            }
        }

        // When：执行下拉刷新，但这一次 MockService 返回失败
        viewModel.loadData(mode: .refresh)

        // Then：验证 refresh 仍然请求第 1 页
        XCTAssertEqual(mockService.requestedPage, 1, "refresh failure 也应该请求第 1 页")

        // Then：验证 refresh 失败后旧数据数量仍然保留
        XCTAssertEqual(viewModel.products.count, 2, "refresh 失败后不应该清空旧数据")

        // Then：验证旧数据内容没有被改乱
        XCTAssertEqual(viewModel.products.first?.id, 1, "refresh 失败后第一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.first?.title, "旧标题1", "refresh 失败后第一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.first?.body, "旧内容1", "refresh 失败后第一条旧数据 body 应该保留")

        XCTAssertEqual(viewModel.products.last?.id, 2, "refresh 失败后最后一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.last?.title, "旧标题2", "refresh 失败后最后一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.last?.body, "旧内容2", "refresh 失败后最后一条旧数据 body 应该保留")

        // Then：验证有旧数据时 refresh 失败，页面应该继续保持 content
        XCTAssertTrue(didReceiveContentState, "有旧数据时 refresh 失败，ViewState 应该保持 content")

        // Then：验证有旧数据时 refresh 失败，不应该切到 error 空页面
        XCTAssertFalse(didReceiveErrorState, "有旧数据时 refresh 失败，不应该进入 error")

        // Then：验证请求失败不是成功但空数据，不应该误判为 empty
        XCTAssertFalse(didReceiveEmptyState, "refresh 失败不应该进入 empty")

        // Then：验证 refresh 失败没有新数据，不应该触发 products 更新
        XCTAssertFalse(didCallOnProductsChanged, "refresh 失败没有新数据，不应该触发 onProductsChanged")

        // Then：验证旧数据数量小于 pageSize 时，footer 仍然可以收口为 noMoreData
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "旧数据数量小于 pageSize 时，FooterState 应该是 noMoreData")
    }

    func testLoadMoreFailureWithOldData_keepsOldProductsAndShowsMessage() {
        // Given：先准备第一页旧数据，而且必须是满一页。
        // 原因：ViewModel 用 list.count == pageSize 判断 hasMoreData。
        // 如果第一页只返回 2 条，hasMoreData 会变成 false，后面的 loadMore 会被 canLoadData 拦截。
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }

        // 第一次请求：让 MockService 返回满一页数据。
        // 这一步是真的执行 initial 请求，目的是让 ViewModel.products 有旧数据，并且 hasMoreData = true。
        mockService.result = .success(oldProducts)
        viewModel.loadData(mode: .initial)

        // 第二次请求前，修改 MockService 的返回值为 failure。
        // 注意：这句不会自动触发请求，只是告诉 MockService 下一次 loadMore 要失败。
        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))

        var didReceiveContentState = false
        var didReceiveErrorState = false
        var didReceiveEmptyState = false
        var didCallOnProductsChanged = false
        var didReceiveNoMoreDataFooterState = false

        // loadMore 失败时 products 不应该被改写，所以不应该触发 onProductsChanged。
        viewModel.onProductsChanged = { _ in
            didCallOnProductsChanged = true
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .content:
                didReceiveContentState = true
            case .error:
                didReceiveErrorState = true
            case .empty:
                didReceiveEmptyState = true
            default:
                break
            }
        }

        viewModel.onFooterStateChanged = { state in
            switch state {
            case .noMoreData:
                didReceiveNoMoreDataFooterState = true
            default:
                break
            }
        }

        // When：执行上拉加载更多，但这一次 MockService 返回失败
        viewModel.loadData(mode: .loadMore)

        // Then：验证 loadMore 请求的是 currentPage + 1，也就是第 2 页
        XCTAssertEqual(mockService.requestedPage, 2, "loadMore failure 应该请求第 2 页")

        // Then：验证 loadMore 失败后旧数据数量仍然保留
        XCTAssertEqual(viewModel.products.count, 10, "loadMore 失败后不应该清空旧数据")

        // Then：验证第一页旧数据没有被改乱
        XCTAssertEqual(viewModel.products.first?.id, 1, "loadMore 失败后第一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.first?.title, "第一页标题1", "loadMore 失败后第一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.first?.body, "第一页内容1", "loadMore 失败后第一条旧数据 body 应该保留")

        XCTAssertEqual(viewModel.products.last?.id, 10, "loadMore 失败后最后一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.last?.title, "第一页标题10", "loadMore 失败后最后一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.last?.body, "第一页内容10", "loadMore 失败后最后一条旧数据 body 应该保留")

        // Then：验证有旧数据时 loadMore 失败，页面应该继续保持 content
        XCTAssertTrue(didReceiveContentState, "有旧数据时 loadMore 失败，ViewState 应该保持 content")

        // Then：验证有旧数据时 loadMore 失败，不应该切到 error 空页面
        XCTAssertFalse(didReceiveErrorState, "有旧数据时 loadMore 失败，不应该进入 error")

        // Then：验证请求失败不是成功但空数据，不应该误判为 empty
        XCTAssertFalse(didReceiveEmptyState, "loadMore 失败不应该进入 empty")

        // Then：验证 loadMore 失败没有新数据，不应该触发 products 更新
        XCTAssertFalse(didCallOnProductsChanged, "loadMore 失败没有新数据，不应该触发 onProductsChanged")

        // Then：验证 loadMore 失败不应该误判为 noMoreData
        XCTAssertFalse(didReceiveNoMoreDataFooterState, "loadMore 失败不应该误判为 noMoreData")
    }
    
    // MARK: - Update Product

    // 创建测试用 Product。
    // 统一造数据，避免每个测试里反复写 Product(userId:id:title:body:)。
    private func makeProduct(
        userId: Int = 1,
        id: Int,
        title: String,
        body: String
    ) -> Product {
        return Product(userId: userId, id: id, title: title, body: body)
    }
    
    // 创建测试用 ViewModel。
    // 通过参数注入 service，确保测试可以自由切换 MockService。
    private func makeViewModel(service: ProductServiceProtocol) -> ProductListViewModel {
        return ProductListViewModel(service: service)
    }
    
}
