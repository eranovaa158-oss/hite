import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

private func extraString(_ strings: PresentationStrings, ru: String, en: String) -> String {
    return strings.baseLanguageCode.lowercased().hasPrefix("ru") ? ru : en
}

private enum ExtraContextMenusSettingsSection: Int32 {
    case chatList
    case privateAndGroups
    case channels
    case settings
}

private extension ExtraContextMenuOption {
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .chatListFolder:
            return extraString(strings, ru: "Добавить или убрать в/из папки", en: "Add or Remove from Folder")
        case .chatListMark:
            return extraString(strings, ru: "Пометить", en: "Mark")
        case .chatListArchive:
            return extraString(strings, ru: "Архивировать", en: "Archive")
        case .chatListPin:
            return extraString(strings, ru: "Закрепить", en: "Pin")
        case .chatListMute:
            return extraString(strings, ru: "Выкл. или вкл. уведомления", en: "Mute or Unmute")
        case .chatListDelete:
            return extraString(strings, ru: "Удалить", en: "Delete")
            
        case .privateReply:
            return extraString(strings, ru: "Ответить", en: "Reply")
        case .privateCopy:
            return extraString(strings, ru: "Скопировать", en: "Copy")
        case .privateEdit:
            return extraString(strings, ru: "Редактировать", en: "Edit")
        case .privateForward:
            return extraString(strings, ru: "Переслать", en: "Forward")
        case .privateHideName:
            return extraString(strings, ru: "Спрятать имя", en: "Hide Name")
        case .privateDelete:
            return extraString(strings, ru: "Удалить", en: "Delete")
        case .privateAddToFavorites:
            return extraString(strings, ru: "Добавить в избранное", en: "Add to Favorites")
        case .privatePin:
            return extraString(strings, ru: "Закрепить", en: "Pin")
        case .privateRemove:
            return extraString(strings, ru: "Удалить", en: "Remove")
        case .privateSelect:
            return extraString(strings, ru: "Выбрать", en: "Select")
            
        case .channelReply:
            return extraString(strings, ru: "Ответить", en: "Reply")
        case .channelCopy:
            return extraString(strings, ru: "Скопировать", en: "Copy")
        case .channelCopyLink:
            return extraString(strings, ru: "Скопировать ссылку", en: "Copy Link")
        case .channelEdit:
            return extraString(strings, ru: "Редактировать", en: "Edit")
        case .channelForward:
            return extraString(strings, ru: "Переслать", en: "Forward")
        case .channelHideName:
            return extraString(strings, ru: "Спрятать имя", en: "Hide Name")
        case .channelReport:
            return extraString(strings, ru: "Пожаловаться", en: "Report")
        case .channelDelete:
            return extraString(strings, ru: "Удалить", en: "Delete")
        case .channelSaveToFavorites:
            return extraString(strings, ru: "Сохранить в избранное", en: "Save to Favorites")
        case .channelPin:
            return extraString(strings, ru: "Закрепить", en: "Pin")
        case .channelRemove:
            return extraString(strings, ru: "Удалить", en: "Remove")
        case .channelSelect:
            return extraString(strings, ru: "Выбрать", en: "Select")
            
        case .settingsSavedMessages:
            return extraString(strings, ru: "Избранное", en: "Saved Messages")
        case .settingsRecentCalls:
            return extraString(strings, ru: "Недавние звонки", en: "Recent Calls")
        case .settingsDevices:
            return extraString(strings, ru: "Устройства", en: "Devices")
        case .settingsChatFolders:
            return extraString(strings, ru: "Папки с чатами", en: "Chat Folders")
        case .settingsPremium:
            return "Telegram Premium"
        case .settingsStars:
            return extraString(strings, ru: "Мои звезды", en: "My Stars")
        case .settingsBusiness:
            return extraString(strings, ru: "Telegram для бизнеса", en: "Telegram Business")
        case .settingsGifts:
            return "Telegram Gifts"
        case .settingsHelp:
            return extraString(strings, ru: "Помощь", en: "Help")
        case .settingsFAQ:
            return extraString(strings, ru: "Вопросы о Telegram", en: "Telegram FAQ")
        case .settingsFeatures:
            return extraString(strings, ru: "Возможности Telegram", en: "Telegram Features")
        }
    }
    
    var section: ExtraContextMenusSettingsSection {
        switch self {
        case .chatListFolder, .chatListMark, .chatListArchive, .chatListPin, .chatListMute, .chatListDelete:
            return .chatList
            
        case .privateReply, .privateCopy, .privateEdit, .privateForward, .privateHideName, .privateDelete, .privateAddToFavorites, .privatePin, .privateRemove, .privateSelect:
            return .privateAndGroups
            
        case .channelReply, .channelCopy, .channelCopyLink, .channelEdit, .channelForward, .channelHideName, .channelReport, .channelDelete, .channelSaveToFavorites, .channelPin, .channelRemove, .channelSelect:
            return .channels
            
        case .settingsSavedMessages, .settingsRecentCalls, .settingsDevices, .settingsChatFolders, .settingsPremium, .settingsStars, .settingsBusiness, .settingsGifts, .settingsHelp, .settingsFAQ, .settingsFeatures:
            return .settings
        }
    }
    
}

private typealias ExtraContextMenusSettingsState = ExtraContextMenuSettings

private extension ExtraContextMenuSettings {
    func value(_ option: ExtraContextMenuOption) -> Bool {
        return self.isEnabled(option)
    }
}

private final class ExtraContextMenusSettingsArguments {
    let updateOption: (ExtraContextMenuOption, Bool) -> Void
    
    init(updateOption: @escaping (ExtraContextMenuOption, Bool) -> Void) {
        self.updateOption = updateOption
    }
}

