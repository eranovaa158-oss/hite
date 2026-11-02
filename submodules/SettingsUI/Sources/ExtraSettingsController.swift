import Foundation
import UIKit
import Darwin
import AsyncDisplayKit
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

private func extraString(_ presentationData: ItemListPresentationData, ru: String, en: String) -> String {
    return extraString(presentationData.strings, ru: ru, en: en)
}

private final class ExtraSettingsArguments {
    let openCategory: (ExtraSettingsCategory) -> Void
    
    init(openCategory: @escaping (ExtraSettingsCategory) -> Void) {
        self.openCategory = openCategory
    }
}

private enum ExtraSettingsSection: Int32 {
    case main
}

private func extraSettingsIcon(backgroundColors: [UIColor], drawGlyph: @escaping (CGContext, CGSize) -> Void) -> UIImage? {
    return generateImage(CGSize(width: 30.0, height: 30.0), contextGenerator: { size, context in
        let bounds = CGRect(origin: .zero, size: size)
        context.clear(bounds)

        context.saveGState()
        context.addPath(UIBezierPath(roundedRect: bounds, cornerRadius: 8.0).cgPath)
        context.clip()

        var locations: [CGFloat] = [0.0, 1.0]
        let colors = backgroundColors.map(\.cgColor)
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: &locations) {
            context.drawLinearGradient(gradient, start: CGPoint(x: size.width, y: size.height), end: CGPoint(x: 0.0, y: 0.0), options: [])
        } else if let color = backgroundColors.first {
            context.setFillColor(color.cgColor)
            context.fill(bounds)
        }

        context.restoreGState()
        drawGlyph(context, size)
    })
}

private enum ExtraSettingsIcons {
    static let tabs = extraSettingsIcon(backgroundColors: [UIColor(rgb: 0x32ADE6), UIColor(rgb: 0x5E5CE6)], drawGlyph: { context, _ in
        let fillRoundedRect: (CGRect, CGFloat) -> Void = { rect, radius in
            context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
            context.fillPath()
        }

        let white = UIColor.white.cgColor
        context.setStrokeColor(white)
        context.setLineWidth(1.7)
        context.setLineJoin(.round)

        let screenRect = CGRect(x: 7.0, y: 6.5, width: 16.0, height: 17.0)
        context.addPath(UIBezierPath(roundedRect: screenRect, cornerRadius: 4.0).cgPath)
        context.strokePath()

        context.setFillColor(white)
        fillRoundedRect(CGRect(x: 9.0, y: 19.0, width: 3.2, height: 3.2), 1.6)
        fillRoundedRect(CGRect(x: 13.4, y: 18.5, width: 3.2, height: 4.2), 1.6)
        fillRoundedRect(CGRect(x: 17.8, y: 19.0, width: 3.2, height: 3.2), 1.6)

        context.setAlpha(0.78)
        fillRoundedRect(CGRect(x: 10.0, y: 10.0, width: 10.0, height: 2.4), 1.2)
        fillRoundedRect(CGRect(x: 10.0, y: 14.0, width: 7.0, height: 2.4), 1.2)
        context.setAlpha(1.0)
    })

    static let contextMenu = extraSettingsIcon(backgroundColors: [UIColor(rgb: 0xAF52DE), UIColor(rgb: 0xFF2D55)], drawGlyph: { context, _ in
        let fillRoundedRect: (CGRect, CGFloat) -> Void = { rect, radius in
            context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
            context.fillPath()
        }

        context.setFillColor(UIColor.white.cgColor)

        let rows: [(CGFloat, CGFloat)] = [
            (7.0, 16.0),
            (13.0, 18.0),
            (19.0, 14.0)
        ]
        for (y, width) in rows {
            context.fillEllipse(in: CGRect(x: 6.5, y: y + 0.4, width: 3.2, height: 3.2))
            fillRoundedRect(CGRect(x: 11.0, y: y, width: width, height: 4.0), 2.0)
        }
    })
}

private enum ExtraSettingsCategory: Int32, CaseIterable {
    case tabs
    case chatSettings
    case chatFolders
    case stories
    case media
    case contextMenu
    case other
    
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .tabs:
            return extraString(strings, ru: "Вкладки", en: "Tabs")
        case .chatSettings:
            return extraString(strings, ru: "Настройки чатов", en: "Chat Settings")
        case .chatFolders:
            return extraString(strings, ru: "Папки с чатами", en: "Chat Folders")
        case .stories:
            return extraString(strings, ru: "Истории", en: "Stories")
        case .media:
            return extraString(strings, ru: "Медиа", en: "Media")
        case .contextMenu:
            return extraString(strings, ru: "Контекстные меню", en: "Context Menus")
        case .other:
            return extraString(strings, ru: "Другие", en: "Other")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .tabs:
            return ExtraSettingsIcons.tabs
        case .chatSettings:
            return PresentationResourcesSettings.chatAppearance
        case .chatFolders:
            return PresentationResourcesSettings.chatFolders
        case .stories:
            return PresentationResourcesSettings.stories
        case .media:
            return PresentationResourcesSettings.photosBlue
        case .other:
            return PresentationResourcesSettings.settings
        case .contextMenu:
            return ExtraSettingsIcons.contextMenu
        }
    }
}

private enum ExtraSettingsEntry: ItemListNodeEntry {
    case category(ExtraSettingsCategory)
    
    var section: ItemListSectionId {
        return ExtraSettingsSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .category(category):
            return category.rawValue
        }
    }
    
    static func ==(lhs: ExtraSettingsEntry, rhs: ExtraSettingsEntry) -> Bool {
        switch lhs {
        case let .category(lhsCategory):
            if case let .category(rhsCategory) = rhs {
                return lhsCategory == rhsCategory
            }
            return false
        }
    }
    
    static func <(lhs: ExtraSettingsEntry, rhs: ExtraSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraSettingsArguments
        switch self {
        case let .category(category):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: category.icon,
                title: category.title(strings: presentationData.strings),
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.openCategory(category)
                }
            )
        }
    }
}

private func extraSettingsEntries() -> [ExtraSettingsEntry] {
    return ExtraSettingsCategory.allCases.map(ExtraSettingsEntry.category)
}

