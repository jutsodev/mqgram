// MARK: MQGram - Passcode Manager
import Foundation
import CryptoKit

public final class MQGramPasscodeManager {
    public static let shared = MQGramPasscodeManager()

    public enum PasscodeType: Int {
        case fourDigit = 4
        case sixDigit = 6
        case custom = 0
    }

    private let defaults: UserDefaults

    private static let passcodeHashKey = "MQGram.passcodeHash"
    private static let passcodeTypeKey = "MQGram.passcodeType"
    private static let lockedPeerIdsKey = "MQGram.lockedPeerIds"

    public private(set) var isUnlocked: Bool = false

    private init() {
        self.defaults = UserDefaults.standard
        self.defaults.set(false, forKey: "MQGram.passcodeUnlocked")
    }

    public var isPasscodeSet: Bool {
        return defaults.string(forKey: MQGramPasscodeManager.passcodeHashKey) != nil
    }

    public var passcodeType: PasscodeType {
        let raw = defaults.integer(forKey: MQGramPasscodeManager.passcodeTypeKey)
        return PasscodeType(rawValue: raw) ?? .fourDigit
    }

    public func setPasscode(_ passcode: String, type: PasscodeType) {
        let hash = sha256(passcode)
        defaults.set(hash, forKey: MQGramPasscodeManager.passcodeHashKey)
        defaults.set(type.rawValue, forKey: MQGramPasscodeManager.passcodeTypeKey)
    }

    public func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedHash = defaults.string(forKey: MQGramPasscodeManager.passcodeHashKey) else {
            return false
        }
        return sha256(passcode) == storedHash
    }

    public func removePasscode() {
        defaults.removeObject(forKey: MQGramPasscodeManager.passcodeHashKey)
        defaults.removeObject(forKey: MQGramPasscodeManager.passcodeTypeKey)
        defaults.removeObject(forKey: MQGramPasscodeManager.lockedPeerIdsKey)
        isUnlocked = false
        defaults.set(false, forKey: "MQGram.passcodeUnlocked")
    }

    public func unlock() {
        isUnlocked = true
        defaults.set(true, forKey: "MQGram.passcodeUnlocked")
    }

    public func lock() {
        isUnlocked = false
        defaults.set(false, forKey: "MQGram.passcodeUnlocked")
    }

    public var lockedPeerIds: [Int64] {
        get {
            return defaults.array(forKey: MQGramPasscodeManager.lockedPeerIdsKey) as? [Int64] ?? []
        }
        set {
            defaults.set(newValue, forKey: MQGramPasscodeManager.lockedPeerIdsKey)
        }
    }

    public func addLockedPeer(_ peerId: Int64) {
        var ids = lockedPeerIds
        if !ids.contains(peerId) {
            ids.append(peerId)
            lockedPeerIds = ids
        }
    }

    public func removeLockedPeer(_ peerId: Int64) {
        var ids = lockedPeerIds
        ids.removeAll { $0 == peerId }
        lockedPeerIds = ids
    }

    public func isPeerLocked(_ peerId: Int64) -> Bool {
        return lockedPeerIds.contains(peerId)
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
