import Foundation

extension UserDefaults {
    
    /// Environment-specific UserDefaults instance
    static var environmentSpecific: UserDefaults {
        let suiteName = EnvironmentManager.shared.getUserDefaultsSuite()
        return UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    /// Get value from environment-specific UserDefaults
    static func environmentValue<T>(forKey key: String, defaultValue: T) -> T {
        return environmentSpecific.object(forKey: key) as? T ?? defaultValue
    }
    
    /// Set value to environment-specific UserDefaults
    static func environmentSet<T>(_ value: T, forKey key: String) {
        environmentSpecific.set(value, forKey: key)
    }
    
    /// Remove value from environment-specific UserDefaults
    static func environmentRemove(forKey key: String) {
        environmentSpecific.removeObject(forKey: key)
    }
    
    /// Synchronize environment-specific UserDefaults
    static func environmentSynchronize() -> Bool {
        return environmentSpecific.synchronize()
    }
} 