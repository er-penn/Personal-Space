//
//  APIService.swift
//  Personal Space
//
//  网络服务层 - 负责所有与后端API的通信
//

import Foundation
import Combine

// MARK: - API错误类型
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "服务器未返回数据"
        case .decodingError:
            return "数据解析失败"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .unauthorized:
            return "未授权，请重新登录"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}

// MARK: - API响应模型
struct APIResponse<T: Codable>: Codable {
    let code: Int?
    let message: String?
    let data: T?
    let detail: String?  // Django错误详情
}

// MARK: - Django REST Framework错误响应
struct DetailResponse: Codable {
    let detail: String?
}

// MARK: - 登录响应
struct LoginResponse: Codable {
    let access: String
    let refresh: String
}

// MARK: - 用户信息
struct UserInfo: Codable {
    let id: String
    let phone: String
    let nickname: String?
    let avatar_url: String?
    let current_energy_level: String
    let focus_mode_enabled: Bool
    let created_at: String
    let updated_at: String
    let last_seen_at: String?
}

// MARK: - API服务类
class APIService: ObservableObject {
    // MARK: - 单例
    static let shared = APIService()
    
    // MARK: - 配置
    #if DEBUG
    // 使用127.0.0.1而不是localhost，避免iOS模拟器IPv6连接问题
    private let baseURL = "http://127.0.0.1:8000/api/v1"
    #else
    private let baseURL = "https://your-production-domain.com/api/v1"  // 生产环境URL
    #endif
    
