// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP

public class UserDefaults {
    let platformValue: android.content.SharedPreferences
    /// The default default values
    private var registrationDictionary: [String: Any] = [:]

    init(platformValue: android.content.SharedPreferences) {
        self.platformValue = platformValue
    }

    init(_ platformValue: android.content.SharedPreferences) {
        self.platformValue = platformValue
    }

    public static var standard: UserDefaults {
        UserDefaults(suiteName: nil)
    }

    public init(suiteName: String?) {
        platformValue = ProcessInfo.processInfo.androidContext.getSharedPreferences(suiteName ?? "defaults", android.content.Context.MODE_PRIVATE)
    }

    public func register(defaults registrationDictionary: [String : Any]) {
        self.registrationDictionary = registrationDictionary
    }

    public func registerOnSharedPreferenceChangeListener(key: String, onChange: () -> ()) -> AnyObject {
        let listener = android.content.SharedPreferences.OnSharedPreferenceChangeListener { (_, changedKey: String?) in
            if let changedKey = changedKey, key == changedKey {
                onChange()
            }
        }

        platformValue.registerOnSharedPreferenceChangeListener(listener)
        return listener
    }

    public func `set`(_ value: Int, forKey defaultName: String) {
        let prefs = platformValue.edit()
        prefs.putInt(defaultName, value)
        prefs.apply()
    }

    public func `set`(_ value: Boolean, forKey defaultName: String) {
        let prefs = platformValue.edit()
        prefs.putBoolean(defaultName, value)
        prefs.apply()
    }

    public func `set`(_ value: Double, forKey defaultName: String) {
        let prefs = platformValue.edit()
        prefs.putFloat(defaultName, value.toFloat())
        prefs.apply()
    }

    public func `set`(_ value: String, forKey defaultName: String) {
        let prefs = platformValue.edit()
        prefs.putString(defaultName, value)
        prefs.apply()
    }

    public func `set`(_ value: Any?, forKey defaultName: String) {
        let prefs = platformValue.edit()
        defer { prefs.apply() }

        if let v = value as? Float {
            prefs.putFloat(defaultName, v.toFloat())
        } else if let v = value as? Int64 {
            prefs.putLong(defaultName, v)
        } else if let v = value as? Int {
            prefs.putInt(defaultName, v)
        } else if let v = value as? Bool {
            prefs.putBoolean(defaultName, v)
        } else if let v = value as? Double { // there is no SharedPreferences.putDouble, so store doubles as strings
            prefs.putString(defaultName, v.toString())
        } else if let v = value as? Number {
            prefs.putString(defaultName, v.toString())
        } else if let v = value as? String {
            prefs.putString(defaultName, v)
        } else if let v = value as? URL {
            prefs.putString(defaultName, v.absoluteString)
        } else if let v = value as? Data {
            prefs.putString(defaultName, v.base64EncodedString())
        } else if let v = value as? Date {
            prefs.putString(defaultName, v.ISO8601Format())
        } else {
            // we ignore
            return
        }
    }

    public func removeObject(forKey defaultName: String) {
        let prefs = platformValue.edit()
        prefs.remove(defaultName)
        prefs.apply()
    }

    /// Returns the value from the current defaults.
    /// Called `object_` since `object` is an unescapable keyword in Kotin.
    public func object_(forKey defaultName: String) -> Any? {
        platformValue.getAll()[defaultName] ?? registrationDictionary[defaultName] ?? nil
    }

    public func string(forKey defaultName: String) -> String? {
        guard let value = object(forKey: defaultName) else {
            return nil
        }
        if let number = value as? Number {
            return number.toString()
        } else if let bool = value as? Bool {
            return bool ? "YES" : "NO"
        } else if let string = value as? String {
            return string
        } else {
            return nil
        }
    }

    public func double(forKey defaultName: String) -> Double? {
        guard let value = object(forKey: defaultName) else {
            return nil
        }
        if let number = value as? Number {
            return number.toDouble()
        } else if let bool = value as? Bool {
            return bool ? 1.0 : 0.0
        } else if let string = value as? String {
            return string.toDouble()
        } else {
            return nil
        }
    }

    public func integer(forKey defaultName: String) -> Int? {
        guard let value = object(forKey: defaultName) else {
            return nil
        }
        if let number = value as? Number {
            return number.toInt()
        } else if let bool = value as? Bool {
            return bool ? 1 : 0
        } else if let string = value as? String {
            return string.toInt()
        } else {
            return nil
        }
    }

    public func bool(forKey defaultName: String) -> Bool? {
        guard let value = object(forKey: defaultName) else {
            return nil
        }
        if let number = value as? Number {
            return number.toDouble() == 0.0 ? false : true
        } else if let bool = value as? Bool {
            return bool
        } else if let string = value as? String {
            // match the default string->bool conversion for UserDefaults
            return ["true", "yes", "1"].contains(string.lowercased())
        } else {
            return nil
        }
    }

    public func url(forKey defaultName: String) -> URL? {
        guard let value = object(forKey: defaultName) else {
            return nil
        }
        if let url = value as? URL {
            return url
        } else if let string = value as? String {
            return URL(string: string)
        } else {
            return nil
        }
    }

    public func data(forKey defaultName: String) -> Data? {
        guard let value = object(forKey: defaultName) else {
            return nil
        }
        if let url = value as? Data {
            return url
        } else if let string = value as? String {
            return Data(base64Encoded: string)
        } else {
            return nil
        }
    }
}

extension UserDefaults {
    public func kotlin(nocopy: Bool = false) -> android.content.SharedPreferences {
        return platformValue
    }
}

extension android.content.SharedPreferences {
    public func swift(nocopy: Bool = false) -> UserDefaults {
        return UserDefaults(platformValue: self)
    }
}

#endif
