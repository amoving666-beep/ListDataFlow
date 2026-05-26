import XCTest
@testable import DeviceManagerDemo

final class ProductListViewModelTests: XCTestCase {

    // 测试分组说明：
    // 1. Initial / Refresh / Load More：验证三种加载入口的成功路径和入口拦截
    // 2. Failure / Cancelled：验证失败和取消不会误改列表状态
    // 3. Concurrent Requests：验证旧请求乱序返回时不会污染新数据
    // 4. Update Product：验证详情页保存后的本地列表更新
    // 5. Helpers：统一创建测试数据、ViewModel 和回调监听，减少重复代码

    override func setUp() {
        super.setUp()
        try? UserDefaultsProductCacheStore().clear()
    }

    override func tearDown() {
        try? UserDefaultsProductCacheStore().clear()
        super.tearDown()
    }

    // MARK: - 1. Initial
    // 首次加载：重点验证 page=1、products 写入、页面进入 content/error

    // initial 成功：更新列表，并进入 content 状态
    func testInitialSuccess_updatesProductsAndShowsContent() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)
        let outputSpy = bindOutputSpy(to: viewModel)

        let mockProducts = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]
        mockService.result = .success(makePageResponse(mockProducts))

        // initial 应该请求第一页，并把返回数据写入列表
        viewModel.loadData(mode: .initial)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(mockService.requestedPageSize, 10)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products.first, id: 1, title: "标题1", body: "内容1")
        assertProduct(viewModel.products.last, id: 2, title: "标题2", body: "内容2")
        XCTAssertEqual(outputSpy.productsChangedCallCount, 1)
        XCTAssertEqual(outputSpy.lastProducts?.count, 2)
        XCTAssertTrue(outputSpy.didReceiveContentState)
        XCTAssertTrue(outputSpy.didReceiveNoMoreDataFooterState)
    }

    // MARK: - 2. Refresh
    // 下拉刷新：重点验证第一页新数据会替换旧列表，不受 noMoreData 限制

    // refresh 成功：用第一页新数据替换旧数据
    func testRefreshSuccess_replacesOldProducts() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts))
        viewModel.loadData(mode: .initial)

        // refresh 应该用第一页新数据替换旧列表，而不是 append
        let newProducts = [
            makeProduct(id: 3, title: "新标题3", body: "新内容3"),
            makeProduct(id: 4, title: "新标题4", body: "新内容4")
        ]
        mockService.result = .success(makePageResponse(newProducts))
        let outputSpy = bindOutputSpy(to: viewModel)

        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products.first, id: 3, title: "新标题3", body: "新内容3")
        assertProduct(viewModel.products.last, id: 4, title: "新标题4", body: "新内容4")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 1 }))
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 2 }))
        XCTAssertEqual(outputSpy.productsChangedCallCount, 1)
        XCTAssertEqual(outputSpy.lastProducts?.count, 2)
        XCTAssertTrue(outputSpy.didReceiveContentState)
        XCTAssertTrue(outputSpy.didReceiveNoMoreDataFooterState)
    }

    // MARK: - 3. Load More
    // 上拉加载：重点验证追加下一页，以及各种不该发请求的拦截场景

    // loadMore 成功：追加下一页数据
    func testLoadMoreSuccess_appendsNewProducts() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 12))
        viewModel.loadData(mode: .initial)

        // loadMore 应该请求 currentPage + 1，并追加到第一页后面
        let newProducts = [
            makeProduct(id: 11, title: "第二页标题11", body: "第二页内容11"),
            makeProduct(id: 12, title: "第二页标题12", body: "第二页内容12")
        ]
        mockService.result = .success(makePageResponse(newProducts, page: 2, pageSize: 10, total: 12))
        let outputSpy = bindOutputSpy(to: viewModel)

        viewModel.loadData(mode: .loadMore)

        XCTAssertEqual(mockService.requestedPage, 2)
        XCTAssertEqual(viewModel.products.count, 12)
        assertProduct(viewModel.products.first, id: 1, title: "第一页标题1", body: "第一页内容1")
        assertProduct(viewModel.products.last, id: 12, title: "第二页标题12", body: "第二页内容12")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 1 }))
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 10 }))
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 11 }))
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 12 }))
        XCTAssertEqual(outputSpy.productsChangedCallCount, 1)
        XCTAssertEqual(outputSpy.lastProducts?.count, 12)
        XCTAssertTrue(outputSpy.didReceiveContentState)
        XCTAssertTrue(outputSpy.didReceiveNoMoreDataFooterState)
    }

    // 无更多数据时，loadMore 不应该继续请求下一页
    func testLoadMoreWhenNoMoreData_isRejected() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 2))
        viewModel.loadData(mode: .initial)

        // 清空上一次请求记录，方便确认 loadMore 没有再次发起请求
        mockService.resetRequestRecord()

        viewModel.loadData(mode: .loadMore)

        // 没有更多数据时，不应该触发新的 service 请求
        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products.first, id: 1, title: "标题1", body: "内容1")
        assertProduct(viewModel.products.last, id: 2, title: "标题2", body: "内容2")
    }

    // noMoreData 只限制 loadMore，不限制 refresh
    func testRefreshAllowedWhenNoMoreData() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 2))
        viewModel.loadData(mode: .initial)

        let newProducts = [
            makeProduct(id: 3, title: "新标题3", body: "新内容3")
        ]
        mockService.result = .success(makePageResponse(newProducts, page: 1, pageSize: 10, total: 1))

        // 即使已经没有更多数据，refresh 仍然允许重新请求第一页
        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(mockService.requestedPageSize, 10)
        XCTAssertEqual(viewModel.products.count, 1)
        assertProduct(viewModel.products.first, id: 3, title: "新标题3", body: "新内容3")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 1 }))
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 2 }))
    }

    // 没有第一页基础数据时，loadMore 不应该直接请求 page 2
    func testLoadMoreWhenProductsIsEmpty_isRejected() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        viewModel.loadData(mode: .loadMore)

        // 没有第一页数据时，loadMore 不应该越过 initial 直接请求下一页
        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 0)
    }

    // refresh 未完成时，loadMore 应该被拦截
    func testLoadMoreWhileRefreshing_isRejected() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .initial)

        mockService.shouldDelayCompletion = true
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .refresh)
        
        // 清空 refresh 的请求记录，下面只验证 loadMore 是否被拦截
        mockService.resetRequestRecord()

        viewModel.loadData(mode: .loadMore)

        // refresh 进行中时，loadMore 应该被入口优先级拦截
        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 10)
    }

    // loadingMore 未完成时，重复 loadMore 应该被拦截
    func testRepeatedLoadMore_isRejected() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .initial)

        mockService.shouldDelayCompletion = true
        mockService.result = .success(makePageResponse([
            makeProduct(id: 11, title: "第二页标题11", body: "第二页内容11")
        ], page: 2, pageSize: 10, total: 20))
        viewModel.loadData(mode: .loadMore)

        // 清空第一次 loadMore 的请求记录，下面只验证重复 loadMore 是否被拦截
        mockService.resetRequestRecord()

        viewModel.loadData(mode: .loadMore)

        // 上一次 loadMore 未完成前，重复 loadMore 不应该再次发请求
        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 10)
    }

    // MARK: - 4. Failure
    // 失败分支：重点验证不同 LoadMode 失败后，旧数据和页面状态是否安全

    // initial 失败且无旧数据：进入 error 状态
    func testInitialFailureWithoutOldData_showsError() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)
        let outputSpy = bindOutputSpy(to: viewModel)

        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))

        // 首次加载失败且没有旧数据兜底时，页面应该进入 error
        viewModel.loadData(mode: .initial)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(viewModel.products.count, 0)
        XCTAssertTrue(outputSpy.didReceiveErrorState)
        XCTAssertFalse(outputSpy.didReceiveContentState)
        XCTAssertFalse(outputSpy.didReceiveEmptyState)
        XCTAssertEqual(outputSpy.productsChangedCallCount, 0)
    }

    // refresh 失败且有旧数据：保留旧列表
    func testRefreshFailureWithOldData_keepsOldProductsAndShowsMessage() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts))
        viewModel.loadData(mode: .initial)

        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))
        let outputSpy = bindOutputSpy(to: viewModel)

        // refresh 失败但已有旧数据时，保留列表，不切到整页 error
        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products.first, id: 1, title: "旧标题1", body: "旧内容1")
        assertProduct(viewModel.products.last, id: 2, title: "旧标题2", body: "旧内容2")
        XCTAssertTrue(outputSpy.didReceiveContentState)
        XCTAssertFalse(outputSpy.didReceiveErrorState)
        XCTAssertFalse(outputSpy.didReceiveEmptyState)
        XCTAssertEqual(outputSpy.productsChangedCallCount, 0)
        XCTAssertTrue(outputSpy.didReceiveNoMoreDataFooterState)
    }

    // loadMore 失败时，保留第一页数据，也不能误判 noMoreData
    func testLoadMoreFailureWithOldData_keepsOldProductsAndShowsMessage() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .initial)

        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))
        let outputSpy = bindOutputSpy(to: viewModel)

        // loadMore 失败只影响底部加载，不应该清空第一页数据
        viewModel.loadData(mode: .loadMore)

        XCTAssertEqual(mockService.requestedPage, 2)
        XCTAssertEqual(viewModel.products.count, 10)
        assertProduct(viewModel.products.first, id: 1, title: "第一页标题1", body: "第一页内容1")
        assertProduct(viewModel.products.last, id: 10, title: "第一页标题10", body: "第一页内容10")
        XCTAssertTrue(outputSpy.didReceiveContentState)
        XCTAssertFalse(outputSpy.didReceiveErrorState)
        XCTAssertFalse(outputSpy.didReceiveEmptyState)
        XCTAssertEqual(outputSpy.productsChangedCallCount, 0)
        XCTAssertFalse(outputSpy.didReceiveNoMoreDataFooterState)
    }

    // MARK: - 5. Update Product
    // 详情保存回传：重点验证只更新匹配 id 的那一条数据

    // updateProduct 成功：只更新匹配 id 的数据
    func testUpdateProductSuccess_updatesMatchedProduct() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts))
        viewModel.loadData(mode: .initial)

        let newProduct = makeProduct(id: 2, title: "新标题2", body: "新内容2")
        var didCallOnProductsChanged = false
        var callbackProducts: [Product] = []
        viewModel.onProductsChanged = { products in
            didCallOnProductsChanged = true
            callbackProducts = products
        }

        // 详情页保存回传后，只更新 id 匹配的那一条
        let updatedIndex = viewModel.updateProduct(newProduct)

        XCTAssertEqual(updatedIndex, 1)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products[1], id: 2, title: "新标题2", body: "新内容2")
        assertProduct(viewModel.products[0], id: 1, title: "旧标题1", body: "旧内容1")
        XCTAssertTrue(didCallOnProductsChanged)
        XCTAssertEqual(callbackProducts.count, 2)
        assertProduct(callbackProducts[1], id: 2, title: "新标题2", body: "新内容2")
    }

    // updateProduct 找不到 id：返回 nil，不改列表
    func testUpdateProductNotFound_returnsNil() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts))
        viewModel.loadData(mode: .initial)

        let notFoundProduct = makeProduct(id: 999, title: "不存在标题", body: "不存在内容")
        var didCallOnProductsChanged = false
        viewModel.onProductsChanged = { _ in
            didCallOnProductsChanged = true
        }

        // 找不到对应 id 时，不应该改动列表，也不应该触发刷新回调
        let updatedIndex = viewModel.updateProduct(notFoundProduct)

        XCTAssertNil(updatedIndex)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products[0], id: 1, title: "旧标题1", body: "旧内容1")
        assertProduct(viewModel.products[1], id: 2, title: "旧标题2", body: "旧内容2")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 999 }))
        XCTAssertFalse(didCallOnProductsChanged)
    }

    // MARK: - 6. Cache Store
    // 缓存协议注入：验证 ViewModel 依赖 ProductCacheStoreProtocol，而不是直接依赖 CacheHelper

    // loadCache：页面启动时先从 cacheStore 读取缓存。
    // 这个测试只验证缓存读取链路，不触发真实网络请求。

    func testInitial_loadsCacheBeforeNetwork() {
        let mockService = MockProductService()
        let mockCacheStore = MockProductCacheStore()

        mockCacheStore.pageResponseToLoad = makePageResponse([
            makeProduct(id: 1, title: "缓存标题1", body: "缓存内容1")
        ])

        let viewModel = makeViewModel(service: mockService, cacheStore: mockCacheStore)
        let outputSpy = bindOutputSpy(to: viewModel)

        viewModel.loadCache()

        XCTAssertEqual(mockCacheStore.loadPageResponseCallCount, 1)
        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.products.first?.title, "缓存标题1")
        XCTAssertEqual(outputSpy.productsChangedCallCount, 1)
        XCTAssertTrue(outputSpy.didReceiveContentState)
    }

    // refresh 成功：应把第一页新数据保存到 cacheStore，旧缓存不应该继续保留。
    func testRefreshSuccess_replacesCache() {
        let mockService = MockProductService()
        let mockCacheStore = MockProductCacheStore()
        let viewModel = makeViewModel(service: mockService, cacheStore: mockCacheStore)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .initial)

        let newProducts = [
            makeProduct(id: 3, title: "新标题3", body: "新内容3"),
            makeProduct(id: 4, title: "新标题4", body: "新内容4")
        ]
        mockService.result = .success(makePageResponse(newProducts, page: 1, pageSize: 10, total: 20))

        // refresh 成功后，ViewModel 内部 products 已经被第一页新数据替换，
        // saveCache 保存的也必须是替换后的完整列表。
        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockCacheStore.savePageResponseCallCount, 2)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.list.map { $0.id }, [3, 4])
        XCTAssertEqual(mockCacheStore.savedPageResponse?.page, 1)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.pageSize, 10)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.total, 20)
    }

    // loadMore 成功：缓存必须保存“第一页 + 第二页”的合并结果。
    // 这是本阶段最关键的测试，防止误把 page 2 response 单独写进缓存。
    func testLoadMoreSuccess_savesMergedProductsToCache() {
        let mockService = MockProductService()
        let mockCacheStore = MockProductCacheStore()
        let viewModel = makeViewModel(service: mockService, cacheStore: mockCacheStore)

        let page1Products = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(page1Products, page: 1, pageSize: 10, total: 12))
        viewModel.loadData(mode: .initial)

        let page2Products = [
            makeProduct(id: 11, title: "第二页标题11", body: "第二页内容11"),
            makeProduct(id: 12, title: "第二页标题12", body: "第二页内容12")
        ]
        mockService.result = .success(makePageResponse(page2Products, page: 2, pageSize: 10, total: 12))

        // loadMore 返回的 response.list 只有第二页。
        // ViewModel 必须先 append 到 products，再把合并后的完整 products 保存到 cacheStore。
        viewModel.loadData(mode: .loadMore)

        XCTAssertEqual(mockCacheStore.savePageResponseCallCount, 2)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.list.count, 12)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.list.first?.id, 1)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.list.last?.id, 12)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.list.map { $0.id }, Array(1...12))
        XCTAssertEqual(mockCacheStore.savedPageResponse?.page, 2)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.pageSize, 10)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.total, 12)
    }

    // cacheStore 保存失败：不能影响网络成功后的列表展示。
    // 缓存只是兜底能力，网络主流程成功时不能因为本地写入失败而进入 error。
    func testCacheSaveFailure_doesNotBreakNetworkSuccess() {
        let mockService = MockProductService()
        let mockCacheStore = MockProductCacheStore()
        mockCacheStore.shouldThrowOnSave = true

        let viewModel = makeViewModel(service: mockService, cacheStore: mockCacheStore)
        let outputSpy = bindOutputSpy(to: viewModel)

        let products = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]
        mockService.result = .success(makePageResponse(products, page: 1, pageSize: 10, total: 2))

        viewModel.loadData(mode: .initial)

        XCTAssertEqual(mockCacheStore.savePageResponseCallCount, 1)
        XCTAssertEqual(viewModel.products.count, 2)
        XCTAssertEqual(outputSpy.productsChangedCallCount, 1)
        XCTAssertTrue(outputSpy.didReceiveContentState)
        XCTAssertFalse(outputSpy.didReceiveErrorState)
    }
    
    // 网络成功后：应通过 cacheStore 保存分页缓存
    func testInitialSuccess_savesPageResponseToCacheStore() {
        let mockService = MockProductService()
        let mockCacheStore = MockProductCacheStore()
        let viewModel = makeViewModel(service: mockService, cacheStore: mockCacheStore)

        let products = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]
        mockService.result = .success(makePageResponse(products, page: 1, pageSize: 10, total: 20))

        viewModel.loadData(mode: .initial)

        XCTAssertEqual(mockCacheStore.savePageResponseCallCount, 1)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.list.count, 2)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.page, 1)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.pageSize, 10)
        XCTAssertEqual(mockCacheStore.savedPageResponse?.total, 20)
    }

    // clearCache：应通过 cacheStore 清理缓存
    func testClearCache_callsCacheStoreClear() {
        let mockService = MockProductService()
        let mockCacheStore = MockProductCacheStore()
        let viewModel = makeViewModel(service: mockService, cacheStore: mockCacheStore)

        viewModel.clearCache()

        XCTAssertEqual(mockCacheStore.clearCallCount, 1)
        XCTAssertEqual(viewModel.products.count, 0)
    }

    // MARK: - 7. Cancelled
    // 取消请求：重点验证 cancelled 被静默忽略，不进入 error，也不清空旧数据

    // cancelled 属于主动取消，不应该当成普通失败展示
    func testCancelledRequest_doesNotPolluteState() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "旧标题1", body: "旧内容1"),
            makeProduct(id: 2, title: "旧标题2", body: "旧内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .initial)

        mockService.result = .failure(NetworkError.cancelled)
        let outputSpy = bindOutputSpy(to: viewModel)

        // cancelled 是主动取消，应该静默结束，不走普通失败 UI
        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products.first, id: 1, title: "旧标题1", body: "旧内容1")
        assertProduct(viewModel.products.last, id: 2, title: "旧标题2", body: "旧内容2")
        XCTAssertFalse(outputSpy.didReceiveErrorState)
        XCTAssertFalse(outputSpy.didReceiveEmptyState)
        XCTAssertEqual(outputSpy.productsChangedCallCount, 0)
        XCTAssertFalse(outputSpy.didReceiveNoMoreDataFooterState)
    }

    // MARK: - 8. Concurrent Requests
    // 并发安全：重点验证 ControlledMock 手动制造乱序返回时，旧请求不能写入新状态

    // 两次 refresh 乱序返回：旧请求不能覆盖新请求
    func testOldRequestReturnsLater_shouldNotOverrideNewData() {
        let service = ControlledMockProductService()
        let viewModel = makeViewModel(service: service)

        viewModel.loadData(mode: .refresh) // A
        viewModel.loadData(mode: .refresh) // B

        // pendingRequests[0] = A，pendingRequests[1] = B
        XCTAssertEqual(service.pendingRequests.count, 2)

        let newData = makePageResponse([
            makeProduct(id: 2, title: "B", body: "新请求数据")
        ])

        // 先让后发出的 B 返回，确认最新请求可以正常写入
        service.completeRequest(at: 1, with: .success(newData))
        XCTAssertEqual(viewModel.products.first?.title, "B")

        let oldData = makePageResponse([
            makeProduct(id: 1, title: "A", body: "旧请求数据")
        ])

        // 再让旧请求 A 返回，验证 requestID 会丢弃旧回调
        service.completeRequest(at: 0, with: .success(oldData))

        XCTAssertEqual(viewModel.products.first?.title, "B")
    }

    // refresh 打断 loadMore：旧 page 2 不能追加到新的 page 1
    func testRefreshCancelsLoadMore_oldLoadMoreShouldNotAppend() {
        let service = ControlledMockProductService()
        let viewModel = makeViewModel(service: service)

        viewModel.loadData(mode: .initial)

        let page1Data = makePageResponse(
            (1...10).map {
                makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
            },
            page: 1,
            pageSize: 10,
            total: 20
        )
        service.completeRequest(at: 0, with: .success(page1Data))

        XCTAssertEqual(viewModel.products.count, 10)
        XCTAssertEqual(viewModel.products.first?.title, "第一页标题1")

        viewModel.loadData(mode: .loadMore) // pendingRequests[1]，旧 page 2
        viewModel.loadData(mode: .refresh)  // pendingRequests[2]，新 page 1

        XCTAssertEqual(service.pendingRequests.count, 3)

        let refreshData = makePageResponse(
            [makeProduct(id: 100, title: "刷新后的第一页", body: "刷新后的内容")],
            page: 1,
            pageSize: 10,
            total: 1
        )

        // 先完成 refresh，新列表应该替换旧列表
        service.completeRequest(at: 2, with: .success(refreshData))

        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.products.first?.title, "刷新后的第一页")

        let oldLoadMoreData = makePageResponse(
            [makeProduct(id: 11, title: "旧第二页标题11", body: "旧第二页内容11")],
            page: 2,
            pageSize: 10,
            total: 20
        )

        // 再完成旧 loadMore，验证它不会被追加到 refresh 后的新列表
        service.completeRequest(at: 1, with: .success(oldLoadMoreData))

        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.products.first?.title, "刷新后的第一页")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 11 }))
    }
    
    // MARK: - 9. Helpers
    // 测试辅助方法：统一处理测试数据、断言和 ViewModel 输出监听

    // 记录 ViewModel 输出，避免每个测试重复写回调监听
    private final class ViewModelOutputSpy {
        var productsChangedCallCount = 0
        var lastProducts: [Product]?
        var didReceiveLoadingState = false
        var didReceiveContentState = false
        var didReceiveEmptyState = false
        var didReceiveErrorState = false
        var didReceiveIdleFooterState = false
        var didReceiveLoadingFooterState = false
        var didReceiveNoMoreDataFooterState = false

        func recordProductsChanged(_ products: [Product]) {
            productsChangedCallCount += 1
            lastProducts = products
        }
    }

    // 测试用缓存实现：只记录调用，不碰真实 UserDefaults
    private final class MockProductCacheStore: ProductCacheStoreProtocol {
        var savePageResponseCallCount = 0
        var loadPageResponseCallCount = 0
        var clearCallCount = 0
        var savedPageResponse: PageResponse<Product>?
        var pageResponseToLoad: PageResponse<Product>?
        var shouldThrowOnSave = false
        var shouldThrowOnLoad = false
        var shouldThrowOnClear = false

        func savePageResponse(_ response: PageResponse<Product>) throws {
            savePageResponseCallCount += 1

            if shouldThrowOnSave {
                throw NSError(domain: "MockProductCacheStore", code: 1)
            }

            savedPageResponse = response
        }

        func loadPageResponse() throws -> PageResponse<Product>? {
            loadPageResponseCallCount += 1

            if shouldThrowOnLoad {
                throw NSError(domain: "MockProductCacheStore", code: 2)
            }

            return pageResponseToLoad
        }

        func clear() throws {
            clearCallCount += 1

            if shouldThrowOnClear {
                throw NSError(domain: "MockProductCacheStore", code: 3)
            }
        }
    }

    // 绑定 ViewModel 回调，把输出统一记到 spy 里
    private func bindOutputSpy(to viewModel: ProductListViewModel) -> ViewModelOutputSpy {
        let outputSpy = ViewModelOutputSpy()

        viewModel.onProductsChanged = { products in
            outputSpy.recordProductsChanged(products)
        }

        viewModel.onViewStateChanged = { state in
            switch state {
            case .loading:
                outputSpy.didReceiveLoadingState = true
            case .content:
                outputSpy.didReceiveContentState = true
            case .empty(_):
                outputSpy.didReceiveEmptyState = true
            case .error(_):
                outputSpy.didReceiveErrorState = true
            }
        }

        viewModel.onFooterStateChanged = { state in
            switch state {
            case .hidden:
                outputSpy.didReceiveIdleFooterState = true
            case .loadingMore:
                outputSpy.didReceiveLoadingFooterState = true
            case .noMoreData:
                outputSpy.didReceiveNoMoreDataFooterState = true
            }
        }

        return outputSpy
    }

    // 检查 Product 的核心字段
    private func assertProduct(
        _ product: Product?,
        id: Int,
        title: String,
        body: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(product?.id, id, file: file, line: line)
        XCTAssertEqual(product?.title, title, file: file, line: line)
        XCTAssertEqual(product?.body, body, file: file, line: line)
    }

    // 快速创建测试用 Product
    private func makeProduct(
        userId: Int = 1,
        id: Int,
        title: String,
        body: String
    ) -> Product {
        return Product(userId: userId, id: id, title: title, body: body)
    }

    // 快速创建分页响应
    private func makePageResponse(
        _ products: [Product],
        page: Int = 1,
        pageSize: Int = 10,
        total: Int? = nil
    ) -> PageResponse<Product> {
        return PageResponse(
            list: products,
            page: page,
            pageSize: pageSize,
            total: total ?? products.count
        )
    }

    // 创建被测试的 ViewModel
    private func makeViewModel(
        service: ProductServiceProtocol,
        cacheStore: ProductCacheStoreProtocol = UserDefaultsProductCacheStore()
    ) -> ProductListViewModel {
        return ProductListViewModel(service: service, cacheStore: cacheStore)
    }
}