private enum ExtraContextMenusSettingsEntry: ItemListNodeEntry {
    case header(ExtraContextMenusSettingsSection, String)
    case option(ExtraContextMenuOption, Bool)
    
    var section: ItemListSectionId {
        switch self {
        case let .header(section, _):
            return section.rawValue
        case let .option(option, _):
            return option.section.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .header(section, _):
            return section.rawValue * 1000
        case let .option(option, _):
            let index = ExtraContextMenuOption.allCases.firstIndex(of: option) ?? 0
            return option.section.rawValue * 1000 + Int32(index + 1)
        }
    }
    
    static func ==(lhs: ExtraContextMenusSettingsEntry, rhs: ExtraContextMenusSettingsEntry) -> Bool {
        switch lhs {
        case let .header(lhsSection, lhsText):
            if case let .header(rhsSection, rhsText) = rhs {
                return lhsSection == rhsSection && lhsText == rhsText
            }
            return false
            
        case let .option(lhsOption, lhsValue):
            if case let .option(rhsOption, rhsValue) = rhs {
                return lhsOption == rhsOption && lhsValue == rhsValue
            }
            return false
        }
    }
    
    static func <(lhs: ExtraContextMenusSettingsEntry, rhs: ExtraContextMenusSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraContextMenusSettingsArguments
        
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
            
        case let .option(option, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title(strings: presentationData.strings),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateOption(option, value)
                }
            )
        }
    }
}

private func extraContextMenusSettingsEntries(strings: PresentationStrings, state: ExtraContextMenusSettingsState) -> [ExtraContextMenusSettingsEntry] {
    var entries: [ExtraContextMenusSettingsEntry] = []
    
    entries.append(.header(.chatList, extraString(strings, ru: "Список чатов", en: "Chat List")))
    entries.append(.option(.chatListFolder, state.value(.chatListFolder)))
    entries.append(.option(.chatListMark, state.value(.chatListMark)))
    entries.append(.option(.chatListArchive, state.value(.chatListArchive)))
    entries.append(.option(.chatListPin, state.value(.chatListPin)))
    entries.append(.option(.chatListMute, state.value(.chatListMute)))
    entries.append(.option(.chatListDelete, state.value(.chatListDelete)))
    
    entries.append(.header(.privateAndGroups, extraString(strings, ru: "Внутри чатов - личные сообщения или группы", en: "Inside Chats - Private Messages or Groups")))
    entries.append(.option(.privateReply, state.value(.privateReply)))
    entries.append(.option(.privateCopy, state.value(.privateCopy)))
    entries.append(.option(.privateEdit, state.value(.privateEdit)))
    entries.append(.option(.privateForward, state.value(.privateForward)))
    entries.append(.option(.privateHideName, state.value(.privateHideName)))
    entries.append(.option(.privateDelete, state.value(.privateDelete)))
    entries.append(.option(.privateAddToFavorites, state.value(.privateAddToFavorites)))
    entries.append(.option(.privatePin, state.value(.privatePin)))
    entries.append(.option(.privateRemove, state.value(.privateRemove)))
    entries.append(.option(.privateSelect, state.value(.privateSelect)))
    
    entries.append(.header(.channels, extraString(strings, ru: "Внутри чатов - каналы", en: "Inside Chats - Channels")))
    entries.append(.option(.channelReply, state.value(.channelReply)))
    entries.append(.option(.channelCopy, state.value(.channelCopy)))
    entries.append(.option(.channelCopyLink, state.value(.channelCopyLink)))
    entries.append(.option(.channelEdit, state.value(.channelEdit)))
    entries.append(.option(.channelForward, state.value(.channelForward)))
    entries.append(.option(.channelHideName, state.value(.channelHideName)))
    entries.append(.option(.channelReport, state.value(.channelReport)))
    entries.append(.option(.channelDelete, state.value(.channelDelete)))
    entries.append(.option(.channelSaveToFavorites, state.value(.channelSaveToFavorites)))
    entries.append(.option(.channelPin, state.value(.channelPin)))
    entries.append(.option(.channelRemove, state.value(.channelRemove)))
    entries.append(.option(.channelSelect, state.value(.channelSelect)))
    
    entries.append(.header(.settings, extraString(strings, ru: "Настройки", en: "Settings")))
    entries.append(.option(.settingsSavedMessages, state.value(.settingsSavedMessages)))
    entries.append(.option(.settingsRecentCalls, state.value(.settingsRecentCalls)))
    entries.append(.option(.settingsDevices, state.value(.settingsDevices)))
    entries.append(.option(.settingsChatFolders, state.value(.settingsChatFolders)))
    entries.append(.option(.settingsPremium, state.value(.settingsPremium)))
    entries.append(.option(.settingsStars, state.value(.settingsStars)))
    entries.append(.option(.settingsBusiness, state.value(.settingsBusiness)))
    entries.append(.option(.settingsGifts, state.value(.settingsGifts)))
    entries.append(.option(.settingsHelp, state.value(.settingsHelp)))
    entries.append(.option(.settingsFAQ, state.value(.settingsFAQ)))
    entries.append(.option(.settingsFeatures, state.value(.settingsFeatures)))
    
    return entries
}

public func extraContextMenusSettingsController(context: AccountContext) -> ViewController {
    var currentState = ExtraContextMenusSettingsState()
    let statePromise = ValuePromise<ExtraContextMenusSettingsState>(currentState, ignoreRepeated: true)
    
    let arguments = ExtraContextMenusSettingsArguments(
        updateOption: { option, value in
            currentState.setValue(value, for: option)
            statePromise.set(currentState)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, ExtraContextMenusSettingsArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, ExtraContextMenusSettingsArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Контекстные меню", en: "Context Menus")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraContextMenusSettingsEntries(strings: presentationData.strings, state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}