    // MARK: - Token管理
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    @Published var accessToken: String? {
        didSet {
            if let token = accessToken {
                UserDefaults.standard.set(token, forKey: accessTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
            }
        }
    }
    
    @Published var refreshToken: String? {
        didSet {
            if let token = refreshToken {
                UserDefaults.standard.set(token, forKey: refreshTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: refreshTokenKey)
            }
        }
    }
    
    var isLoggedIn: Bool {
        return accessToken != nil
    }
    
    // MARK: - 初始化
    private init() {
        // 从UserDefaults加载已保存的Token
        self.accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        self.refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    // MARK: - 通用请求方法
    private func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        // 构建URL
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证头
        if requiresAuth {
            if let token = accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.unauthorized
            }
        }
        
        // 添加请求体
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    // Token过期，尝试刷新
                    if let _ = try? await refreshAccessToken() {
                        // 重新发送请求
                        if requiresAuth, let token = accessToken {
                            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        }
                        let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
                        return try decodeResponse(data: retryData, response: retryResponse)
                    } else {
                        throw APIError.unauthorized
                    }
                }
            }
            
            return try decodeResponse(data: data, response: response)
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - 响应解码
    private func decodeResponse<T: Codable>(data: Data, response: URLResponse) throws -> T {
        // 检查HTTP状态码
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                // 尝试解析Django REST Framework标准错误格式: {"detail": "..."}
                if let detailResponse = try? JSONDecoder().decode(DetailResponse.self, from: data),
                   let detail = detailResponse.detail {
                    throw APIError.serverError(detail)
                }
                // 尝试解析错误信息
                if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                    let errorMessage = errorResponse.detail ?? errorResponse.message ?? "服务器错误"
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("HTTP错误: \(httpResponse.statusCode)")
            }
        }
        
        // 尝试解析为APIResponse
        if let apiResponse = try? JSONDecoder().decode(APIResponse<T>.self, from: data),
           let data = apiResponse.data {
            return data
        }
        
        // 尝试直接解析
        if let directResponse = try? JSONDecoder().decode(T.self, from: data) {
            return directResponse
        }
        
        // 如果都不行，尝试解析LoginResponse（JWT返回格式不同）
        if T.self == LoginResponse.self,
           let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
            return loginResponse as! T
        }
        
        throw APIError.decodingError
    }
    
    // MARK: - 刷新Token
    private func refreshAccessToken() async throws {
        guard let refresh = refreshToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/auth/refresh/") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh": refresh]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        accessToken = response.access
        refreshToken = response.refresh
    }
    
    // MARK: - 认证相关API
    
    /// 注册
    struct RegisterResponse: Codable {
        let id: String
        let phone: String
        let nickname: String?
        let message: String
    }
    
    func register(phone: String, password: String, passwordConfirm: String, nickname: String? = nil) async throws -> RegisterResponse {
        var body: [String: Any] = [
            "phone": phone,
            "password": password,
            "password_confirm": passwordConfirm
        ]
        
        if let nickname = nickname, !nickname.isEmpty {
            body["nickname"] = nickname
        }
        
        let response: RegisterResponse = try await request(
            endpoint: "/auth/register/",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        
        return response
    }
    
    /// 登录
    /// 注意：后端API需要phone字段
    func login(phone: String, password: String) async throws -> LoginResponse {
        let body = [
            "phone": phone,
            "password": password
        ]
        
        let response: LoginResponse = try await request(
            endpoint: "/auth/login/",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        
        // 保存Token
        accessToken = response.access
        refreshToken = response.refresh
        
        return response
    }
    
    /// 登出
    func logout() {
        accessToken = nil
        refreshToken = nil
    }
    
    // MARK: - 用户相关API
    
    /// 获取当前用户信息
    func getCurrentUser() async throws -> UserInfo {
        return try await request(endpoint: "/users/me/", method: "GET")
    }
    
    /// 更新用户信息
    func updateUser(nickname: String? = nil, avatar_url: String? = nil) async throws -> UserInfo {
        var body: [String: Any] = [:]
        if let nickname = nickname {
            body["nickname"] = nickname
        }
        if let avatar_url = avatar_url {
            body["avatar_url"] = avatar_url
        }
        
        return try await request(endpoint: "/users/me/update/", method: "PUT", body: body)
    }
    
    // MARK: - 能量相关API
    
    /// 时间段模型
    struct TimeSlot: Codable {
        let start_hour: Int
        let start_minute: Int
        let end_hour: Int
        let end_minute: Int
    }
    
    /// 能量记录模型
    struct EnergyRecord: Codable, Identifiable {
        let id: String
        let date: String
        let energy_level: String
        let time_slots: [TimeSlot]
        let temporary_type: String?
        let original_energy_level: String?
        let created_at: String
        let updated_at: String
    }
    
    /// 当前状态响应
    struct CurrentStatusResponse: Codable {
        let current_status: CurrentStatus
        let partner_status: PartnerStatus?
        
        struct CurrentStatus: Codable {
            let base_energy_level: String
            let display_energy_level: String
            let temporary_state: TemporaryState
            let planned_state: PlannedState
            
            struct TemporaryState: Codable {
                let is_active: Bool
                let type: String?
                let remaining_minutes: Int
            }
            
            struct PlannedState: Codable {
                let is_active: Bool
                let level: String?
                let remaining_minutes: Int
            }
        }
        
        struct PartnerStatus: Codable {
            let energy_level: String
        }
    }
    
    /// 能量记录响应
    struct EnergyRecordsResponse: Codable {
        let records: Records
        let summary: Summary
        
        struct Records: Codable {
            let base: [EnergyRecord]
            let planned: [EnergyRecord]
            let temporary: [EnergyRecord]
        }
        
        struct Summary: Codable {
            let high_minutes: Int
            let medium_minutes: Int
            let low_minutes: Int
            let unplanned_minutes: Int
        }
    }
    
    /// 能量预规划响应
    struct EnergyPlansResponse: Codable {
        let plans: [EnergyPlan]
        
        struct EnergyPlan: Codable, Identifiable {
            let id: String
            let date: String
            let energy_level: String
            let time_slots: [TimeSlot]
            let created_at: String
        }
    }
    
    /// 伴侣状态响应
    struct PartnerStatusResponse: Codable {
        let partner_status: PartnerStatus
        
        struct PartnerStatus: Codable {
            let energy_level: String
            let records: Records
            
            struct Records: Codable {
                let base: [EnergyRecord]
            }
        }
    }
    
    /// 获取当前能量状态
    func getCurrentEnergyStatus() async throws -> CurrentStatusResponse {
        return try await request(endpoint: "/energy/current-status/", method: "GET")
    }
    
    /// 更新当前能量状态
    func updateCurrentEnergyLevel(energyLevel: String) async throws -> UpdateEnergyLevelResponse {
        let body = ["energy_level": energyLevel]
        return try await request(endpoint: "/energy/current-status/", method: "PUT", body: body)
    }
    
    struct UpdateEnergyLevelResponse: Codable {
        let energy_level: String
        let updated_at: String
    }
    
    /// 获取能量记录
    func getEnergyRecords(date: String? = nil, type: String? = nil) async throws -> EnergyRecordsResponse {
        var queryItems: [String] = []
        if let date = date {
            queryItems.append("date=\(date)")
        }
        if let type = type {
            queryItems.append("type=\(type)")
        }
        
        let queryString = queryItems.isEmpty ? "" : "?\(queryItems.joined(separator: "&"))"
        return try await request(endpoint: "/energy/records/\(queryString)", method: "GET")
    }
    
    /// 更新基础状态记录（包括时间段）
    func updateBaseEnergyRecord(date: String? = nil, energyLevel: String? = nil, timeSlots: [[String: Int]]? = nil) async throws -> UpdateBaseEnergyRecordResponse {
        var body: [String: Any] = [:]
        if let date = date {
            body["date"] = date
        }
        if let energyLevel = energyLevel {
            body["energy_level"] = energyLevel
        }
        if let timeSlots = timeSlots {
            body["time_slots"] = timeSlots
        }
        return try await request(endpoint: "/energy/records/base/", method: "PUT", body: body)
    }
    
    struct UpdateBaseEnergyRecordResponse: Codable {
        let id: String
        let record_date: String
        let energy_level: String
        let time_slots: [TimeSlot]
        let updated_at: String
    }
    
    /// 获取能量预规划
    func getEnergyPlans(date: String? = nil) async throws -> EnergyPlansResponse {
        let queryString = date != nil ? "?date=\(date!)" : ""
        return try await request(endpoint: "/energy/plans/\(queryString)", method: "GET")
    }
    
    /// 创建能量预规划
    func createEnergyPlan(date: String, energyLevel: String, timeSlots: [[String: Int]]) async throws -> EnergyPlansResponse.EnergyPlan {
        let body: [String: Any] = [
            "date": date,
            "energy_level": energyLevel,
            "time_slots": timeSlots
        ]
        return try await request(endpoint: "/energy/plans/create/", method: "POST", body: body)
    }
    
    /// 创建临时状态
    func createTemporaryState(type: String, durationMinutes: Int) async throws -> TemporaryStateResponse {
        let body: [String: Any] = [
            "type": type,
            "duration_minutes": durationMinutes
        ]
        return try await request(endpoint: "/energy/temporary-state/", method: "POST", body: body)
    }
    
    struct TemporaryStateResponse: Codable {
        let id: String
        let type: String
        let start_time: String
        let end_time: String
        let remaining_minutes: Int
    }
    
    /// 结束临时状态
    func endTemporaryState(id: String? = nil) async throws -> EndTemporaryStateResponse {
        var endpoint = "/energy/temporary-state/end/"
        if let id = id {
            endpoint += "?id=\(id)"
        }
        return try await request(endpoint: endpoint, method: "DELETE", body: nil)
    }
    
    struct EndTemporaryStateResponse: Codable {
        let message: String
    }
    
    /// 获取伴侣状态
    func getPartnerStatus() async throws -> PartnerStatusResponse {
        return try await request(endpoint: "/energy/partner-status/", method: "GET")
    }
}