public func extraSettingsController(context: AccountContext) -> ViewController {
    var pushController: ((ViewController) -> Void)?
    
    let arguments = ExtraSettingsArguments(
        openCategory: { category in
            print("Extra category tapped:", category)
            switch category {
            case .tabs:
                pushController?(extraTabsSettingsController(context: context))
            case .chatSettings:
                pushController?(extraChatSettingsController(context: context))
            case .chatFolders:
                pushController?(extraChatFoldersSettingsController(context: context))
            case .stories:
                pushController?(extraStorySettingsController(context: context))
            case .media:
                break
            case .contextMenu:
                pushController?(extraContextMenusSettingsController(context: context))
            case .other:
                pushController?(extraOtherSettingsController(context: context))
            }
        }
    )
    
    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Extra"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraSettingsEntries(),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    pushController = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

private final class ExtraStorySettingsArguments {
    let update: ((ExtraStorySettings) -> ExtraStorySettings) -> Void

    init(update: @escaping ((ExtraStorySettings) -> ExtraStorySettings) -> Void) {
        self.update = update
    }
}

private enum ExtraStorySettingsSection: Int32 {
    case options
}

private enum ExtraStorySettingsEntry: ItemListNodeEntry {
    case disableStories(ExtraStorySettings)
    case hideStories(ExtraStorySettings)
    case disableStoryRecording(ExtraStorySettings)
    case disableStoryRecordingSwipe(ExtraStorySettings)
    case askBeforeViewingStories(ExtraStorySettings)

    var section: ItemListSectionId {
        return ExtraStorySettingsSection.options.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .disableStories:
            return 0
        case .hideStories:
            return 1
        case .disableStoryRecording:
            return 2
        case .disableStoryRecordingSwipe:
            return 3
        case .askBeforeViewingStories:
            return 4
        }
    }

    static func ==(lhs: ExtraStorySettingsEntry, rhs: ExtraStorySettingsEntry) -> Bool {
        switch lhs {
        case let .disableStories(lhsSettings):
            if case let .disableStories(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideStories(lhsSettings):
            if case let .hideStories(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .disableStoryRecording(lhsSettings):
            if case let .disableStoryRecording(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .disableStoryRecordingSwipe(lhsSettings):
            if case let .disableStoryRecordingSwipe(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .askBeforeViewingStories(lhsSettings):
            if case let .askBeforeViewingStories(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        }
    }

    static func <(lhs: ExtraStorySettingsEntry, rhs: ExtraStorySettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraStorySettingsArguments

        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }

        switch self {
        case let .disableStories(settings):
            return switchItem(title: extraString(presentationData, ru: "Отключить истории полностью", en: "Disable Stories Completely"), text: extraString(presentationData, ru: "Скрывает истории и отключает просмотр, создание и запись.", en: "Hides stories and disables viewing, creating, and recording them."), value: settings.disableStories, enabled: true, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableStories = value
                    if value {
                        current.hideStories = true
                        current.disableStoryRecording = true
                        current.disableStoryRecordingSwipe = true
                    }
                    return current
                }
            })
        case let .hideStories(settings):
            return switchItem(title: extraString(presentationData, ru: "Скрыть истории", en: "Hide Stories"), text: extraString(presentationData, ru: "Скрывает истории сверху в списке чатов, но не отключает запись.", en: "Hides stories at the top of the chat list without disabling recording."), value: settings.hideStories, enabled: !settings.disableStories, update: { value in
                arguments.update { current in
                    var current = current
                    current.hideStories = value
                    return current
                }
            })
        case let .disableStoryRecording(settings):
            return switchItem(title: extraString(presentationData, ru: "Отключить запись истории", en: "Disable Story Recording"), text: extraString(presentationData, ru: "Отключает только создание историй, просмотр остается доступен.", en: "Disables creating stories only. Viewing remains available."), value: settings.disableStoryRecording, enabled: !settings.disableStories, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableStoryRecording = value
                    return current
                }
            })
        case let .disableStoryRecordingSwipe(settings):
            return switchItem(title: extraString(presentationData, ru: "Отключить свайп для записи", en: "Disable Recording Swipe"), text: extraString(presentationData, ru: "Отключает свайп вправо в списке чатов для записи истории.", en: "Disables swiping right in the chat list to record a story."), value: settings.disableStoryRecordingSwipe, enabled: !settings.disableStories && !settings.disableStoryRecording, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableStoryRecordingSwipe = value
                    return current
                }
            })
        case let .askBeforeViewingStories(settings):
            return switchItem(title: extraString(presentationData, ru: "Спросить перед просмотром", en: "Ask Before Viewing"), text: extraString(presentationData, ru: "Перед открытием истории показывает предупреждение, что владелец увидит просмотр.", en: "Shows a warning before opening a story that the owner will see your view."), value: settings.askBeforeViewingStories, enabled: !settings.disableStories, update: { value in
                arguments.update { current in
                    var current = current
                    current.askBeforeViewingStories = value
                    return current
                }
            })
        }
    }
}

private func extraStorySettingsEntries(settings: ExtraStorySettings) -> [ExtraStorySettingsEntry] {
    return [
        .disableStories(settings),
        .hideStories(settings),
        .disableStoryRecording(settings),
        .disableStoryRecordingSwipe(settings),
        .askBeforeViewingStories(settings)
    ]
}

private func extraStorySettingsController(context: AccountContext) -> ViewController {
    let initialSettings = ExtraStorySettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)

    let arguments = ExtraStorySettingsArguments(update: { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        statePromise.set(updated)
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Истории", en: "Stories")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraStorySettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private final class ExtraTabsSettingsArguments {
    let update: (((ExtraTabSettings) -> ExtraTabSettings), Bool) -> Void
    let restart: () -> Void
    
    init(update: @escaping (((ExtraTabSettings) -> ExtraTabSettings), Bool) -> Void, restart: @escaping () -> Void) {
        self.update = update
        self.restart = restart
    }
}

private enum ExtraTabsSettingsSection: Int32 {
    case options
    case restart
}

private enum ExtraTabsSettingsEntry: ItemListNodeEntry {
    case compactPanel(ExtraTabSettings)
    case hideContacts(ExtraTabSettings)
    case hideCalls(ExtraTabSettings)
    case hideTitles(ExtraTabSettings)
    case hideSearch(ExtraTabSettings)
    case widePanel(ExtraTabSettings)
    
    var section: ItemListSectionId {
        return ExtraTabsSettingsSection.options.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case .compactPanel:
            return 0
        case .hideContacts:
            return 1
        case .hideCalls:
            return 2
        case .hideTitles:
            return 3
        case .hideSearch:
            return 4
        case .widePanel:
            return 5
        }
    }
    
    static func ==(lhs: ExtraTabsSettingsEntry, rhs: ExtraTabsSettingsEntry) -> Bool {
        switch lhs {
        case let .compactPanel(lhsSettings):
            if case let .compactPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideContacts(lhsSettings):
            if case let .hideContacts(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideCalls(lhsSettings):
            if case let .hideCalls(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideTitles(lhsSettings):
            if case let .hideTitles(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideSearch(lhsSettings):
            if case let .hideSearch(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .widePanel(lhsSettings):
            if case let .widePanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        }
    }
    
    static func <(lhs: ExtraTabsSettingsEntry, rhs: ExtraTabsSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraTabsSettingsArguments
        
        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }
        
        switch self {
        case let .compactPanel(settings):
            return switchItem(title: extraString(presentationData, ru: "Сократить панель вкладок", en: "Compact Tab Bar"), text: extraString(presentationData, ru: "Скрывает нижнюю панель и переносит вкладки в компактное меню.", en: "Hides the bottom bar and moves tabs into a compact menu."), value: settings.compactPanel, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.compactPanel = value
                    return current
                }, true)
            })
        case let .hideContacts(settings):
            return switchItem(title: extraString(presentationData, ru: "Вкладка контакты", en: "Contacts Tab"), text: extraString(presentationData, ru: "Показывает вкладку контактов в нижней панели.", en: "Shows the Contacts tab in the bottom bar."), value: !settings.hideContactsTab, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideContactsTab = !value
                    return current
                }, true)
            })
        case let .hideCalls(settings):
            return switchItem(title: extraString(presentationData, ru: "Вкладка звонки", en: "Calls Tab"), text: extraString(presentationData, ru: "Показывает вкладку звонков рядом с чатами.", en: "Shows the Calls tab next to Chats."), value: !settings.hideCallsTab, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideCallsTab = !value
                    return current
                }, true)
            })
        case let .hideTitles(settings):
            return switchItem(title: extraString(presentationData, ru: "Подписи вкладок", en: "Tab Labels"), text: extraString(presentationData, ru: "Показывает названия вкладок под иконками.", en: "Shows tab names below the icons."), value: !settings.hideTabTitles, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideTabTitles = !value
                    return current
                }, true)
            })
        case let .hideSearch(settings):
            return switchItem(title: extraString(presentationData, ru: "Кнопка поиска", en: "Search Button"), text: extraString(presentationData, ru: "Показывает отдельную кнопку поиска справа от вкладок.", en: "Shows a separate search button to the right of the tabs."), value: !settings.hideSearchButton, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideSearchButton = !value
                    return current
                }, true)
            })
        case let .widePanel(settings):
            return switchItem(title: extraString(presentationData, ru: "Широкая панель", en: "Wide Bar"), text: extraString(presentationData, ru: "Растягивает панель по доступной ширине с обычными отступами.", en: "Stretches the bar to the available width with regular insets."), value: settings.widePanel, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.widePanel = value
                    return current
                }, true)
            })
        }
    }
}

