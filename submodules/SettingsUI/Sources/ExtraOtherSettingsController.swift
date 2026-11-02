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

private func extraString(_ presentationData: ItemListPresentationData, ru: String, en: String) -> String {
    return extraString(presentationData.strings, ru: ru, en: en)
}

private typealias ExtraOtherSettingsState = ExtraOtherSettings

private enum ExtraOtherSettingsSection: Int32 {
    case network
    case translation
    case voiceToText
    case voiceAndVideoRecording
    case gallery
}

private enum ExtraOtherSettingsEntry: ItemListNodeEntry {
    case header(ExtraOtherSettingsSection, String)
    
    case automaticProxy(Bool)
    
    case autoTranslate(Bool)
    case translationService(String)
    case translationButton(Bool)
    
    case voiceTranscription(Bool)
    case transcriptionService(String)
    
    case forceDeviceMicrophone(Bool)
    
    case hideCameraInGallery(Bool)
    case hideCameraPreviewInGallery(Bool, Bool)
    
    var section: ItemListSectionId {
        switch self {
        case let .header(section, _):
            return section.rawValue
            
        case .automaticProxy:
            return ExtraOtherSettingsSection.network.rawValue
            
        case .autoTranslate, .translationService, .translationButton:
            return ExtraOtherSettingsSection.translation.rawValue
            
        case .voiceTranscription, .transcriptionService:
            return ExtraOtherSettingsSection.voiceToText.rawValue
            
        case .forceDeviceMicrophone:
            return ExtraOtherSettingsSection.voiceAndVideoRecording.rawValue
            
        case .hideCameraInGallery, .hideCameraPreviewInGallery:
            return ExtraOtherSettingsSection.gallery.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .header(section, _):
            return section.rawValue * 1000
            
        case .automaticProxy:
            return ExtraOtherSettingsSection.network.rawValue * 1000 + 1
            
        case .autoTranslate:
            return ExtraOtherSettingsSection.translation.rawValue * 1000 + 1
        case .translationService:
            return ExtraOtherSettingsSection.translation.rawValue * 1000 + 2
        case .translationButton:
            return ExtraOtherSettingsSection.translation.rawValue * 1000 + 3
            
        case .voiceTranscription:
            return ExtraOtherSettingsSection.voiceToText.rawValue * 1000 + 1
        case .transcriptionService:
            return ExtraOtherSettingsSection.voiceToText.rawValue * 1000 + 2
            
        case .forceDeviceMicrophone:
            return ExtraOtherSettingsSection.voiceAndVideoRecording.rawValue * 1000 + 1
            
        case .hideCameraInGallery:
            return ExtraOtherSettingsSection.gallery.rawValue * 1000 + 1
        case .hideCameraPreviewInGallery:
            return ExtraOtherSettingsSection.gallery.rawValue * 1000 + 2
        }
    }
    
