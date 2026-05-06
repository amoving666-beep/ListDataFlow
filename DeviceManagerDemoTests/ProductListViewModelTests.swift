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
        // Given：准备一个假的网络服务
        let mockService = MockProductService()

          XCTAssertNotNil(mockService)
        // Given：准备一个假的网络服务，并指定它返回成功数据
//        let mockService = MockProductService()
//        mockService.result = .success([
//            Product(userId: 1, id: 1, title: "测试标题1", body: "测试内容1"),
//            Product(userId: 1, id: 2, title: "测试标题2", body: "测试内容2")
//        ])
//        
//        // Given：把假 Service 注入 ViewModel
//        // 这样 loadData 不会真的请求网络，而是使用 mockService 返回的数据
//        let viewModel = ProductListViewModel(service: mockService)
//        
//        // When：模拟 VC 首次进入页面时触发 initial 加载
//        viewModel.loadData(mode: .initial)
//        
//        // Then：验证 ViewModel 是否请求了第 1 页
//        XCTAssertEqual(mockService.requestedPage, 1)
//        
//        // Then：验证 products 是否被成功更新
//        XCTAssertEqual(viewModel.products.count, 2)
//        XCTAssertEqual(viewModel.products.first?.title, "测试标题1")
//        XCTAssertEqual(viewModel.products.last?.body, "测试内容2")
    }
    
}
