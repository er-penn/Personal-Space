//
//  MainTabView.swift
//  Personal Space
//
//  Created by Penn on 2025/1/27.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var userState = UserState()
    @StateObject private var partnerState = PartnerState()
    @StateObject private var growthGarden = GrowthGarden()
    
    var body: some View {
        TabView {
            MySpaceView()
                .environmentObject(userState)
                .environmentObject(partnerState)
                .environmentObject(growthGarden)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我的空间")
                }
            
            OurSpaceView()
                .environmentObject(userState)
                .environmentObject(partnerState)
                .environmentObject(growthGarden)
                .tabItem {
                    Image(systemName: "heart.circle")
                    Text("我们的空间")
                }
            
            ProfileView()
                .environmentObject(userState)
                .environmentObject(partnerState)
                .tabItem {
                    Image(systemName: "gearshape.circle")
                    Text("个人中心")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}