private final class ExtraRestartFooterItem: ItemListControllerFooterItem {
    let presentationData: ItemListPresentationData
    let action: () -> Void
    
    init(presentationData: ItemListPresentationData, action: @escaping () -> Void) {
        self.presentationData = presentationData
        self.action = action
    }
    
    func isEqual(to: ItemListControllerFooterItem) -> Bool {
        if let item = to as? ExtraRestartFooterItem {
            return self.presentationData.theme === item.presentationData.theme && self.presentationData.strings.baseLanguageCode == item.presentationData.strings.baseLanguageCode
        }
        return false
    }
    
    func node(current: ItemListControllerFooterItemNode?) -> ItemListControllerFooterItemNode {
        if let current = current as? ExtraRestartFooterItemNode {
            current.item = self
            return current
        } else {
            return ExtraRestartFooterItemNode(item: self)
        }
    }
}

private final class ExtraRestartFooterItemNode: ItemListControllerFooterItemNode {
    private let backgroundView = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let button = UIButton(type: .system)
    private var validLayout: ContainerViewLayout?
    
    var item: ExtraRestartFooterItem {
        didSet {
            self.updateItem()
            if let validLayout = self.validLayout {
                let _ = self.updateLayout(layout: validLayout, transition: .immediate)
            }
        }
    }

    init(item: ExtraRestartFooterItem) {
        self.item = item

        super.init()

        self.backgroundView.backgroundColor = UIColor(rgb: 0x5a5a5a)
        self.backgroundView.layer.cornerRadius = 26.0
        self.backgroundView.clipsToBounds = true
        self.view.addSubview(self.backgroundView)

        self.iconLabel.text = "i"
        self.iconLabel.textAlignment = .center
        self.iconLabel.font = Font.semibold(20.0)
        self.iconLabel.textColor = .white
        self.iconLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.16)
        self.iconLabel.layer.cornerRadius = 15.0
        self.iconLabel.clipsToBounds = true
        self.backgroundView.addSubview(self.iconLabel)

        self.titleLabel.numberOfLines = 2
        self.titleLabel.font = Font.medium(15.0)
        self.titleLabel.textColor = .white
        self.backgroundView.addSubview(self.titleLabel)

        self.button.titleLabel?.font = Font.medium(15.0)
        self.button.setTitleColor(UIColor(rgb: 0x35C8FF), for: [])
        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        self.backgroundView.addSubview(self.button)

        self.updateItem()
    }

    @objc private func buttonPressed() {
        self.item.action()
    }

    private func updateItem() {
        self.titleLabel.text = extraString(self.item.presentationData, ru: "Необходим\nперезапуск", en: "Restart\nRequired")
        self.button.setTitle(extraString(self.item.presentationData, ru: "Перезапустить Сейчас", en: "Restart Now"), for: [])
    }

    override func updateLayout(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) -> CGFloat {
        self.validLayout = layout

        let insets = layout.insets(options: [.input])
        let sideInset = max(12.0, layout.safeInsets.left + 12.0)
        let bottomInset = max(8.0, insets.bottom + 8.0)
        let panelHeight: CGFloat = 52.0
        let totalHeight = panelHeight + bottomInset + 8.0
        let panelFrame = CGRect(x: sideInset, y: layout.size.height - bottomInset - panelHeight, width: layout.size.width - sideInset * 2.0, height: panelHeight)
        let buttonWidth = min(190.0, max(142.0, panelFrame.width * 0.54))
        let buttonX = panelFrame.width - buttonWidth - 10.0
        let titleX: CGFloat = 60.0

        self.backgroundView.frame = panelFrame
        self.iconLabel.frame = CGRect(x: 16.0, y: 11.0, width: 30.0, height: 30.0)
        self.titleLabel.frame = CGRect(x: titleX, y: 7.0, width: max(78.0, buttonX - titleX - 8.0), height: 38.0)
        self.button.frame = CGRect(x: buttonX, y: 0.0, width: buttonWidth, height: panelHeight)

        return totalHeight
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.backgroundView.frame.contains(point)
    }
}

private func extraTabsSettingsEntries(settings: ExtraTabSettings, initialSettings: ExtraTabSettings) -> [ExtraTabsSettingsEntry] {
    return [
        .compactPanel(settings),
        .hideContacts(settings),
        .hideCalls(settings),
        .hideTitles(settings),
        .hideSearch(settings),
        .widePanel(settings)
    ]
}

private func extraTabsSettingsController(context: AccountContext) -> ViewController {
    let initialSettings = ExtraTabSettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)
    let restartWarningPromise = ValuePromise(false, ignoreRepeated: true)
    var restartWarningTimer: SwiftSignalKit.Timer?

    let showRestartWarning: () -> Void = {
        restartWarningTimer?.invalidate()
        restartWarningPromise.set(true)
        let timer = SwiftSignalKit.Timer(timeout: 4.0, repeat: false, completion: {
            restartWarningPromise.set(false)
        }, queue: Queue.mainQueue())
        restartWarningTimer = timer
        timer.start()
    }
    
    let updateSettings: (((ExtraTabSettings) -> ExtraTabSettings), Bool) -> Void = { f, notify in
        let updated = stateValue.modify { current in
            let previous = current
            let updated = f(current)
            updated.save(notify: notify)
            if previous.compactPanel != updated.compactPanel {
                showRestartWarning()
            }
            return updated
        }
        statePromise.set(updated)
    }
    
    let arguments = ExtraTabsSettingsArguments(
        update: updateSettings,
        restart: {
            exit(0)
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), restartWarningPromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings, showRestartWarning -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Вкладки", en: "Tabs")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraTabsSettingsEntries(settings: settings, initialSettings: initialSettings),
            style: .blocks,
            footerItem: showRestartWarning && settings.compactPanel != initialSettings.compactPanel ? ExtraRestartFooterItem(presentationData: ItemListPresentationData(presentationData), action: arguments.restart) : nil,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}

private final class ExtraChatSettingsArguments {
    let update: (((ExtraChatSettings) -> ExtraChatSettings), Bool) -> Void
    let openVideoMessageCamera: () -> Void
    let openPersonalChatDoubleTapAction: () -> Void
    let openChannelPostDoubleTapAction: () -> Void
    let restart: () -> Void

    init(
        update: @escaping (((ExtraChatSettings) -> ExtraChatSettings), Bool) -> Void,
        openVideoMessageCamera: @escaping () -> Void,
        openPersonalChatDoubleTapAction: @escaping () -> Void,
        openChannelPostDoubleTapAction: @escaping () -> Void,
        restart: @escaping () -> Void
    ) {
        self.update = update
        self.openVideoMessageCamera = openVideoMessageCamera
        self.openPersonalChatDoubleTapAction = openPersonalChatDoubleTapAction
        self.openChannelPostDoubleTapAction = openChannelPostDoubleTapAction
        self.restart = restart
    }
}

