import Cocoa

/// Manages saved signatures for reuse.
class SignatureStore {
    
    private let storageKey = "SavedSignatures"
    
    func save(signature: NSImage, name: String = "Default") {
        guard let tiffData = signature.tiffRepresentation else { return }
        
        var signatures = loadAll()
        signatures[name] = tiffData
        
        UserDefaults.standard.set(signatures, forKey: storageKey)
    }
    
    func load(name: String = "Default") -> NSImage? {
        let signatures = loadAll()
        guard let data = signatures[name] else { return nil }
        return NSImage(data: data)
    }
    
    func loadAll() -> [String: Data] {
        return UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Data] ?? [:]
    }
    
    func delete(name: String) {
        var signatures = loadAll()
        signatures.removeValue(forKey: name)
        UserDefaults.standard.set(signatures, forKey: storageKey)
    }
    
    func allNames() -> [String] {
        return Array(loadAll().keys).sorted()
    }
}
