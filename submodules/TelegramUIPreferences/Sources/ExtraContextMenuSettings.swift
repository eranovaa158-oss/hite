import Foundation

public enum ExtraContextMenuOption: String, CaseIterable {
    case chatListFolder
    case chatListMark
    case chatListArchive
    case chatListPin
    case chatListMute
    case chatListDelete

    case privateReply
    case privateCopy
    case privateEdit
    case privateForward
    case privateHideName
    case privateDelete
    case privateAddToFavorites
    case privatePin
    case privateRemove
    case privateSelect

    case channelReply
    case channelCopy
    case channelCopyLink
    case channelEdit
    case channelForward
    case channelHideName
    case channelReport
    case channelDelete
    case channelSaveToFavorites
    case channelPin
    case channelRemove
    case channelSelect

    case settingsSavedMessages
    case settingsRecentCalls
    case settingsDevices
    case settingsChatFolders
    case settingsPremium
    case settingsStars
    case settingsBusiness
    case settingsGifts
    case settingsHelp
    case settingsFAQ
    case settingsFeatures

    public var storageKey: String {
        return "extra.contextMenus.\(self.rawValue)"
    }
}

public struct ExtraContextMenuSettings: Equatable {
    public var values: [ExtraContextMenuOption: Bool]

    public init() {
        var values: [ExtraContextMenuOption: Bool] = [:]
        for option in ExtraContextMenuOption.allCases {
            if UserDefaults.standard.object(forKey: option.storageKey) == nil {
                values[option] = true
            } else {
                values[option] = UserDefaults.standard.bool(forKey: option.storageKey)
            }
        }
        self.values = values
    }

    public static var current: ExtraContextMenuSettings {
        return ExtraContextMenuSettings()
    }

    public func isEnabled(_ option: ExtraContextMenuOption) -> Bool {
        return self.values[option] ?? true
    }

    public mutating func setValue(_ value: Bool, for option: ExtraContextMenuOption) {
        self.values[option] = value
        UserDefaults.standard.set(value, forKey: option.storageKey)
    }
}
