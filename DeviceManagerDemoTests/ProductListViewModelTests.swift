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

    func testInitialSuccess() {

        // Given：准备假 Service，让它模拟“请求成功”

        let mockService = MockProductService()

        let mockProducts = [

            Product(userId: 1, id: 1, title: "标题1", body: "内容1"),

            Product(userId: 1, id: 2, title: "标题2", body: "内容2")

        ]

        mockService.result = .success(mockProducts)

        let viewModel = ProductListViewModel(service: mockService)

        // When：模拟 VC 触发首次加载

        viewModel.loadData(mode: .initial)

        // Then：检查 ViewModel 的结果是否符合预期

        XCTAssertEqual(mockService.requestedPage, 1)

        XCTAssertEqual(viewModel.products.count, 2)

        XCTAssertEqual(viewModel.products.first?.title, "标题1")

        XCTAssertEqual(viewModel.products.last?.body, "内容2")

    }
    
}