private extension ExtraChatSettings.VideoMessageCamera {
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .front:
            return extraString(strings, ru: "Фронтальная", en: "Front")
        case .back:
            return extraString(strings, ru: "Задняя", en: "Back")
        case .ask:
            return extraString(strings, ru: "Спрашивать", en: "Ask")
        }
    }
}

private extension ExtraChatSettings.PersonalChatDoubleTapAction {
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .savedMessages:
            return extraString(strings, ru: "Избранное", en: "Saved Messages")
        case .reaction:
            return extraString(strings, ru: "Реакция", en: "Reaction")
        case .edit:
            return extraString(strings, ru: "Редактировать сообщение", en: "Edit Message")
        case .forward:
            return extraString(strings, ru: "Переслать", en: "Forward")
        case .reply:
            return extraString(strings, ru: "Ответить", en: "Reply")
        case .pin:
            return extraString(strings, ru: "Закрепить / открепить", en: "Pin / Unpin")
        case .select:
            return extraString(strings, ru: "Выбрать", en: "Select")
        case .copy:
            return extraString(strings, ru: "Скопировать", en: "Copy")
        case .contextMenu:
            return extraString(strings, ru: "Открыть контекстное меню", en: "Open Context Menu")
        }
    }
}

private extension ExtraChatSettings.ChannelPostDoubleTapAction {
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .savedMessages:
            return extraString(strings, ru: "Добавить в Избранное", en: "Add to Saved Messages")
        case .reaction:
            return extraString(strings, ru: "Реакция", en: "Reaction")
        case .forward:
            return extraString(strings, ru: "Переслать", en: "Forward")
        case .reply:
            return extraString(strings, ru: "Ответить", en: "Reply")
        case .select:
            return extraString(strings, ru: "Выбрать", en: "Select")
        case .copy:
            return extraString(strings, ru: "Скопировать", en: "Copy")
        case .contextMenu:
            return extraString(strings, ru: "Открыть контекстное меню", en: "Open Context Menu")
        }
    }
}

private enum ExtraChatSettingsSection: Int32 {
    case chatList
    case general
    case stickerSize
    case stickerOptions
    case messages
    case channels
    case restart
}

private enum ExtraChatSettingsEntry: ItemListNodeEntry {
    case generalHeader
    case compactPinnedMessagesPanel(ExtraChatSettings)
    case stickerSizeHeader
    case stickerSize(ExtraChatSettings)
    case animateEmojiStickers(ExtraChatSettings)
    case messagesHeader
    case showSecondsInMessageTimestamp(ExtraChatSettings)
    case hideMessageTimestamp(ExtraChatSettings)
    case videoMessageCamera(ExtraChatSettings)
    case confirmVoiceRecording(ExtraChatSettings)
    case voiceMessageButton(ExtraChatSettings)
    case swipeToReply(ExtraChatSettings)
    case personalChatDoubleTapAction(ExtraChatSettings)
    case personalChatDoubleTapInfo
    case channelsHeader
    case channelBottomPanel(ExtraChatSettings)
    case wideChannelPosts(ExtraChatSettings)
    case channelSwipeToNext(ExtraChatSettings)
    case channelPostReactions(ExtraChatSettings)
    case channelPostDoubleTapAction(ExtraChatSettings)
    case channelPostDoubleTapInfo
    case chatListHeader
    case compactChatList(ExtraChatSettings)
    case chatSwipeOptions(ExtraChatSettings)
    case chatSwipeDelete(ExtraChatSettings)

    var section: ItemListSectionId {
        switch self {
        case .generalHeader, .compactPinnedMessagesPanel:
            return ExtraChatSettingsSection.general.rawValue
        case .stickerSizeHeader, .stickerSize:
            return ExtraChatSettingsSection.stickerSize.rawValue
        case .animateEmojiStickers:
            return ExtraChatSettingsSection.stickerOptions.rawValue
        case .messagesHeader, .showSecondsInMessageTimestamp, .hideMessageTimestamp, .videoMessageCamera, .confirmVoiceRecording, .voiceMessageButton, .swipeToReply, .personalChatDoubleTapAction, .personalChatDoubleTapInfo:
            return ExtraChatSettingsSection.messages.rawValue
        case .channelsHeader, .channelBottomPanel, .wideChannelPosts, .channelSwipeToNext, .channelPostReactions, .channelPostDoubleTapAction, .channelPostDoubleTapInfo:
            return ExtraChatSettingsSection.channels.rawValue
        case .chatListHeader, .compactChatList, .chatSwipeOptions, .chatSwipeDelete:
            return ExtraChatSettingsSection.chatList.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .chatListHeader:
            return 0
        case .compactChatList:
            return 1
        case .chatSwipeOptions:
            return 2
        case .chatSwipeDelete:
            return 3
        case .generalHeader:
            return 4
        case .compactPinnedMessagesPanel:
            return 5
        case .stickerSizeHeader:
            return 6
        case .stickerSize:
            return 7
        case .animateEmojiStickers:
            return 9
        case .messagesHeader:
            return 10
        case .showSecondsInMessageTimestamp:
            return 11
        case .hideMessageTimestamp:
            return 12
        case .videoMessageCamera:
            return 13
        case .confirmVoiceRecording:
            return 14
        case .voiceMessageButton:
            return 15
        case .swipeToReply:
            return 16
        case .personalChatDoubleTapAction:
            return 17
        case .personalChatDoubleTapInfo:
            return 18
        case .channelsHeader:
            return 19
        case .channelBottomPanel:
            return 20
        case .wideChannelPosts:
            return 21
        case .channelSwipeToNext:
            return 22
        case .channelPostReactions:
            return 23
        case .channelPostDoubleTapAction:
            return 24
        case .channelPostDoubleTapInfo:
            return 25
        }
    }

