// MARK: MQGram - Proxy API Client
import Foundation

public struct MQGramProxyServer: Codable, Equatable {
    public let id: String
    public let name: String
    public let server: String
    public let port: Int
    public let secret: String
    public let created_at: String
}

public final class MQGramProxyAPI {
    public static let shared = MQGramProxyAPI()

    private static let adminUserIds: Set<Int64> = [8228905313]

    private init() {}

    public var baseURL: String {
        return UserDefaults.standard.string(forKey: "MQGram.proxyAPIBaseURL") ?? ""
    }

    public var adminToken: String {
        return UserDefaults.standard.string(forKey: "MQGram.proxyAdminToken") ?? ""
    }

    public static var isConfigured: Bool {
        let url = UserDefaults.standard.string(forKey: "MQGram.proxyAPIBaseURL") ?? ""
        return !url.isEmpty
    }

    public static func isAdmin(userId: Int64) -> Bool {
        return adminUserIds.contains(userId)
    }

    public static func configure(baseURL: String, adminToken: String = "") {
        UserDefaults.standard.set(baseURL, forKey: "MQGram.proxyAPIBaseURL")
        UserDefaults.standard.set(adminToken, forKey: "MQGram.proxyAdminToken")
    }

    public func fetchProxies(completion: @escaping ([MQGramProxyServer]) -> Void) {
        let base = baseURL
        guard !base.isEmpty, let url = URL(string: "\(base)/api/proxies") else {
            completion([])
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let proxies = (try? JSONDecoder().decode([MQGramProxyServer].self, from: data)) ?? []
            DispatchQueue.main.async { completion(proxies) }
        }.resume()
    }

    public func addProxy(name: String, server: String, port: Int, secret: String, completion: @escaping (MQGramProxyServer?) -> Void) {
        let base = baseURL
        let token = adminToken
        guard !base.isEmpty, !token.isEmpty,
              let url = URL(string: "\(base)/api/proxies") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let body: [String: Any] = ["name": name, "server": server, "port": port, "secret": secret]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let proxy = try? JSONDecoder().decode(MQGramProxyServer.self, from: data)
            DispatchQueue.main.async { completion(proxy) }
        }.resume()
    }

    public func deleteProxy(id: String, completion: @escaping (Bool) -> Void) {
        let base = baseURL
        let token = adminToken
        guard !base.isEmpty, !token.isEmpty,
              let url = URL(string: "\(base)/api/proxies/\(id)") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 204
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }
}
