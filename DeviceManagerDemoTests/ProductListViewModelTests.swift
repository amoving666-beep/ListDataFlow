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
    
    func testInitialSuccess_updatesProductsAndShowsContent() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)
        
        let mockProducts = [
            makeProduct(id: 1, title: "标题1", body: "内容1"),
            makeProduct(id: 2, title: "标题2", body: "内容2")
        ]
        mockService.result = .success(makePageResponse(mockProducts))
        var didCallOnProductsChanged = false
        var didReceiveContentState = false
        var didReceiveNoMoreDataFooterState = false
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
        viewModel.loadData(mode: .initial)
        XCTAssertEqual(mockService.requestedPage, 1, "initial 模式应该请求第 1 页")
        XCTAssertEqual(mockService.requestedPageSize, 10, "ViewModel 应该把 pageSize = 10 传给 Service")
        XCTAssertEqual(viewModel.products.count, 2, "请求成功后，ViewModel.products 数量应该是 2")
        XCTAssertEqual(viewModel.products.first?.id, 1, "第一条 Product 的 id 应该正确")
        XCTAssertEqual(viewModel.products.first?.title, "标题1", "第一条 Product 的 title 应该正确")
        XCTAssertEqual(viewModel.products.first?.body, "内容1", "第一条 Product 的 body 应该正确")
        XCTAssertEqual(viewModel.products.last?.id, 2, "最后一条 Product 的 id 应该正确")
        XCTAssertEqual(viewModel.products.last?.title, "标题2", "最后一条 Product 的 title 应该正确")
        XCTAssertEqual(viewModel.products.last?.body, "内容2", "最后一条 Product 的 body 应该正确")
        XCTAssertTrue(didCallOnProductsChanged, "请求成功后应该触发 onProductsChanged")
        XCTAssertTrue(didReceiveContentState, "initial 成功且有数据时，ViewState 应该进入 content")
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "返回数据数量小于 pageSize 时，FooterState 应该进入 noMoreData")

    }

    // MARK: - Refresh
    
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
        viewModel.loadData(mode: .refresh)
        XCTAssertEqual(mockService.requestedPage, 1, "refresh 模式应该重新请求第 1 页")
        XCTAssertEqual(viewModel.products.count, 2, "refresh 成功后应该替换旧数据，而不是 append")
        XCTAssertEqual(viewModel.products.first?.id, 3, "refresh 后第一条应该是新数据 id = 3")
        XCTAssertEqual(viewModel.products.first?.title, "新标题3", "refresh 后第一条 title 应该是新标题")
        XCTAssertEqual(viewModel.products.first?.body, "新内容3", "refresh 后第一条 body 应该是新内容")
        XCTAssertEqual(viewModel.products.last?.id, 4, "refresh 后最后一条应该是新数据 id = 4")
        XCTAssertEqual(viewModel.products.last?.title, "新标题4", "refresh 后最后一条 title 应该是新标题")
        XCTAssertEqual(viewModel.products.last?.body, "新内容4", "refresh 后最后一条 body 应该是新内容")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 1 }), "refresh 后不应该再包含旧数据 id = 1")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 2 }), "refresh 后不应该再包含旧数据 id = 2")
        XCTAssertTrue(didCallOnProductsChanged, "refresh 成功后应该触发 onProductsChanged")
        XCTAssertTrue(didReceiveContentState, "refresh 成功且有数据时，ViewState 应该是 content")
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "refresh 返回数据数量小于 pageSize 时，FooterState 应该进入 noMoreData")
    }

    // MARK: - Load More
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
        viewModel.loadData(mode: .loadMore)
        XCTAssertEqual(mockService.requestedPage, 2, "loadMore 模式应该请求第 2 页")
        XCTAssertEqual(viewModel.products.count, 12, "loadMore 成功后应该 append 第二页数据，而不是 replace")
        XCTAssertEqual(viewModel.products.first?.id, 1, "loadMore 后第一条仍然应该是第一页 id = 1")
        XCTAssertEqual(viewModel.products.first?.title, "第一页标题1", "loadMore 后第一条 title 应该保持第一页数据")
        XCTAssertEqual(viewModel.products.first?.body, "第一页内容1", "loadMore 后第一条 body 应该保持第一页数据")
        XCTAssertEqual(viewModel.products.last?.id, 12, "loadMore 后最后一条应该是第二页 id = 12")
        XCTAssertEqual(viewModel.products.last?.title, "第二页标题12", "loadMore 后最后一条 title 应该是第二页数据")
        XCTAssertEqual(viewModel.products.last?.body, "第二页内容12", "loadMore 后最后一条 body 应该是第二页数据")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 1 }), "loadMore 后应该保留第一页旧数据 id = 1")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 10 }), "loadMore 后应该保留第一页旧数据 id = 10")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 11 }), "loadMore 后应该包含第二页新数据 id = 11")
        XCTAssertTrue(viewModel.products.contains(where: { $0.id == 12 }), "loadMore 后应该包含第二页新数据 id = 12")
        XCTAssertTrue(didCallOnProductsChanged, "loadMore 成功后应该触发 onProductsChanged")
        XCTAssertTrue(didReceiveContentState, "loadMore 成功且有数据时，ViewState 应该是 content")
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "loadMore 返回数据数量小于 pageSize 时，FooterState 应该进入 noMoreData")

    }

    // MARK: - Failure
    func testInitialFailureWithoutOldData_showsError() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)
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
        viewModel.loadData(mode: .initial)
        XCTAssertEqual(mockService.requestedPage, 1, "initial failure 也应该请求第 1 页")
        XCTAssertEqual(viewModel.products.count, 0, "无旧数据时 initial 失败，products 应该仍然为空")
        XCTAssertTrue(didReceiveErrorState, "无旧数据时 initial 请求失败，ViewState 应该进入 error")
        XCTAssertFalse(didReceiveContentState, "无旧数据时 initial 请求失败，不应该进入 content")
        XCTAssertFalse(didReceiveEmptyState, "请求失败不是请求成功但空数据，不应该进入 empty")
        XCTAssertFalse(didCallOnProductsChanged, "initial 失败没有新数据，不应该触发 onProductsChanged")
    }

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

        var didReceiveContentState = false
        var didReceiveErrorState = false
        var didReceiveEmptyState = false
        var didCallOnProductsChanged = false
        var didReceiveNoMoreDataFooterState = false
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
        viewModel.loadData(mode: .refresh)
        XCTAssertEqual(mockService.requestedPage, 1, "refresh failure 也应该请求第 1 页")
        XCTAssertEqual(viewModel.products.count, 2, "refresh 失败后不应该清空旧数据")
        XCTAssertEqual(viewModel.products.first?.id, 1, "refresh 失败后第一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.first?.title, "旧标题1", "refresh 失败后第一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.first?.body, "旧内容1", "refresh 失败后第一条旧数据 body 应该保留")

        XCTAssertEqual(viewModel.products.last?.id, 2, "refresh 失败后最后一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.last?.title, "旧标题2", "refresh 失败后最后一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.last?.body, "旧内容2", "refresh 失败后最后一条旧数据 body 应该保留")
        XCTAssertTrue(didReceiveContentState, "有旧数据时 refresh 失败，ViewState 应该保持 content")
        XCTAssertFalse(didReceiveErrorState, "有旧数据时 refresh 失败，不应该进入 error")
        XCTAssertFalse(didReceiveEmptyState, "refresh 失败不应该进入 empty")
        XCTAssertFalse(didCallOnProductsChanged, "refresh 失败没有新数据，不应该触发 onProductsChanged")
        XCTAssertTrue(didReceiveNoMoreDataFooterState, "旧数据数量小于 pageSize 时，FooterState 应该是 noMoreData")
    }

    func testLoadMoreFailureWithOldData_keepsOldProductsAndShowsMessage() {
        let mockService = MockProductService()
        let viewModel = makeViewModel(service: mockService)

        let oldProducts = (1...10).map {
            makeProduct(id: $0, title: "第一页标题\($0)", body: "第一页内容\($0)")
        }
        mockService.result = .success(makePageResponse(oldProducts, page: 1, pageSize: 10, total: 20))
        viewModel.loadData(mode: .initial)
        mockService.result = .failure(NetworkError.requestFailed(URLError(.notConnectedToInternet)))

        var didReceiveContentState = false
        var didReceiveErrorState = false
        var didReceiveEmptyState = false
        var didCallOnProductsChanged = false
        var didReceiveNoMoreDataFooterState = false
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
        viewModel.loadData(mode: .loadMore)
        XCTAssertEqual(mockService.requestedPage, 2, "loadMore failure 应该请求第 2 页")
        XCTAssertEqual(viewModel.products.count, 10, "loadMore 失败后不应该清空旧数据")
        XCTAssertEqual(viewModel.products.first?.id, 1, "loadMore 失败后第一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.first?.title, "第一页标题1", "loadMore 失败后第一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.first?.body, "第一页内容1", "loadMore 失败后第一条旧数据 body 应该保留")

        XCTAssertEqual(viewModel.products.last?.id, 10, "loadMore 失败后最后一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.last?.title, "第一页标题10", "loadMore 失败后最后一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.last?.body, "第一页内容10", "loadMore 失败后最后一条旧数据 body 应该保留")
        XCTAssertTrue(didReceiveContentState, "有旧数据时 loadMore 失败，ViewState 应该保持 content")
        XCTAssertFalse(didReceiveErrorState, "有旧数据时 loadMore 失败，不应该进入 error")
        XCTAssertFalse(didReceiveEmptyState, "loadMore 失败不应该进入 empty")
        XCTAssertFalse(didCallOnProductsChanged, "loadMore 失败没有新数据，不应该触发 onProductsChanged")
        XCTAssertFalse(didReceiveNoMoreDataFooterState, "loadMore 失败不应该误判为 noMoreData")
    }
    
    // MARK: - Update Product

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
        XCTAssertEqual(updatedIndex, 1, "id = 2 的 Product 在数组里的 index 应该是 1")
        XCTAssertEqual(viewModel.products.count, 2, "updateProduct 成功后 products 数量不应该变化")
        XCTAssertEqual(viewModel.products[1].id, 2, "被更新的 Product id 应该仍然是 2")
        XCTAssertEqual(viewModel.products[1].title, "新标题2", "目标 Product 的 title 应该被更新")
        XCTAssertEqual(viewModel.products[1].body, "新内容2", "目标 Product 的 body 应该被更新")
        XCTAssertEqual(viewModel.products[0].id, 1, "非目标 Product 的 id 不应该变化")
        XCTAssertEqual(viewModel.products[0].title, "旧标题1", "非目标 Product 的 title 不应该变化")
        XCTAssertEqual(viewModel.products[0].body, "旧内容1", "非目标 Product 的 body 不应该变化")
        XCTAssertTrue(didCallOnProductsChanged, "updateProduct 成功后应该触发 onProductsChanged")
        XCTAssertEqual(callbackProducts.count, 2, "onProductsChanged 回调里的 products 数量应该仍然是 2")
        XCTAssertEqual(callbackProducts[1].title, "新标题2", "onProductsChanged 回调里的目标 Product title 应该是新值")
        XCTAssertEqual(callbackProducts[1].body, "新内容2", "onProductsChanged 回调里的目标 Product body 应该是新值")
    }
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
        XCTAssertNil(updatedIndex, "找不到目标 id 时，updateProduct 应该返回 nil")
        XCTAssertEqual(viewModel.products.count, 2, "updateProduct 找不到目标时，不应该改变 products 数量")
        XCTAssertEqual(viewModel.products[0].id, 1, "找不到目标时，第一条旧数据 id 不应该变化")
        XCTAssertEqual(viewModel.products[0].title, "旧标题1", "找不到目标时，第一条旧数据 title 不应该变化")
        XCTAssertEqual(viewModel.products[0].body, "旧内容1", "找不到目标时，第一条旧数据 body 不应该变化")
        XCTAssertEqual(viewModel.products[1].id, 2, "找不到目标时，第二条旧数据 id 不应该变化")
        XCTAssertEqual(viewModel.products[1].title, "旧标题2", "找不到目标时，第二条旧数据 title 不应该变化")
        XCTAssertEqual(viewModel.products[1].body, "旧内容2", "找不到目标时，第二条旧数据 body 不应该变化")
        XCTAssertFalse(viewModel.products.contains(where: { $0.id == 999 }), "找不到目标时，不应该把 id = 999 插入 products")
        XCTAssertFalse(didCallOnProductsChanged, "updateProduct 找不到目标时，不应该触发 onProductsChanged")
    }

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

        var didReceiveErrorState = false
        var didReceiveEmptyState = false
        var didCallOnProductsChanged = false
        var didReceiveNoMoreDataFooterState = false

        viewModel.onProductsChanged = { _ in
            didCallOnProductsChanged = true
        }

        viewModel.onViewStateChanged = { state in
            switch state {
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

        viewModel.loadData(mode: .refresh)

        XCTAssertEqual(mockService.requestedPage, 1, "cancelled refresh 仍然是请求第 1 页")
        XCTAssertEqual(viewModel.products.count, 2, "cancelled 不应该清空旧数据")
        XCTAssertEqual(viewModel.products.first?.id, 1, "cancelled 后第一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.first?.title, "旧标题1", "cancelled 后第一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.first?.body, "旧内容1", "cancelled 后第一条旧数据 body 应该保留")
        XCTAssertEqual(viewModel.products.last?.id, 2, "cancelled 后最后一条旧数据 id 应该保留")
        XCTAssertEqual(viewModel.products.last?.title, "旧标题2", "cancelled 后最后一条旧数据 title 应该保留")
        XCTAssertEqual(viewModel.products.last?.body, "旧内容2", "cancelled 后最后一条旧数据 body 应该保留")
        XCTAssertFalse(didReceiveErrorState, "cancelled 不应该进入 error")
        XCTAssertFalse(didReceiveEmptyState, "cancelled 不是空数据，不应该进入 empty")
        XCTAssertFalse(didCallOnProductsChanged, "cancelled 没有新数据，不应该触发 onProductsChanged")
        XCTAssertFalse(didReceiveNoMoreDataFooterState, "cancelled 不应该污染 FooterState")
    }
    
    // MARK: - Helpers
    private func makeProduct(
        userId: Int = 1,
        id: Int,
        title: String,
        body: String
    ) -> Product {
        return Product(userId: userId, id: id, title: title, body: body)
    }

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
    private func makeViewModel(service: ProductServiceProtocol) -> ProductListViewModel {
        return ProductListViewModel(service: service)
    }
    
}