    static func ==(lhs: ExtraOtherSettingsEntry, rhs: ExtraOtherSettingsEntry) -> Bool {
        switch lhs {
        case let .header(lhsSection, lhsText):
            if case let .header(rhsSection, rhsText) = rhs {
                return lhsSection == rhsSection && lhsText == rhsText
            }
            return false
            
        case let .automaticProxy(lhsValue):
            if case let .automaticProxy(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .autoTranslate(lhsValue):
            if case let .autoTranslate(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .translationService(lhsValue):
            if case let .translationService(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .translationButton(lhsValue):
            if case let .translationButton(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .voiceTranscription(lhsValue):
            if case let .voiceTranscription(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .transcriptionService(lhsValue):
            if case let .transcriptionService(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .forceDeviceMicrophone(lhsValue):
            if case let .forceDeviceMicrophone(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .hideCameraInGallery(lhsValue):
            if case let .hideCameraInGallery(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .hideCameraPreviewInGallery(lhsValue, lhsEnabled):
            if case let .hideCameraPreviewInGallery(rhsValue, rhsEnabled) = rhs {
                return lhsValue == rhsValue && lhsEnabled == rhsEnabled
            }
            return false
        }
    }
    
    static func <(lhs: ExtraOtherSettingsEntry, rhs: ExtraOtherSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraOtherSettingsArguments
        
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
            
        case let .automaticProxy(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Автопоиск прокси", en: "Automatic Proxy Discovery"),
                text: extraString(presentationData, ru: "Раз в 10 минут проверяет публичные списки MTProxy и автоматически подключает лучший доступный сервер. Выкл. по умолчанию.", en: "Every 10 minutes it checks public MTProxy lists and automatically connects to the best available server. Off by default."),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateAutomaticProxy(value)
                }
            )
            
        case let .autoTranslate(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Включить автоперевод", en: "Enable Auto-Translate"),
                text: extraString(presentationData, ru: "Автоматически переводит посты и сообщения без дополнительных действий.", en: "Automatically translates posts and messages without any extra action."),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateAutoTranslate(value)
                }
            )
            
        case let .translationService(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: nil,
                title: extraString(presentationData, ru: "Сервис", en: "Service"),
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.openTranslationService()
                }
            )
            
        case let .translationButton(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Кнопка перевода", en: "Translate Button"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateTranslationButton(value)
                }
            )
            
        case let .voiceTranscription(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Транскрибация", en: "Transcription"),
                text: extraString(presentationData, ru: "Включает или отключает преобразование голоса в текст.", en: "Enables or disables voice-to-text."),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateVoiceTranscription(value)
                }
            )
            
        case let .transcriptionService(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: nil,
                title: extraString(presentationData, ru: "Сервис", en: "Service"),
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.openTranscriptionService()
                }
            )
            
        case let .forceDeviceMicrophone(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Микрофон устройства", en: "Device Microphone"),
                text: extraString(presentationData, ru: "Записывает с микрофона устройства, даже когда подключены другие устройства записи.", en: "Records from the device microphone even when other recording devices are connected."),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateForceDeviceMicrophone(value)
                }
            )
            
        case let .hideCameraInGallery(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Камера в галерее", en: "Camera in Gallery"),
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateHideCameraInGallery(value)
                }
            )
            
        case let .hideCameraPreviewInGallery(value, enabled):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: extraString(presentationData, ru: "Превью камеры в галерее", en: "Camera Preview in Gallery"),
                value: value,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateHideCameraPreviewInGallery(value)
                }
            )
        }
    }
}

private final class ExtraOtherSettingsArguments {
    let updateAutomaticProxy: (Bool) -> Void
    let updateAutoTranslate: (Bool) -> Void
    let openTranslationService: () -> Void
    let updateTranslationButton: (Bool) -> Void
    
    let updateVoiceTranscription: (Bool) -> Void
    let openTranscriptionService: () -> Void
    
    let updateForceDeviceMicrophone: (Bool) -> Void
    
    let updateHideCameraInGallery: (Bool) -> Void
    let updateHideCameraPreviewInGallery: (Bool) -> Void
    
    init(
        updateAutomaticProxy: @escaping (Bool) -> Void,
        updateAutoTranslate: @escaping (Bool) -> Void,
        openTranslationService: @escaping () -> Void,
        updateTranslationButton: @escaping (Bool) -> Void,
        updateVoiceTranscription: @escaping (Bool) -> Void,
        openTranscriptionService: @escaping () -> Void,
        updateForceDeviceMicrophone: @escaping (Bool) -> Void,
        updateHideCameraInGallery: @escaping (Bool) -> Void,
        updateHideCameraPreviewInGallery: @escaping (Bool) -> Void
    ) {
        self.updateAutomaticProxy = updateAutomaticProxy
        self.updateAutoTranslate = updateAutoTranslate
        self.openTranslationService = openTranslationService
        self.updateTranslationButton = updateTranslationButton
        self.updateVoiceTranscription = updateVoiceTranscription
        self.openTranscriptionService = openTranscriptionService
        self.updateForceDeviceMicrophone = updateForceDeviceMicrophone
        self.updateHideCameraInGallery = updateHideCameraInGallery
        self.updateHideCameraPreviewInGallery = updateHideCameraPreviewInGallery
    }
}

private func extraOtherSettingsEntries(strings: PresentationStrings, state: ExtraOtherSettingsState) -> [ExtraOtherSettingsEntry] {
    var entries: [ExtraOtherSettingsEntry] = []
    
    entries.append(.header(.network, extraString(strings, ru: "Сеть", en: "Network")))
    entries.append(.automaticProxy(state.automaticProxy))
    
    entries.append(.header(.translation, extraString(strings, ru: "Перевод", en: "Translation")))
    entries.append(.autoTranslate(state.autoTranslate))
    entries.append(.translationService(state.translationService.title))
    entries.append(.translationButton(state.translationButton))
    
    entries.append(.header(.voiceToText, extraString(strings, ru: "Голос в текст", en: "Voice to Text")))
    entries.append(.voiceTranscription(state.voiceTranscription))
    entries.append(.transcriptionService(state.transcriptionService.title))
    
    entries.append(.header(.voiceAndVideoRecording, extraString(strings, ru: "Запись голоса и видео", en: "Voice and Video Recording")))
    entries.append(.forceDeviceMicrophone(state.forceDeviceMicrophone))
    
    entries.append(.header(.gallery, extraString(strings, ru: "Галерея", en: "Gallery")))
    entries.append(.hideCameraInGallery(!state.hideCameraInGallery))
    entries.append(.hideCameraPreviewInGallery(!state.hideCameraPreviewInGallery, !state.hideCameraInGallery))
    
    return entries
}

