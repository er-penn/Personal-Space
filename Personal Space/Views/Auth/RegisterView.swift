//
//  RegisterView.swift
//  Personal Space
//
//  注册视图
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var apiService = APIService.shared
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    @State private var nickname: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showAlert: Bool = false
    @State private var registerSuccess: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppGradient.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo或标题
                        VStack(spacing: 10) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.purple)
                            
                            Text("注册账号")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("创建你的边界舱账号")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // 注册表单
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
                            
                            // 昵称输入（可选）
                            VStack(alignment: .leading, spacing: 8) {
                                Text("昵称（可选）")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("请输入昵称", text: $nickname)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                            }
                            
                            // 密码输入
                            VStack(alignment: .leading, spacing: 8) {
                                Text("密码")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                SecureField("请输入密码（至少6位）", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // 确认密码输入
                            VStack(alignment: .leading, spacing: 8) {
                                Text("确认密码")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                SecureField("请再次输入密码", text: $passwordConfirm)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // 注册按钮
                            Button(action: {
                                Task {
                                    await performRegister()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("注册")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? Color.purple : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!isFormValid || isLoading)
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
                        
                        // 已有账号，去登录
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Text("已有账号？")
                                    .foregroundColor(.secondary)
                                Text("去登录")
                                    .foregroundColor(.purple)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("注册成功", isPresented: $showAlert) {
                Button("确定", role: .cancel) {
                    registerSuccess = true
                }
            } message: {
                Text("账号注册成功！请登录")
            }
        }
        .fullScreenCover(isPresented: $registerSuccess) {
            LoginView()
        }
    }
    
    // MARK: - 表单验证
    private var isFormValid: Bool {
        !phone.isEmpty &&
        !password.isEmpty &&
        !passwordConfirm.isEmpty &&
        password.count >= 6 &&
        password == passwordConfirm
    }
    
    // MARK: - 注册操作
    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        
        // 前端验证
        guard password.count >= 6 else {
            await MainActor.run {
                isLoading = false
                errorMessage = "密码长度至少6位"
            }
            return
        }
        
        guard password == passwordConfirm else {
            await MainActor.run {
                isLoading = false
                errorMessage = "两次密码输入不一致"
            }
            return
        }
        
        do {
            _ = try await apiService.register(
                phone: phone,
                password: password,
                passwordConfirm: passwordConfirm,
                nickname: nickname.isEmpty ? nil : nickname
            )
            
            // 注册成功
            await MainActor.run {
                isLoading = false
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if let apiError = error as? APIError {
                    errorMessage = apiError.errorDescription
                } else {
                    errorMessage = "注册失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}

