import Foundation

public enum ExtraOtherTranslationService: String, CaseIterable {
    case telegram
    case gTranslate

    public var title: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .gTranslate:
            return "Google Translate"
        }
    }
}

public enum ExtraOtherTranscriptionService: String, CaseIterable {
    case telegram
    case apple

    public var title: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .apple:
            return "Apple"
        }
    }
}

public struct ExtraOtherSettings: Equatable {
    public var autoTranslate: Bool
    public var translationService: ExtraOtherTranslationService
    public var translationButton: Bool

    public var voiceTranscription: Bool
    public var transcriptionService: ExtraOtherTranscriptionService

    public var forceDeviceMicrophone: Bool

    public var hideCameraInGallery: Bool
    public var hideCameraPreviewInGallery: Bool

    public var automaticProxy: Bool

    public init() {
        let defaults = UserDefaults.standard

        self.autoTranslate = defaults.object(forKey: "extra.other.autoTranslate") as? Bool ?? false

        if let rawValue = defaults.string(forKey: "extra.other.translationService"), let value = ExtraOtherTranslationService(rawValue: rawValue) {
            self.translationService = value
        } else {
            self.translationService = .telegram
        }

        self.translationButton = defaults.object(forKey: "extra.other.translationButton") as? Bool ?? true
        self.voiceTranscription = defaults.object(forKey: "extra.other.voiceTranscription") as? Bool ?? true

        if let rawValue = defaults.string(forKey: "extra.other.transcriptionService"), let value = ExtraOtherTranscriptionService(rawValue: rawValue) {
            self.transcriptionService = value
        } else {
            self.transcriptionService = .apple
        }

        self.forceDeviceMicrophone = defaults.object(forKey: "extra.other.forceDeviceMicrophone") as? Bool ?? false
        self.hideCameraInGallery = defaults.object(forKey: "extra.other.hideCameraInGallery") as? Bool ?? false
        self.hideCameraPreviewInGallery = defaults.object(forKey: "extra.other.hideCameraPreviewInGallery") as? Bool ?? false
        self.automaticProxy = defaults.object(forKey: "extra.other.automaticProxy") as? Bool ?? false
    }

    public static var current: ExtraOtherSettings {
        return ExtraOtherSettings()
    }

    public mutating func setAutoTranslate(_ value: Bool) {
        self.autoTranslate = value
        UserDefaults.standard.set(value, forKey: "extra.other.autoTranslate")
    }

    public mutating func setTranslationService(_ value: ExtraOtherTranslationService) {
        self.translationService = value
        UserDefaults.standard.set(value.rawValue, forKey: "extra.other.translationService")
    }

    public mutating func setTranslationButton(_ value: Bool) {
        self.translationButton = value
        UserDefaults.standard.set(value, forKey: "extra.other.translationButton")
    }

    public mutating func setVoiceTranscription(_ value: Bool) {
        self.voiceTranscription = value
        UserDefaults.standard.set(value, forKey: "extra.other.voiceTranscription")
    }

    public mutating func setTranscriptionService(_ value: ExtraOtherTranscriptionService) {
        self.transcriptionService = value
        UserDefaults.standard.set(value.rawValue, forKey: "extra.other.transcriptionService")
    }

    public mutating func setForceDeviceMicrophone(_ value: Bool) {
        self.forceDeviceMicrophone = value
        UserDefaults.standard.set(value, forKey: "extra.other.forceDeviceMicrophone")
    }

    public mutating func setHideCameraInGallery(_ value: Bool) {
        self.hideCameraInGallery = value
        UserDefaults.standard.set(value, forKey: "extra.other.hideCameraInGallery")
    }

    public mutating func setHideCameraPreviewInGallery(_ value: Bool) {
        self.hideCameraPreviewInGallery = value
        UserDefaults.standard.set(value, forKey: "extra.other.hideCameraPreviewInGallery")
    }

    public mutating func setAutomaticProxy(_ value: Bool) {
        self.automaticProxy = value
        UserDefaults.standard.set(value, forKey: "extra.other.automaticProxy")
    }
}