private func extraSelectionCheckIcon(color: UIColor) -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    
    guard let context = UIGraphicsGetCurrentContext() else {
        UIGraphicsEndImageContext()
        return nil
    }
    
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(2.2)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    context.move(to: CGPoint(x: 4.5, y: 11.5))
    context.addLine(to: CGPoint(x: 9.0, y: 16.0))
    context.addLine(to: CGPoint(x: 17.5, y: 6.5))
    context.strokePath()
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}

private func extraSelectionEmptyIcon() -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

public func extraOtherSettingsController(context: AccountContext) -> ViewController {
    var currentState = ExtraOtherSettingsState()
    let statePromise = ValuePromise<ExtraOtherSettingsState>(currentState, ignoreRepeated: true)
    
    var pushController: ((ViewController) -> Void)?
    
    let arguments = ExtraOtherSettingsArguments(
        updateAutomaticProxy: { value in
            currentState.setAutomaticProxy(value)
            statePromise.set(currentState)
        },
        updateAutoTranslate: { value in
            currentState.setAutoTranslate(value)
            statePromise.set(currentState)
        },
        openTranslationService: {
            pushController?(extraOtherTranslationServiceController(
                context: context,
                statePromise: statePromise,
                updateService: { value in
                    currentState.setTranslationService(value)
                    statePromise.set(currentState)
                }
            ))
        },
        updateTranslationButton: { value in
            currentState.setTranslationButton(value)
            statePromise.set(currentState)
        },
        updateVoiceTranscription: { value in
            currentState.setVoiceTranscription(value)
            statePromise.set(currentState)
        },
        openTranscriptionService: {
            pushController?(extraOtherTranscriptionServiceController(
                context: context,
                statePromise: statePromise,
                updateService: { value in
                    currentState.setTranscriptionService(value)
                    statePromise.set(currentState)
                }
            ))
        },
        updateForceDeviceMicrophone: { value in
            currentState.setForceDeviceMicrophone(value)
            statePromise.set(currentState)
        },
        updateHideCameraInGallery: { value in
            currentState.setHideCameraInGallery(!value)
            if !value {
                currentState.setHideCameraPreviewInGallery(false)
            }
            statePromise.set(currentState)
        },
        updateHideCameraPreviewInGallery: { value in
            currentState.setHideCameraPreviewInGallery(!value)
            statePromise.set(currentState)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, ExtraOtherSettingsArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, ExtraOtherSettingsArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Другие", en: "Other")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraOtherSettingsEntries(strings: presentationData.strings, state: state),
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

// MARK: - Translation Service Selection

private enum ExtraOtherTranslationServiceSelectionSection: Int32 {
    case main
}

private enum ExtraOtherTranslationServiceSelectionEntry: ItemListNodeEntry {
    case service(ExtraOtherTranslationService, Bool)
    case info(String)
    
    var section: ItemListSectionId {
        return ExtraOtherTranslationServiceSelectionSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .service(service, _):
            switch service {
            case .telegram:
                return 0
            case .gTranslate:
                return 1
            }
        case .info:
            return 100
        }
    }
    
    static func ==(lhs: ExtraOtherTranslationServiceSelectionEntry, rhs: ExtraOtherTranslationServiceSelectionEntry) -> Bool {
        switch lhs {
        case let .service(lhsService, lhsSelected):
            if case let .service(rhsService, rhsSelected) = rhs {
                return lhsService == rhsService && lhsSelected == rhsSelected
            }
            return false
            
        case let .info(lhsText):
            if case let .info(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        }
    }
    
    static func <(lhs: ExtraOtherTranslationServiceSelectionEntry, rhs: ExtraOtherTranslationServiceSelectionEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraOtherTranslationServiceSelectionArguments
        
        switch self {
        case let .service(service, selected):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: selected ? extraSelectionCheckIcon(color: presentationData.theme.list.itemAccentColor) : extraSelectionEmptyIcon(),
                title: service.title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.selectService(service)
                }
            )
            
        case let .info(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )
        }
    }
}

private final class ExtraOtherTranslationServiceSelectionArguments {
    let selectService: (ExtraOtherTranslationService) -> Void
    
    init(selectService: @escaping (ExtraOtherTranslationService) -> Void) {
        self.selectService = selectService
    }
}

private func extraOtherTranslationServiceSelectionEntries(strings: PresentationStrings, state: ExtraOtherSettingsState) -> [ExtraOtherTranslationServiceSelectionEntry] {
    return [
        .service(.telegram, state.translationService == .telegram),
        .service(.gTranslate, state.translationService == .gTranslate),
        .info(extraString(strings, ru: "Extra будет использовать Google Translate, если Telegram недоступен.", en: "Extra will use Google Translate if Telegram is unavailable."))
    ]
}

private func extraOtherTranslationServiceController(
    context: AccountContext,
    statePromise: ValuePromise<ExtraOtherSettingsState>,
    updateService: @escaping (ExtraOtherTranslationService) -> Void
) -> ViewController {
    let arguments = ExtraOtherTranslationServiceSelectionArguments(
        selectService: { service in
            updateService(service)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, ExtraOtherTranslationServiceSelectionArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, ExtraOtherTranslationServiceSelectionArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Сервис перевода", en: "Translation Service")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraOtherTranslationServiceSelectionEntries(strings: presentationData.strings, state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}

// MARK: - Transcription Service Selection

private enum ExtraOtherTranscriptionServiceSelectionSection: Int32 {
    case main
}

private enum ExtraOtherTranscriptionServiceSelectionEntry: ItemListNodeEntry {
    case service(ExtraOtherTranscriptionService, Bool)
    case info(String)
    
    var section: ItemListSectionId {
        return ExtraOtherTranscriptionServiceSelectionSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .service(service, _):
            switch service {
            case .telegram:
                return 0
            case .apple:
                return 1
            }
        case .info:
            return 100
        }
    }
    
    static func ==(lhs: ExtraOtherTranscriptionServiceSelectionEntry, rhs: ExtraOtherTranscriptionServiceSelectionEntry) -> Bool {
        switch lhs {
        case let .service(lhsService, lhsSelected):
            if case let .service(rhsService, rhsSelected) = rhs {
                return lhsService == rhsService && lhsSelected == rhsSelected
            }
            return false
            
        case let .info(lhsText):
            if case let .info(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        }
    }
    
    static func <(lhs: ExtraOtherTranscriptionServiceSelectionEntry, rhs: ExtraOtherTranscriptionServiceSelectionEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExtraOtherTranscriptionServiceSelectionArguments
        
        switch self {
        case let .service(service, selected):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: selected ? extraSelectionCheckIcon(color: presentationData.theme.list.itemAccentColor) : extraSelectionEmptyIcon(),
                title: service.title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.selectService(service)
                }
            )
            
        case let .info(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )
        }
    }
}

private final class ExtraOtherTranscriptionServiceSelectionArguments {
    let selectService: (ExtraOtherTranscriptionService) -> Void
    
    init(selectService: @escaping (ExtraOtherTranscriptionService) -> Void) {
        self.selectService = selectService
    }
}

private func extraOtherTranscriptionServiceSelectionEntries(strings: PresentationStrings, state: ExtraOtherSettingsState) -> [ExtraOtherTranscriptionServiceSelectionEntry] {
    return [
        .service(.telegram, state.transcriptionService == .telegram),
        .service(.apple, state.transcriptionService == .apple),
        .info(extraString(strings, ru: "Extra будет использовать Apple, если Telegram недоступен.", en: "Extra will use Apple if Telegram is unavailable."))
    ]
}

private func extraOtherTranscriptionServiceController(
    context: AccountContext,
    statePromise: ValuePromise<ExtraOtherSettingsState>,
    updateService: @escaping (ExtraOtherTranscriptionService) -> Void
) -> ViewController {
    let arguments = ExtraOtherTranscriptionServiceSelectionArguments(
        selectService: { service in
            updateService(service)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, ExtraOtherTranscriptionServiceSelectionArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, ExtraOtherTranscriptionServiceSelectionArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(extraString(presentationData.strings, ru: "Сервис транскрибации", en: "Transcription Service")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: extraOtherTranscriptionServiceSelectionEntries(strings: presentationData.strings, state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}
