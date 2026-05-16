//
//  SceneDelegate.swift
//  DeviceManagerDemo
//
//  Created by 天亮了 on 2026/4/16.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        //拿到当前 App 场景对应的 UIWindowScene。拿不到就不继续。
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        //创建窗口。iOS 13 以后，一个 Scene 对应一个 Window。
        let window = UIWindow(windowScene: windowScene)
        
        
        if isRunningUnitTests {
            print("当前是单元测试环境，不启动真实首页")

            window.rootViewController = UIViewController()
            window.makeKeyAndVisible()
            self.window = window
            return
        }
        
        //创建你的列表页。
        let rootVC = HomeViewController()
        
        //创建导航控制器，并把列表页作为导航栈第一个页面。
        let nav = UINavigationController(rootViewController: rootVC)
        
        //让 window 显示导航控制器。
        window.rootViewController = nav
        
        //让 window 成为主窗口，并显示出来。
        window.makeKeyAndVisible()
        
        //SceneDelegate 持有这个 window，避免它被释放。
        ///
        ///把局部变量 window 保存到 SceneDelegate 的 window 属性里。
        ///让 SceneDelegate 强引用这个 UIWindow。
        ///只要 SceneDelegate 还在，window 就不会被释放。
        ///
        ///
        self.window = window
        
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private var isRunningUnitTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
             || NSClassFromString("XCTest.XCTestCase") != nil
    }
}