    static func ==(lhs: ExtraChatSettingsEntry, rhs: ExtraChatSettingsEntry) -> Bool {
        switch lhs {
        case .generalHeader:
            if case .generalHeader = rhs {
                return true
            }
            return false
        case let .compactPinnedMessagesPanel(lhsSettings):
            if case let .compactPinnedMessagesPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .stickerSizeHeader:
            if case .stickerSizeHeader = rhs {
                return true
            }
            return false
        case let .stickerSize(lhsSettings):
            if case let .stickerSize(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .animateEmojiStickers(lhsSettings):
            if case let .animateEmojiStickers(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .messagesHeader:
            if case .messagesHeader = rhs {
                return true
            }
            return false
        case let .showSecondsInMessageTimestamp(lhsSettings):
            if case let .showSecondsInMessageTimestamp(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideMessageTimestamp(lhsSettings):
            if case let .hideMessageTimestamp(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .videoMessageCamera(lhsSettings):
            if case let .videoMessageCamera(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .confirmVoiceRecording(lhsSettings):
            if case let .confirmVoiceRecording(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .voiceMessageButton(lhsSettings):
            if case let .voiceMessageButton(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .swipeToReply(lhsSettings):
            if case let .swipeToReply(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .personalChatDoubleTapAction(lhsSettings):
            if case let .personalChatDoubleTapAction(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .personalChatDoubleTapInfo:
            if case .personalChatDoubleTapInfo = rhs {
                return true
            }
            return false
        case .channelsHeader:
            if case .channelsHeader = rhs {
                return true
            }
            return false
        case let .channelBottomPanel(lhsSettings):
            if case let .channelBottomPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .wideChannelPosts(lhsSettings):
            if case let .wideChannelPosts(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .channelSwipeToNext(lhsSettings):
            if case let .channelSwipeToNext(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .channelPostReactions(lhsSettings):
            if case let .channelPostReactions(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .channelPostDoubleTapAction(lhsSettings):
            if case let .channelPostDoubleTapAction(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .channelPostDoubleTapInfo:
            if case .channelPostDoubleTapInfo = rhs {
                return true
            }
            return false
        case .chatListHeader:
            if case .chatListHeader = rhs {
                return true
            }
            return false
        case let .compactChatList(lhsSettings):
            if case let .compactChatList(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .chatSwipeOptions(lhsSettings):
            if case let .chatSwipeOptions(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .chatSwipeDelete(lhsSettings):
            if case let .chatSwipeDelete(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        }
    }

    static func <(lhs: ExtraChatSettingsEntry, rhs: ExtraChatSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraChatSettingsArguments

        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }

        switch self {
        case .generalHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: extraString(presentationData, ru: "Закрепленные", en: "Pinned Messages"), sectionId: self.section)
        case let .compactPinnedMessagesPanel(settings):
            return switchItem(title: extraString(presentationData, ru: "Сократить закрепленные", en: "Compact Pinned Messages"), text: extraString(presentationData, ru: "Сокращает закрепленные сообщения в небольшую клавишу.", en: "Turns the pinned messages panel into a small button."), value: settings.compactPinnedMessagesPanel, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.compactPinnedMessagesPanel = value
                    return current
                }, true)
            })
        case .stickerSizeHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: extraString(presentationData, ru: "Размеры одиночных стикеров", en: "Standalone Sticker Size"), sectionId: self.section)
        case let .stickerSize(settings):
            return ExtraStickerSizeSliderItem(
                presentationData: presentationData,
                value: settings.stickerSizePercent,
                showTime: settings.showStickerTime,
                sectionId: self.section,
                updatedSize: { value in
                    arguments.update({ current in
                        var current = current
                        current.stickerSizePercent = value
                        return current
                    }, true)
                },
                updatedShowTime: { value in
                    arguments.update({ current in
                        var current = current
                        current.showStickerTime = value
                        return current
                    }, true)
                }
            )
        case let .animateEmojiStickers(settings):
            return switchItem(title: extraString(presentationData, ru: "Анимация эмоджи стикеров", en: "Emoji Sticker Animation"), text: extraString(presentationData, ru: "Включает анимацию обычных эмоджи-стикеров.", en: "Enables regular emoji sticker animation."), value: settings.animateEmojiStickers, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.animateEmojiStickers = value
                    return current
                }, true)
            })
        case .messagesHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: extraString(presentationData, ru: "Сообщения", en: "Messages"), sectionId: self.section)
        case let .showSecondsInMessageTimestamp(settings):
            return switchItem(title: extraString(presentationData, ru: "Секунды ко времени", en: "Show Seconds"), text: extraString(presentationData, ru: "Показывает секунды рядом со временем сообщения.", en: "Shows seconds next to the message timestamp."), value: settings.showSecondsInMessageTimestamp, enabled: !settings.hideMessageTimestamp, update: { value in
                arguments.update({ current in
                    var current = current
                    current.showSecondsInMessageTimestamp = value
                    return current
                }, true)
            })
        case let .hideMessageTimestamp(settings):
            return switchItem(title: extraString(presentationData, ru: "Отключить время", en: "Hide Timestamps"), text: extraString(presentationData, ru: "Скрывает время у сообщений.", en: "Hides timestamps on messages."), value: settings.hideMessageTimestamp, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideMessageTimestamp = value
                    if value {
                        current.showSecondsInMessageTimestamp = false
                    }
                    return current
                }, true)
            })
        case let .videoMessageCamera(settings):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Камера видеосообщения", en: "Video Message Camera"),
                label: settings.videoMessageCamera.title(strings: presentationData.strings),
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: arguments.openVideoMessageCamera
            )
        case let .confirmVoiceRecording(settings):
            return switchItem(title: extraString(presentationData, ru: "Подтверждать запись голосового", en: "Confirm Voice Recording"), text: extraString(presentationData, ru: "Показывает предупреждение перед началом записи голосового.", en: "Shows a warning before starting voice recording."), value: settings.confirmVoiceRecording, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.confirmVoiceRecording = value
                    return current
                }, true)
            })
        case let .voiceMessageButton(settings):
            return switchItem(title: extraString(presentationData, ru: "Клавиша голосового сообщения", en: "Voice Message Button"), text: extraString(presentationData, ru: "Показывает кнопку записи голосового сообщения.", en: "Shows the voice message recording button."), value: settings.voiceMessageButton, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.voiceMessageButton = value
                    return current
                }, true)
            })
        case let .swipeToReply(settings):
            return switchItem(title: extraString(presentationData, ru: "Свайп для ответа на сообщение", en: "Swipe to Reply"), text: extraString(presentationData, ru: "Включает ответ свайпом по сообщению.", en: "Enables replying by swiping on a message."), value: settings.swipeToReply, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.swipeToReply = value
                    return current
                }, true)
            })
        case let .personalChatDoubleTapAction(settings):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Двойной тап в личных чатах", en: "Double Tap in Private Chats"),
                label: settings.personalChatDoubleTapAction.title(strings: presentationData.strings),
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: arguments.openPersonalChatDoubleTapAction
            )
        case .personalChatDoubleTapInfo:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(extraString(presentationData, ru: "Выбирает действие, которое выполняется при двойном тапе по сообщению в личных чатах.", en: "Selects the action performed when double-tapping a message in private chats.")),
                sectionId: self.section
            )
        case .channelsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: extraString(presentationData, ru: "Каналы", en: "Channels"), sectionId: self.section)
        case let .channelBottomPanel(settings):
            return switchItem(title: extraString(presentationData, ru: "Нижняя панель", en: "Bottom Panel"), text: extraString(presentationData, ru: "Показывает нижнюю панель в каналах: подписаться, отправить подарок и другие действия.", en: "Shows the bottom panel in channels: subscribe, send gift, and other actions."), value: settings.channelBottomPanel, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.channelBottomPanel = value
                    return current
                }, true)
            })
        case let .wideChannelPosts(settings):
            return switchItem(title: extraString(presentationData, ru: "Широкие посты", en: "Wide Posts"), text: extraString(presentationData, ru: "Расширяет посты каналов до ширины экрана с учетом системных отступов.", en: "Expands channel posts to screen width while respecting system insets."), value: settings.wideChannelPosts, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.wideChannelPosts = value
                    return current
                }, true)
            })
        case let .channelSwipeToNext(settings):
            return switchItem(title: extraString(presentationData, ru: "Свайп между каналами", en: "Swipe Between Channels"), text: extraString(presentationData, ru: "Открывает следующий непрочитанный канал свайпом вверх в конце текущего.", en: "Opens the next unread channel by swiping up at the end of the current one."), value: settings.channelSwipeToNext, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.channelSwipeToNext = value
                    return current
                }, true)
            })
        case let .channelPostReactions(settings):
            return switchItem(title: extraString(presentationData, ru: "Реакции на постах", en: "Post Reactions"), text: extraString(presentationData, ru: "Показывает реакции под постами каналов. Ставить реакции можно в любом случае.", en: "Shows reactions below channel posts. You can still react either way."), value: settings.channelPostReactions, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.channelPostReactions = value
                    return current
                }, true)
            })
        case let .channelPostDoubleTapAction(settings):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Двойной тап по посту", en: "Double Tap on Posts"),
                label: settings.channelPostDoubleTapAction.title(strings: presentationData.strings),
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: arguments.openChannelPostDoubleTapAction
            )
        case .channelPostDoubleTapInfo:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(extraString(presentationData, ru: "Выбирает действие, которое выполняется при двойном тапе по посту в канале.", en: "Selects the action performed when double-tapping a channel post.")),
                sectionId: self.section
            )
        case .chatListHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: extraString(presentationData, ru: "Список чатов", en: "Chat List"), sectionId: self.section)
        case let .compactChatList(settings):
            return switchItem(title: extraString(presentationData, ru: "Компактный список чатов", en: "Compact Chat List"), text: extraString(presentationData, ru: "Уменьшает строки списка и показывает превью в одну строку.", en: "Reduces row height and shows previews on one line."), value: settings.compactChatList, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.compactChatList = value
                    return current
                }, false)
            })
        case let .chatSwipeOptions(settings):
            return switchItem(title: extraString(presentationData, ru: "Свайп для опций чатов", en: "Swipe for Chat Options"), text: extraString(presentationData, ru: "Показывает инструменты при свайпе по превью чата.", en: "Shows tools when swiping a chat preview."), value: settings.chatSwipeOptions, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.chatSwipeOptions = value
                    if !value {
                        current.chatSwipeDelete = false
                    }
                    return current
                }, true)
            })
        case let .chatSwipeDelete(settings):
            return switchItem(title: extraString(presentationData, ru: "Свайп для удаления", en: "Swipe to Delete"), text: extraString(presentationData, ru: "Показывает удаление чата среди действий свайпа.", en: "Shows delete among the chat swipe actions."), value: settings.chatSwipeDelete, enabled: settings.chatSwipeOptions, update: { value in
                arguments.update({ current in
                    var current = current
                    current.chatSwipeDelete = value
                    return current
                }, true)
            })
        }
    }
}

