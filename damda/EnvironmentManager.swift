import Foundation

class EnvironmentManager: ObservableObject {
    static let shared = EnvironmentManager()
    
    @Published var currentEnvironment: Environment = .production
    @Published var config: EnvironmentConfig
    
    private init() {
        self.config = EnvironmentManager.loadConfig()
        self.currentEnvironment = EnvironmentManager.detectEnvironment()
    }
    
    // MARK: - Environment Detection
    
    enum Environment: String, CaseIterable {
        case production = "Production"
        case development = "Development"
        
        var bundleIdentifier: String {
            switch self {
            case .production:
                return "com.beomsooshin.damda"
            case .development:
                return "dev.com.beomsooshin.damda-dev"
            }
        }
        
        var coreDataModelName: String {
            switch self {
            case .production:
                return "damda"
            case .development:
                return "damda-dev"
            }
        }
        
        var userDefaultsSuite: String {
            switch self {
            case .production:
                return "com.beomsooshin.damda"
            case .development:
                return "dev.com.beomsooshin.damda-dev"
            }
        }
    }
    
    // MARK: - Configuration
    
    struct EnvironmentConfig {
        let environment: String
        let logLevel: String
        let enableAnalytics: Bool
        let enableDebugMenu: Bool
        let coreDataModelName: String
        let userDefaultsSuite: String
        
        init(from plist: [String: Any]) {
            self.environment = plist["Environment"] as? String ?? "Unknown"
            self.logLevel = plist["LogLevel"] as? String ?? "INFO"
            self.enableAnalytics = plist["EnableAnalytics"] as? Bool ?? false
            self.enableDebugMenu = plist["EnableDebugMenu"] as? Bool ?? false
            self.coreDataModelName = plist["CoreDataModelName"] as? String ?? "damda"
            self.userDefaultsSuite = plist["UserDefaultsSuite"] as? String ?? "com.beomsooshin.damda"
        }
    }
    
    // MARK: - Private Methods
    
    private static func detectEnvironment() -> Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    private static func loadConfig() -> EnvironmentConfig {
        let environment = detectEnvironment()
        let configFileName = "Config-\(environment.rawValue)"
        
        guard let path = Bundle.main.path(forResource: configFileName, ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("⚠️ Warning: Could not load \(configFileName).plist, using default config")
            return EnvironmentConfig(from: [:])
        }
        
        return EnvironmentConfig(from: plist)
    }
    
    // MARK: - Public Methods
    
    func getCoreDataModelName() -> String {
        return currentEnvironment.coreDataModelName
    }
    
    func getUserDefaultsSuite() -> String {
        return currentEnvironment.userDefaultsSuite
    }
    
    func isDevelopment() -> Bool {
        return currentEnvironment == .development
    }
    
    func isProduction() -> Bool {
        return currentEnvironment == .production
    }
    
    func getLogLevel() -> String {
        return config.logLevel
    }
    
    func shouldEnableAnalytics() -> Bool {
        return config.enableAnalytics
    }
    
    func shouldShowDebugMenu() -> Bool {
        return config.enableDebugMenu
    }
} 