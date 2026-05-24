import XCTest
@testable import DeviceManagerDemo

final class ProductListViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CacheHelper.clear(key: "ProductListCacheKey")
    }

    override func tearDown() {
        CacheHelper.clear(key: "ProductListCacheKey")
        super.tearDown()
    }

    // MARK: - Initial

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

    // MARK: - Refresh

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

    // MARK: - Load More

    // loadMore 成功：追加下一页数据
    func testLoadMoreSuccess_appendsNewProducts() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 12))
        viewModel.loadData(mode: .initial)

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

    // loadMore 在没有更多数据时：应该被拒绝，不发起新请求
    func testLoadMoreWhenNoMoreData_isRejected() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 2))
        viewModel.loadData(mode: .initial)

        //清空请求 page 和 Size，
        mockService.resetRequestRecord()

        viewModel.loadData(mode: .loadMore)

        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products.first, id: 1, title: "标题1", body: "内容1")
        assertProduct(viewModel.products.last, id: 2, title: "标题2", body: "内容2")
    }

    // refresh 在没有更多数据时：仍然允许重新请求第一页
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

        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockService.requestedPage, 1)
        XCTAssertEqual(mockService.requestedPageSize, 10)
        XCTAssertEqual(viewModel.products.count, 1)
        assertProduct(viewModel.products.first, id: 3, title: "新标题3", body: "新内容3")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 1 }))
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 2 }))
    }

    // loadMore 在没有基础数据时：应该被拒绝，避免 clearCache 后误触发 page 2
    func testLoadMoreWhenProductsIsEmpty_isRejected() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        viewModel.loadData(mode: .loadMore)

        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 0)
    }

    // refreshing 中触发 loadMore：应该被拒绝，避免第一页重建时追加下一页
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
        
        //清空请求 page 和 Size，
        mockService.resetRequestRecord()

        viewModel.loadData(mode: .loadMore)

        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 10)
    }

    // loadingMore 中重复触发 loadMore：应该被拒绝，避免重复请求同一页
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

        //清空请求 page 和 Size，
        mockService.resetRequestRecord()

        viewModel.loadData(mode: .loadMore)

        XCTAssertNil(mockService.requestedPage)
        XCTAssertNil(mockService.requestedPageSize)
        XCTAssertEqual(viewModel.products.count, 10)
    }

    // MARK: - Failure

    // initial 失败且无旧数据：进入 error 状态
    func testInitialFailureWithoutOldData_showsError() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)
        let outputSpy = bindOutputSpy(to: viewModel)

        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))

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

    // loadMore 失败：保留旧列表，不误判无更多数据
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

    // MARK: - Update Product

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

        let updatedIndex = viewModel.updateProduct(notFoundProduct)

        XCTAssertNil(updatedIndex)
        XCTAssertEqual(viewModel.products.count, 2)
        assertProduct(viewModel.products[0], id: 1, title: "旧标题1", body: "旧内容1")
        assertProduct(viewModel.products[1], id: 2, title: "旧标题2", body: "旧内容2")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 999 }))
        XCTAssertFalse(didCallOnProductsChanged)
    }

    // MARK: - Cancelled

    // cancelled：静默忽略，不污染列表和状态
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

    // MARK: - Concurrent Requests

    // 旧请求晚回来：不能覆盖新请求的数据
    func testOldRequestReturnsLater_shouldNotOverrideNewData() {
        let service = ControlledMockProductService()
        let viewModel = makeViewModel(service: service)

        viewModel.loadData(mode: .refresh) // A
        viewModel.loadData(mode: .refresh) // B

        XCTAssertEqual(service.pendingRequests.count, 2)

        let newData = makePageResponse([
            makeProduct(id: 2, title: "B", body: "新请求数据")
        ])
        service.completeRequest(at: 1, with: .success(newData))

        XCTAssertEqual(viewModel.products.first?.title, "B")

        let oldData = makePageResponse([
            makeProduct(id: 1, title: "A", body: "旧请求数据")
        ])
        service.completeRequest(at: 0, with: .success(oldData))

        XCTAssertEqual(viewModel.products.first?.title, "B")
    }

    // refresh 打断 loadMore：旧 loadMore 回来后不能追加到新列表
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

        viewModel.loadData(mode: .loadMore) // 旧 page 2，先发出但不完成
        viewModel.loadData(mode: .refresh)  // 新 page 1，后发出

        XCTAssertEqual(service.pendingRequests.count, 3)

        let refreshData = makePageResponse(
            [makeProduct(id: 100, title: "刷新后的第一页", body: "刷新后的内容")],
            page: 1,
            pageSize: 10,
            total: 1
        )
        service.completeRequest(at: 2, with: .success(refreshData))

        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.products.first?.title, "刷新后的第一页")

        let oldLoadMoreData = makePageResponse(
            [makeProduct(id: 11, title: "旧第二页标题11", body: "旧第二页内容11")],
            page: 2,
            pageSize: 10,
            total: 20
        )
        service.completeRequest(at: 1, with: .success(oldLoadMoreData))

        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.products.first?.title, "刷新后的第一页")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 11 }))
    }
    
    // MARK: - Helpers

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
    private func makeViewModel(service: ProductServiceProtocol) -> ProductListViewModel {
        return ProductListViewModel(service: service)
    }
}