private func extraChatSettingsEntries(settings: ExtraChatSettings, appliedSettings: ExtraChatSettings, initialSettings: ExtraChatSettings) -> [ExtraChatSettingsEntry] {
    return [
        .chatListHeader,
        .compactChatList(settings),
        .chatSwipeOptions(settings),
        .chatSwipeDelete(settings),
        .generalHeader,
        .compactPinnedMessagesPanel(settings),
        .stickerSizeHeader,
        .stickerSize(settings),
        .animateEmojiStickers(settings),
        .messagesHeader,
        .showSecondsInMessageTimestamp(settings),
        .hideMessageTimestamp(settings),
        .videoMessageCamera(settings),
        .confirmVoiceRecording(settings),
        .voiceMessageButton(settings),
        .swipeToReply(settings),
        .personalChatDoubleTapAction(settings),
        .personalChatDoubleTapInfo,
        .channelsHeader,
        .channelBottomPanel(settings),
        .wideChannelPosts(settings),
        .channelSwipeToNext(settings),
        .channelPostReactions(settings),
        .channelPostDoubleTapAction(settings),
        .channelPostDoubleTapInfo
    ]
}

private func extraChatSettingsController(context: AccountContext) -> ViewController {
    let appliedSettings = ExtraChatSettings.effectiveCompactSettings
    let initialSettings = ExtraChatSettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)
    var pushController: ((ViewController) -> Void)?
    let restartWarningPromise = ValuePromise(false, ignoreRepeated: true)
    var restartWarningTimer: SwiftSignalKit.Timer?

    let showRestartWarning: () -> Void = {
        restartWarningTimer?.invalidate()
        restartWarningPromise.set(true)
        let timer = SwiftSignalKit.Timer(timeout: 4.0, repeat: false, completion: {
            restartWarningPromise.set(false)
        }, queue: Queue.mainQueue())
        restartWarningTimer = timer
        timer.start()
    }

    let updateSettings: (((ExtraChatSettings) -> ExtraChatSettings), Bool) -> Void = { f, notify in
        let updated = stateValue.modify { current in
            let previous = current
            let updated = f(current)
            updated.save(notify: notify)
            if previous.compactChatList != updated.compactChatList {
                showRestartWarning()
            }
            return updated
        }
        statePromise.set(updated)
    }

    let arguments = ExtraChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {
            pushController?(extraVideoMessageCameraSettingsController(context: context, statePromise: statePromise, updateSettings: updateSettings))
        },
        openPersonalChatDoubleTapAction: {
            pushController?(extraPersonalChatDoubleTapSettingsController(context: context, statePromise: statePromise, updateSettings: updateSettings))
        },
        openChannelPostDoubleTapAction: {
            pushController?(extraChannelPostDoubleTapSettingsController(context: context, statePromise: statePromise, updateSettings: updateSettings))
        },
        restart: {
            exit(0)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get(), restartWarningPromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings, showRestartWarning -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Настройки чатов", en: "Chat Settings")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraChatSettingsEntries(settings: settings, appliedSettings: appliedSettings, initialSettings: initialSettings),
            style: .blocks,
            footerItem: showRestartWarning && (settings.compactChatList != appliedSettings.compactChatList || settings.compactChatList != initialSettings.compactChatList) ? ExtraRestartFooterItem(presentationData: ItemListPresentationData(presentationData), action: arguments.restart) : nil,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushController = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

private final class ExtraStickerSizeSliderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let value: Int32
    let showTime: Bool
    let sectionId: ItemListSectionId
    let updatedSize: (Int32) -> Void
    let updatedShowTime: (Bool) -> Void

    init(presentationData: ItemListPresentationData, value: Int32, showTime: Bool, sectionId: ItemListSectionId, updatedSize: @escaping (Int32) -> Void, updatedShowTime: @escaping (Bool) -> Void) {
        self.presentationData = presentationData
        self.value = value
        self.showTime = showTime
        self.sectionId = sectionId
        self.updatedSize = updatedSize
        self.updatedShowTime = updatedShowTime
    }

    var selectable: Bool {
        return false
    }

    func selected(listView: ListView) {
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = ExtraStickerSizeSliderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params)
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in
                        apply(false)
                    })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ExtraStickerSizeSliderItemNode {
                let makeLayout = nodeValue.asyncLayout()
                async {
                    let (layout, apply) = makeLayout(self, params)
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply(animation.isAnimated)
                        })
                    }
                }
            }
        }
    }
}

private final class ExtraStickerSizeSliderItemNode: ListViewItemNode {
    private let backgroundView = UIView()
    private let minLabel = UILabel()
    private let valueLabel = UILabel()
    private let maxLabel = UILabel()
    private let slider = UISlider()
    private let separatorView = UIView()
    private let showTimeLabel = UILabel()
    private let showTimeSwitch = UISwitch()
    private var updatedSize: ((Int32) -> Void)?
    private var updatedShowTime: ((Bool) -> Void)?
    private var currentValue: Int32 = 100
    private var currentShowTime = true

