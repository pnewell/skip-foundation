// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP

public class Bundle {
    public static let main = Bundle(location: .main)

    private let location: SkipLocalizedStringResource.BundleDescription

    public init(location: SkipLocalizedStringResource.BundleDescription) {
        self.location = location
    }

    public convenience init?(path: String) {
        self.init(location: .atURL(URL(fileURLWithPath: path)))
    }

    public convenience init?(url: URL) {
        self.init(location: .atURL(url))
    }

    public init() {
        self.init(location: .forClass(Bundle.self))
    }

    public convenience init(for forClass: AnyClass) {
        self.init(location: .forClass(forClass))
    }

    public var description: String {
        return location.description
    }

    public var bundleURL: URL {
        let loc: SkipLocalizedStringResource.BundleDescription = location
        switch loc {
        case .main:
            fatalError("Skip does not support .main bundle")
        case .atURL(let url):
            return url
        case .forClass(let cls):
            return relativeBundleURL("resources.lst")!
                .deletingLastPathComponent()
        }
    }

    public var resourceURL: URL? {
        return bundleURL // FIXME: this is probably not correct
    }

    static var module: Bundle {
        return Bundle(for: Bundle.self)
    }

    /// Creates a relative path to the given bundle URL
    private func relativeBundleURL(path: String) -> URL? {
        let loc: SkipLocalizedStringResource.BundleDescription = location
        switch loc {
        case .main:
            fatalError("Skip does not support .main bundle")
        case .atURL(let url):
            return url.appendingPathComponent(path)
        case .forClass(let cls):
            do {
                let rpath = "Resources/" + path
                let resURL = cls.java.getResource(rpath)
                return URL(platformValue: resURL)
            } catch {
                // getResource throws when it cannot find the resource, but it doesn't handle directories
                // such as .lproj folders; so manually scan the resources.lst elements, and if any
                // appear to be a directory, then just return that relative URL without validating its existance
                if self.resourcesIndex.contains(where: { $0.hasPrefix(path + "/") }) {
                    return resourcesFolderURL?.appendingPathComponent(path, isDirectory: true)
                }
                return nil
            }
        }
    }

    public var bundlePath: String {
        bundleURL.path
    }

    /// The URL for the `resources.lst` resources index file that is created by the transpiler when converting resources files.
    private var resourcesIndexURL: URL? {
        url(forResource: "resources.lst")
    }

    /// THe path to the base folder of the `Resources/` directory.
    ///
    /// In Robolectric, this will be a simple file system directory URL.
    /// On Android it will be something like `jar:file:/data/app/~~GrNJyKuGMG-gs4i97rlqHg==/skip.ui.test-5w0MhfIK6rNxUpG8yMuXgg==/base.apk!/skip/ui/Resources/`
    private var resourcesFolderURL: URL? {
        resourcesIndexURL?.deletingLastPathComponent()
    }

    /// Loads the resources index stored in the `resources.lst` file at the root of the resources folder.
    private lazy var resourcesIndex: [String] = {
        guard let resourceListURL = try self.resourcesIndexURL else {
            return []
        }
        let resourceList = try Data(contentsOf: resourceListURL)
        guard let resourceListString = String(data: resourceList, encoding: String.Encoding.utf8) else {
            return []
        }
        let resourcePaths = resourceListString.components(separatedBy: "\n")
        return resourcePaths
    }()

    /// We default to en as the development localization
    public var developmentLocalization: String { "en" }

    /// Identify the Bundle's localizations by the presence of a `LOCNAME.lproj/` folder in index of the root of the resources folder
    public lazy var localizations: [String] = {
        resourcesIndex
            .compactMap({ $0.components(separatedBy: "/").first })
            .filter({ $0.hasSuffix(".lproj") })
            .map({ $0.dropLast(".lproj".count) })
    }()

    public func path(forResource: String? = nil, ofType: String? = nil, inDirectory: String? = nil, forLocalization: String? = nil) -> String? {
        url(forResource: forResource, withExtension: ofType, subdirectory: inDirectory, localization: forLocalization)?.path
    }

    public func url(forResource: String? = nil, withExtension: String? = nil, subdirectory: String? = nil, localization: String? = nil) -> URL? {
        // similar behavior to: https://github.com/apple/swift-corelibs-foundation/blob/69ab3975ea636d1322ad19bbcea38ce78b65b26a/CoreFoundation/PlugIn.subproj/CFBundle_Resources.c#L1114
        var res = forResource ?? ""
        if let withExtension = withExtension, !withExtension.isEmpty {
            // TODO: If `forResource` is nil, we are expected to find the first file in the bundle whose extension matches
            res += "." + withExtension
        } else {
            if res.isEmpty {
                return nil
            }
        }
        if let localization = localization {
            //let lprojExtension = "lproj" // _CFBundleLprojExtension
            var lprojExtensionWithDot = ".lproj" // _CFBundleLprojExtensionWithDot
            res = localization + lprojExtensionWithDot + "/" + res
        }
        if let subdirectory = subdirectory {
            res = subdirectory + "/" + res
        }

        return relativeBundleURL(path: res)
    }

    public func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        synchronized(self) {
            let table = tableName ?? "Localizable"
            if let localizedTable = localizedTables[table] {
                return localizedTable?[key] ?? value ?? key
            } else {
                let resURL = url(forResource: table, withExtension: "strings")
                let locTable = resURL == nil ? nil : try? PropertyListSerialization.propertyList(from: Data(contentsOf: resURL!), format: nil)
                localizedTables[key] = locTable
                return locTable?[key] ?? value ?? key
            }
        }
    }

    /// The localized strings tables for this bundle
    private var localizedTables: [String: [String: String]?] = [:]

}

public func NSLocalizedString(_ key: String, tableName: String? = nil, bundle: Bundle? = nil, value: String? = nil, comment: String) -> String {
    return (bundle ?? Bundle.main).localizedString(forKey: key, value: value, table: tableName)
}

#endif
