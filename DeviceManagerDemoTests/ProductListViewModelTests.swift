//
//  ProductListViewModelTests.swift
//  DeviceManagerDemoTests
//
//  Created by 天亮了 on 2026/5/6.
//

//引入 Apple 的单元测试框架。
import XCTest

//让测试 Target 可以访问主工程里的 internal 类型和方法。
@testable import DeviceManagerDemo

//说明这是一个测试类，里面可以写 test 开头的测试方法。
final class ProductListViewModelTests: XCTestCase {

    // MARK: - Initial
    
    func testInitialSuccess_updatesProductsAndShowsContent() {

        // Given：准备假 Service，让它模拟“请求成功”
        let mockService = MockProductService()

        let mockProducts = [
            Product(userId: 1, id: 1, title: "标题1", body: "内容1"),
            Product(userId: 1, id: 2, title: "标题2", body: "内容2")
        ]

        mockService.result = .success(mockProducts)

        let viewModel = ProductListViewModel(service: mockService)

        var didCallOnProductsChanged = false
        var didReceiveContentState = false
        var didReceiveNoMoreDataFooterState = false

        viewModel.onProductsChanged = { products in
            didCallOnProductsChanged = true
            XCTAssertEqual(products.count, 2)
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
        XCTAssertEqual(mockService.requestedPage, 1)

        // Then：验证 ViewModel 把 pageSize 正确传给 Service
        XCTAssertEqual(mockService.requestedPageSize, 10)

        // Then：验证请求成功后，ViewModel 成功保存 products 数量
        XCTAssertEqual(viewModel.products.count, 2)

        // Then：验证第一条 Product 的 id / title / body 都正确
        XCTAssertEqual(viewModel.products.first?.id, 1)
        XCTAssertEqual(viewModel.products.first?.title, "标题1")
        XCTAssertEqual(viewModel.products.first?.body, "内容1")

        // Then：验证最后一条 Product 的 id / title / body 都正确
        XCTAssertEqual(viewModel.products.last?.id, 2)
        XCTAssertEqual(viewModel.products.last?.title, "标题2")
        XCTAssertEqual(viewModel.products.last?.body, "内容2")

        // Then：验证 ViewModel 请求成功后通知 VC 刷新列表
        XCTAssertTrue(didCallOnProductsChanged)

        // Then：验证 initial 成功并且有数据时，页面最终进入 content 状态
        XCTAssertTrue(didReceiveContentState)

        // Then：验证返回数据数量小于 pageSize 时，footer 进入 noMoreData 状态
        XCTAssertTrue(didReceiveNoMoreDataFooterState)

    }

    // MARK: - Refresh

    // MARK: - Load More

    // MARK: - Failure

    // MARK: - Update Product

    // MARK: - Helpers
}