    override init(layerBacked: Bool = false, rotated: Bool = false, seeThrough: Bool = false) {
        super.init(layerBacked: layerBacked, rotated: rotated, seeThrough: seeThrough)

        self.backgroundView.layer.cornerRadius = 26.0
        self.backgroundView.clipsToBounds = true
        self.view.addSubview(self.backgroundView)

        self.minLabel.text = "0%"
        self.minLabel.font = Font.medium(17.0)
        self.backgroundView.addSubview(self.minLabel)

        self.valueLabel.font = Font.semibold(21.0)
        self.valueLabel.textAlignment = .center
        self.backgroundView.addSubview(self.valueLabel)

        self.maxLabel.text = "100%"
        self.maxLabel.font = Font.medium(17.0)
        self.maxLabel.textAlignment = .right
        self.backgroundView.addSubview(self.maxLabel)

        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 100.0
        self.slider.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        self.backgroundView.addSubview(self.slider)

        self.backgroundView.addSubview(self.separatorView)

        self.showTimeLabel.font = Font.regular(16.0)
        self.backgroundView.addSubview(self.showTimeLabel)

        self.showTimeSwitch.addTarget(self, action: #selector(self.showTimeValueChanged), for: .valueChanged)
        self.backgroundView.addSubview(self.showTimeSwitch)
    }

    @objc private func sliderValueChanged() {
        let roundedValue = Int32((self.slider.value / 5.0).rounded() * 5.0)
        if roundedValue != self.currentValue {
            self.currentValue = roundedValue
            self.valueLabel.text = "\(roundedValue)%"
            self.updatedSize?(roundedValue)
        }
    }

    @objc private func showTimeValueChanged() {
        let value = self.showTimeSwitch.isOn
        if value != self.currentShowTime {
            self.currentShowTime = value
            self.updatedShowTime?(value)
        }
    }

    func asyncLayout() -> (_ item: ExtraStickerSizeSliderItem, _ params: ListViewItemLayoutParams) -> (ListViewItemNodeLayout, (Bool) -> Void) {
        return { item, params in
            let contentSize = CGSize(width: params.width, height: 150.0)
            let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)

            return (layout, { [weak self] _ in
                guard let self else {
                    return
                }

                let theme = item.presentationData.theme
                self.backgroundView.backgroundColor = theme.list.itemBlocksBackgroundColor
                self.minLabel.textColor = theme.list.itemSecondaryTextColor
                self.valueLabel.textColor = theme.list.itemPrimaryTextColor
                self.maxLabel.textColor = theme.list.itemSecondaryTextColor
                self.slider.minimumTrackTintColor = theme.list.itemAccentColor
                self.slider.maximumTrackTintColor = theme.list.itemSecondaryTextColor.withAlphaComponent(0.24)
                self.separatorView.backgroundColor = theme.list.itemBlocksSeparatorColor
                self.showTimeLabel.text = extraString(item.presentationData, ru: "Показывать время", en: "Show Time")
                self.showTimeLabel.textColor = theme.list.itemPrimaryTextColor
                self.updatedSize = item.updatedSize
                self.updatedShowTime = item.updatedShowTime
                self.currentValue = min(100, max(0, item.value))
                self.currentShowTime = item.showTime
                self.valueLabel.text = "\(self.currentValue)%"
                self.slider.setValue(Float(self.currentValue), animated: false)
                self.showTimeSwitch.setOn(item.showTime, animated: false)

                let sideInset: CGFloat = 0.0
                let frame = CGRect(x: params.leftInset + sideInset, y: 0.0, width: params.width - params.leftInset - params.rightInset - sideInset * 2.0, height: 150.0)
                self.backgroundView.frame = frame
                self.minLabel.frame = CGRect(x: 18.0, y: 14.0, width: 80.0, height: 32.0)
                self.valueLabel.frame = CGRect(x: 96.0, y: 10.0, width: frame.width - 192.0, height: 38.0)
                self.maxLabel.frame = CGRect(x: frame.width - 98.0, y: 14.0, width: 80.0, height: 32.0)
                self.slider.frame = CGRect(x: 18.0, y: 62.0, width: frame.width - 36.0, height: 32.0)
                self.separatorView.frame = CGRect(x: 0.0, y: 106.0, width: frame.width, height: UIScreenPixel)
                self.showTimeLabel.frame = CGRect(x: 18.0, y: 116.0, width: frame.width - 122.0, height: 34.0)
                self.showTimeSwitch.frame = CGRect(origin: CGPoint(x: frame.width - 69.0, y: 116.0), size: self.showTimeSwitch.bounds.size)
            })
        }
    }
}

private enum ExtraVideoMessageCameraSettingsEntry: ItemListNodeEntry {
    case option(ExtraChatSettings.VideoMessageCamera, ExtraChatSettings.VideoMessageCamera)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(option, _):
            return option.stableId
        }
    }

    static func ==(lhs: ExtraVideoMessageCameraSettingsEntry, rhs: ExtraVideoMessageCameraSettingsEntry) -> Bool {
        switch lhs {
        case let .option(lhsOption, lhsSelected):
            if case let .option(rhsOption, rhsSelected) = rhs {
                return lhsOption == rhsOption && lhsSelected == rhsSelected
            }
            return false
        }
    }

    static func <(lhs: ExtraVideoMessageCameraSettingsEntry, rhs: ExtraVideoMessageCameraSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraChatSettingsArguments

        switch self {
        case let .option(option, selectedOption):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title(strings: presentationData.strings),
                style: .left,
                checked: option == selectedOption,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.update({ current in
                        var current = current
                        current.videoMessageCamera = option
                        return current
                    }, true)
                }
            )
        }
    }
}

private extension ExtraChatSettings.VideoMessageCamera {
    var stableId: Int32 {
        switch self {
        case .front:
            return 0
        case .back:
            return 1
        case .ask:
            return 2
        }
    }
}

private func extraVideoMessageCameraSettingsEntries(settings: ExtraChatSettings) -> [ExtraVideoMessageCameraSettingsEntry] {
    return ExtraChatSettings.VideoMessageCamera.allCases.map { .option($0, settings.videoMessageCamera) }
}

private func extraVideoMessageCameraSettingsController(context: AccountContext, statePromise: ValuePromise<ExtraChatSettings>, updateSettings: @escaping (((ExtraChatSettings) -> ExtraChatSettings), Bool) -> Void) -> ViewController {
    let arguments = ExtraChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {},
        openPersonalChatDoubleTapAction: {},
        openChannelPostDoubleTapAction: {},
        restart: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Камера видеосообщения", en: "Video Message Camera")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraVideoMessageCameraSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private enum ExtraPersonalChatDoubleTapSettingsEntry: ItemListNodeEntry {
    case option(ExtraChatSettings.PersonalChatDoubleTapAction, ExtraChatSettings.PersonalChatDoubleTapAction)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(option, _):
            return option.stableId
        }
    }

    static func ==(lhs: ExtraPersonalChatDoubleTapSettingsEntry, rhs: ExtraPersonalChatDoubleTapSettingsEntry) -> Bool {
        switch lhs {
        case let .option(lhsOption, lhsSelected):
            if case let .option(rhsOption, rhsSelected) = rhs {
                return lhsOption == rhsOption && lhsSelected == rhsSelected
            }
            return false
        }
    }

    static func <(lhs: ExtraPersonalChatDoubleTapSettingsEntry, rhs: ExtraPersonalChatDoubleTapSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraChatSettingsArguments

        switch self {
        case let .option(option, selectedOption):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title(strings: presentationData.strings),
                style: .left,
                checked: option == selectedOption,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.update({ current in
                        var current = current
                        current.personalChatDoubleTapAction = option
                        return current
                    }, true)
                }
            )
        }
    }
}

private extension ExtraChatSettings.PersonalChatDoubleTapAction {
    var stableId: Int32 {
        switch self {
        case .savedMessages:
            return 0
        case .reaction:
            return 1
        case .edit:
            return 2
        case .forward:
            return 3
        case .reply:
            return 4
        case .pin:
            return 5
        case .select:
            return 6
        case .copy:
            return 7
        case .contextMenu:
            return 8
        }
    }
}

