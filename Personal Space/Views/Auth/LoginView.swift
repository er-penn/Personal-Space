//
//  LoginView.swift
//  Personal Space
//
//  登录视图 - 演示前后端连接
//

import SwiftUI

struct LoginView: View {
    @StateObject private var apiService = APIService.shared
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    @State private var loginSuccess: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo或标题
                    VStack(spacing: 10) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("边界舱")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("登录以继续")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    // 登录表单
                    VStack(spacing: 20) {
                        // 手机号输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("手机号")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("请输入手机号", text: $phone)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                                .autocapitalization(.none)
                        }
                        
                        // 密码输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("请输入密码", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // 登录按钮
                        Button(action: {
                            Task {
                                await performLogin()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("登录")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(phone.isEmpty || password.isEmpty ? Color.gray : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(phone.isEmpty || password.isEmpty || isLoading)
                        .padding(.top, 10)
                        
                        // 错误提示
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // 提示信息
                    VStack(spacing: 5) {
                        Text("测试账号")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("请使用后端数据库中存在的用户")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .alert("登录成功", isPresented: $showAlert) {
                Button("确定", role: .cancel) {
                    loginSuccess = true
                }
            } message: {
                Text("已成功连接到后端服务器！")
            }
        }
        .fullScreenCover(isPresented: $loginSuccess) {
            MainTabView()
        }
    }
    
    // MARK: - 登录操作
    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiService.login(phone: phone, password: password)
            
            // 登录成功
            await MainActor.run {
                isLoading = false
                showAlert = true
                
                // 可以在这里获取用户信息
                Task {
                    do {
                        let userInfo = try await apiService.getCurrentUser()
                        print("登录成功，用户信息: \(userInfo)")
                    } catch {
                        print("获取用户信息失败: \(error)")
                    }
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if let apiError = error as? APIError {
                    errorMessage = apiError.errorDescription
                } else {
                    errorMessage = "登录失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LoginView()
}

