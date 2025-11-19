//
//  Personal_SpaceApp.swift
//  Personal Space
//
//  Created by Penn on 2025/9/21.
//

import SwiftUI

@main
struct Personal_SpaceApp: App {
    @StateObject private var apiService = APIService.shared
    
    var body: some Scene {
        WindowGroup {
            // 根据登录状态显示不同视图
            if apiService.isLoggedIn {
            MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