private func extraPersonalChatDoubleTapSettingsEntries(settings: ExtraChatSettings) -> [ExtraPersonalChatDoubleTapSettingsEntry] {
    return ExtraChatSettings.PersonalChatDoubleTapAction.allCases.map { .option($0, settings.personalChatDoubleTapAction) }
}

private func extraPersonalChatDoubleTapSettingsController(context: AccountContext, statePromise: ValuePromise<ExtraChatSettings>, updateSettings: @escaping (((ExtraChatSettings) -> ExtraChatSettings), Bool) -> Void) -> ViewController {
    let arguments = ExtraChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {},
        openPersonalChatDoubleTapAction: {},
        openChannelPostDoubleTapAction: {},
        restart: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Двойной тап", en: "Double Tap")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraPersonalChatDoubleTapSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private enum ExtraChannelPostDoubleTapSettingsEntry: ItemListNodeEntry {
    case option(ExtraChatSettings.ChannelPostDoubleTapAction, ExtraChatSettings.ChannelPostDoubleTapAction)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(option, _):
            return option.stableId
        }
    }

    static func ==(lhs: ExtraChannelPostDoubleTapSettingsEntry, rhs: ExtraChannelPostDoubleTapSettingsEntry) -> Bool {
        switch lhs {
        case let .option(lhsOption, lhsSelected):
            if case let .option(rhsOption, rhsSelected) = rhs {
                return lhsOption == rhsOption && lhsSelected == rhsSelected
            }
            return false
        }
    }

    static func <(lhs: ExtraChannelPostDoubleTapSettingsEntry, rhs: ExtraChannelPostDoubleTapSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraChatSettingsArguments

        switch self {
        case let .option(option, selectedOption):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title(strings: presentationData.strings),
                style: .left,
                checked: option == selectedOption,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.update({ current in
                        var current = current
                        current.channelPostDoubleTapAction = option
                        return current
                    }, true)
                }
            )
        }
    }
}

private extension ExtraChatSettings.ChannelPostDoubleTapAction {
    var stableId: Int32 {
        switch self {
        case .savedMessages:
            return 0
        case .reaction:
            return 1
        case .forward:
            return 2
        case .reply:
            return 3
        case .select:
            return 4
        case .copy:
            return 5
        case .contextMenu:
            return 6
        }
    }
}

private func extraChannelPostDoubleTapSettingsEntries(settings: ExtraChatSettings) -> [ExtraChannelPostDoubleTapSettingsEntry] {
    return ExtraChatSettings.ChannelPostDoubleTapAction.allCases.map { .option($0, settings.channelPostDoubleTapAction) }
}

private func extraChannelPostDoubleTapSettingsController(context: AccountContext, statePromise: ValuePromise<ExtraChatSettings>, updateSettings: @escaping (((ExtraChatSettings) -> ExtraChatSettings), Bool) -> Void) -> ViewController {
    let arguments = ExtraChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {},
        openPersonalChatDoubleTapAction: {},
        openChannelPostDoubleTapAction: {},
        restart: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Двойной тап", en: "Double Tap")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraChannelPostDoubleTapSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private final class ExtraChatFoldersSettingsArguments {
    let update: ((ExtraChatFolderSettings) -> ExtraChatFolderSettings) -> Void

    init(update: @escaping ((ExtraChatFolderSettings) -> ExtraChatFolderSettings) -> Void) {
        self.update = update
    }
}

private enum ExtraChatFoldersSettingsSection: Int32 {
    case options
}

private enum ExtraChatFoldersSettingsEntry: ItemListNodeEntry {
    case disableFolders(ExtraChatFolderSettings)
    case compactPanel(ExtraChatFolderSettings)
    case foldersAtBottom(ExtraChatFolderSettings)
    case openLastFolder(ExtraChatFolderSettings)

    var section: ItemListSectionId {
        return ExtraChatFoldersSettingsSection.options.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .disableFolders:
            return 0
        case .compactPanel:
            return 1
        case .foldersAtBottom:
            return 2
        case .openLastFolder:
            return 3
        }
    }

    static func ==(lhs: ExtraChatFoldersSettingsEntry, rhs: ExtraChatFoldersSettingsEntry) -> Bool {
        switch lhs {
        case let .disableFolders(lhsSettings):
            if case let .disableFolders(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .compactPanel(lhsSettings):
            if case let .compactPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .foldersAtBottom(lhsSettings):
            if case let .foldersAtBottom(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .openLastFolder(lhsSettings):
            if case let .openLastFolder(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        }
    }

    static func <(lhs: ExtraChatFoldersSettingsEntry, rhs: ExtraChatFoldersSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraChatFoldersSettingsArguments

        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }

        switch self {
        case let .disableFolders(settings):
            return switchItem(title: extraString(presentationData, ru: "Отключить папки", en: "Disable Folders"), text: extraString(presentationData, ru: "Полностью скрывает панель папок, даже если папки существуют.", en: "Completely hides the folder bar, even if folders exist."), value: settings.disableFolders, enabled: true, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableFolders = value
                    return current
                }
            })
        case let .compactPanel(settings):
            return switchItem(title: extraString(presentationData, ru: "Компактная панель папок", en: "Compact Folder Bar"), text: extraString(presentationData, ru: "Скрывает панель папок и переносит выбор папки в кнопку сверху.", en: "Hides the folder bar and moves folder selection into a button at the top."), value: settings.compactPanel, enabled: !settings.disableFolders && !settings.foldersAtBottom, update: { value in
                arguments.update { current in
                    var current = current
                    current.compactPanel = value
                    if value {
                        current.foldersAtBottom = false
                    }
                    return current
                }
            })
        case let .foldersAtBottom(settings):
            return switchItem(title: extraString(presentationData, ru: "Папки снизу", en: "Folders at Bottom"), text: extraString(presentationData, ru: "Переносит панель папок в нижнюю часть экрана.", en: "Moves the folder bar to the bottom of the screen."), value: settings.foldersAtBottom, enabled: !settings.disableFolders && !settings.compactPanel, update: { value in
                arguments.update { current in
                    var current = current
                    current.foldersAtBottom = value
                    if value {
                        current.compactPanel = false
                    }
                    return current
                }
            })
        case let .openLastFolder(settings):
            return switchItem(title: extraString(presentationData, ru: "Открывать последнюю папку", en: "Open Last Folder"), text: extraString(presentationData, ru: "После перезапуска открывает папку, которая была активна при закрытии приложения.", en: "After relaunching, opens the folder that was active when the app closed."), value: settings.openLastFolder, enabled: !settings.disableFolders, update: { value in
                arguments.update { current in
                    var current = current
                    current.openLastFolder = value
                    return current
                }
            })
        }
    }
}

private func extraChatFoldersSettingsEntries(settings: ExtraChatFolderSettings) -> [ExtraChatFoldersSettingsEntry] {
    return [
        .disableFolders(settings),
        .compactPanel(settings),
        .foldersAtBottom(settings),
        .openLastFolder(settings)
    ]
}

private func extraChatFoldersSettingsController(context: AccountContext) -> ViewController {
    let initialSettings = ExtraChatFolderSettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)

    let arguments = ExtraChatFoldersSettingsArguments(update: { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        statePromise.set(updated)
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Папки с чатами", en: "Chat Folders")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraChatFoldersSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
