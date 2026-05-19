//
//  NetworkError.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/28.
//

import Foundation

/// 网络请求过程中可能出现的错误类型。
///
/// 这个 enum 不是系统固定写法，是我们自己定义的错误模型。
/// 它的作用是：把一次网络请求失败的原因，按“请求链路”拆清楚。
///
/// 一次完整请求大概会经过这些步骤：
///
/// 1. 先根据字符串创建 URL
/// 2. 用 URLSession 发出请求
/// 3. 拿到 response 后，确认它是不是 HTTPURLResponse
/// 4. 判断 HTTP 状态码是否成功，例如 200...299
/// 5. 确认 data 是否存在
/// 6. 用 JSONDecoder 把 data 解码成 Swift Model
///
/// 以前如果只返回系统 Error，列表页只能知道“失败了”。
/// 现在用 NetworkError，就可以知道是：
/// - URL 拼错了
/// - 网络层失败了
/// - response 类型不对
/// - HTTP 状态码失败了
/// - JSON 解码失败了
///
/// 这样后面在 ProductListViewController 里处理失败时，
/// 就可以根据不同错误类型，显示不同提示、打不同日志、做不同兜底策略。
enum NetworkError: Error {

    /// URL 创建失败。
    ///
    /// 发生时机：请求还没有真正发出去。
    ///
    /// 常见原因：
    /// - URL 字符串写错
    /// - URL 中包含非法字符
    /// - 拼接参数时格式不正确
    ///
    /// 举例：
    /// ```swift
    /// URL(string: "https://xxx .com")
    /// ```
    /// 如果字符串不合法，URL(string:) 就可能返回 nil。
    /// 这时候连 URLSession 都还没开始工作，所以属于“请求前失败”。
    case invalidURL

    /// URLSession / 系统网络层请求失败。
    ///
    /// 发生时机：URL 已经创建成功，请求也已经交给 URLSession 执行，
    /// 但是系统网络层返回了 error。
    ///
    /// 常见原因：
    /// - 手机断网
    /// - 请求超时
    /// - DNS 解析失败
    /// - 服务器无法连接
    /// - 网络权限或系统网络环境异常
    ///
    /// 这里的 Error 是系统给我们的原始错误，
    /// 所以要用关联值保存下来，方便调试时 print 出更具体的信息。
    ///
    /// 注意：
    /// 这个错误不是服务器业务 code 返回的失败。
    /// 它主要表示“网络请求这一层没有正常完成”。
    case requestFailed(Error)

    /// response 不是 HTTPURLResponse。
    ///
    /// 发生时机：URLSession 回来了 response，
    /// 但这个 response 不能转换成 HTTPURLResponse。
    ///
    /// 为什么要判断：
    /// 只有 HTTPURLResponse 里面才有 HTTP 状态码，
    /// 比如 200、401、404、500。
    ///
    /// 如果转换失败，说明这次返回不是标准的 HTTP 响应，
    /// 后面就不能继续判断 statusCode。
    ///
    /// 常见写法：
    /// ```swift
    /// guard let httpResponse = response as? HTTPURLResponse else {
    ///     completion(.failure(.invalidResponse))
    ///     return
    /// }
    /// ```
    case invalidResponse

    /// HTTP 状态码失败。
    ///
    /// 发生时机：已经成功拿到 HTTPURLResponse，
    /// 但是 statusCode 不在 200...299 范围内。
    ///
    /// 常见状态码：
    /// - 401：未授权，可能 token 失效
    /// - 403：没有权限
    /// - 404：接口地址不存在
    /// - 500：服务器内部错误
    ///
    /// 这里的 Int 是服务器返回的 HTTP 状态码。
    /// 保存它的原因是：后面可以根据不同状态码做不同处理。
    ///
    /// 注意：
    /// HTTP 状态码失败，说明请求已经到达 HTTP 层了。
    /// 它和 requestFailed(Error) 不是一回事。
    case invalidStatusCode(Int)

    /// 返回 data 为空。
    ///
    /// 发生时机：URL 正确、请求成功、response 正常、状态码成功，
    /// 但是 URLSession 回调里的 `data` 是 nil。
    ///
    /// 注意：
    /// `noData` 不是“服务器正常返回空数组”。
    ///
    /// - `success([])`：表示请求成功，但业务数据为空，应该走 empty 状态。
    /// - `noData`：表示连可解析的响应体都没有，属于请求链路异常。
    case noData

    /// JSON 解码失败。
    ///
    /// 发生时机：URL 正确、请求成功、response 正常、状态码成功、data 也存在，
    /// 但是 JSONDecoder 无法把 data 解码成我们需要的 Swift Model。
    ///
    /// 常见原因：
    /// - Model 字段名和 JSON 字段名不一致
    /// - Model 字段类型写错，例如 JSON 是 String，Model 写成 Int
    /// - 后端返回结构变了
    /// - 当前接口返回的不是数组，但我们按数组去 decode
    ///
    /// 这里的 Error 是 JSONDecoder 给出的原始解码错误。
    /// 保存它的原因是：调试时可以看到具体是哪个字段、哪个类型失败。
    ///
    /// 注意：
    /// decodingFailed 不代表网络请求失败。
    /// 它代表“网络已经成功拿到数据，但 Swift Model 解析失败”。
    case decodingFailed(Error)

    /// 业务失败。
    ///
    /// 发生时机：HTTP 层成功、JSON 也成功解出了 `ApiResponse<T>`，
    /// 但是后端返回的业务 `code` 不是成功码。
    ///
    /// 举例：
    /// ```json
    /// {
    ///     "code": 1001,
    ///     "message": "商品不存在",
    ///     "data": null
    /// }
    /// ```
    ///
    /// 注意：
    /// - `invalidStatusCode(Int)`：表示 HTTP 状态码失败，例如 404、500。
    /// - `businessFailed(code:message:)`：表示 HTTP 成功，但业务 code 失败。
    case businessFailed(code: Int, message: String)

    /// 登录态失效 / 未授权。
    ///
    /// 发生时机可能有两种：
    /// 1. HTTP 层直接返回 `statusCode = 401`
    /// 2. HTTP 200，但业务响应体里 `code = 401`
    ///
    /// 这种错误通常表示：
    /// - 未登录
    /// - token 过期
    /// - token 无效
    /// - 账号被踢下线
    ///
    /// 注意：
    /// NetworkClient 只负责识别 `unauthorized` 并返回错误，
    /// 不应该在网络层直接 push 登录页。
    /// 跳登录页应该交给 VC / RootVC / Coordinator 等上层统一处理。
    case unauthorized(message: String)
}
