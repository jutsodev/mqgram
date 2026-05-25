// MARK: MQGram - Advanced Ghost Mode Settings Controller
// Detailed per-activity ghost mode controls
import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// MARK: - Arguments

private final class MQGramAdvancedGhostArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void

    init(toggleSetting: @escaping (MQGramSettings.Key, Bool) -> Void) {
        self.toggleSetting = toggleSetting
    }
}

// MARK: - Entries

private enum MQGramAdvancedGhostEntry: ItemListNodeEntry {
    case header(Int32, String)
    case toggle(Int32, MQGramSettings.Key, String, String?, Bool)
    case footer(Int32, String)

    var section: ItemListSectionId {
        switch self {
        case .header:
            return 0
        case .toggle:
            return 1
        case .footer:
            return 2
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(id, _):
            return id
        case let .toggle(id, _, _, _, _):
            return id
        case let .footer(id, _):
            return id
        }
    }

    static func ==(lhs: MQGramAdvancedGhostEntry, rhs: MQGramAdvancedGhostEntry) -> Bool {
        switch lhs {
        case let .header(lId, lText):
            if case let .header(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        case let .toggle(lId, lKey, lTitle, lText, lValue):
            if case let .toggle(rId, rKey, rTitle, rText, rValue) = rhs,
               lId == rId, lKey == rKey, lTitle == rTitle, lText == rText, lValue == rValue { return true } else { return false }
        case let .footer(lId, lText):
            if case let .footer(rId, rText) = rhs, lId == rId, lText == rText { return true } else { return false }
        }
    }

    static func <(lhs: MQGramAdvancedGhostEntry, rhs: MQGramAdvancedGhostEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramAdvancedGhostArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .toggle(_, key, title, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { newValue in
                    args.toggleSetting(key, newValue)
                }
            )
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

// MARK: - Entry Generation

private func mqgramAdvancedGhostEntries(settings: MQGramSettings, strings: PresentationStrings) -> [MQGramAdvancedGhostEntry] {
    let detailedTexts = mqgramDetailedTexts(strings.baseLanguageCode)
    var entries: [MQGramAdvancedGhostEntry] = []
    var id: Int32 = 0

    // Header
    let isRu = strings.baseLanguageCode.lowercased().hasPrefix("ru")
    let headerText = isRu ? "Детальные настройки активностей" : "Detailed Activity Settings"
    entries.append(.header(id, headerText)); id += 1

    // Typing text
    entries.append(.toggle(id, .ghostTypingText, detailedTexts.ghostTypingTextTitle, detailedTexts.ghostTypingTextText, settings.ghostTypingText)); id += 1

    // Recording voice
    entries.append(.toggle(id, .ghostRecordingVoice, detailedTexts.ghostRecordingVoiceTitle, detailedTexts.ghostRecordingVoiceText, settings.ghostRecordingVoice)); id += 1

    // Uploading voice
    entries.append(.toggle(id, .ghostUploadingVoice, detailedTexts.ghostUploadingVoiceTitle, detailedTexts.ghostUploadingVoiceText, settings.ghostUploadingVoice)); id += 1

    // Recording video
    entries.append(.toggle(id, .ghostRecordingVideo, detailedTexts.ghostRecordingVideoTitle, detailedTexts.ghostRecordingVideoText, settings.ghostRecordingVideo)); id += 1

    // Uploading video
    entries.append(.toggle(id, .ghostUploadingVideo, detailedTexts.ghostUploadingVideoTitle, detailedTexts.ghostUploadingVideoText, settings.ghostUploadingVideo)); id += 1

    // Uploading photo
    entries.append(.toggle(id, .ghostUploadingPhoto, detailedTexts.ghostUploadingPhotoTitle, detailedTexts.ghostUploadingPhotoText, settings.ghostUploadingPhoto)); id += 1

    // Uploading file
    entries.append(.toggle(id, .ghostUploadingFile, detailedTexts.ghostUploadingFileTitle, detailedTexts.ghostUploadingFileText, settings.ghostUploadingFile)); id += 1

    // Choosing location
    entries.append(.toggle(id, .ghostChoosingLocation, detailedTexts.ghostChoosingLocationTitle, detailedTexts.ghostChoosingLocationText, settings.ghostChoosingLocation)); id += 1

    // Choosing contact
    entries.append(.toggle(id, .ghostChoosingContact, detailedTexts.ghostChoosingContactTitle, detailedTexts.ghostChoosingContactText, settings.ghostChoosingContact)); id += 1

    // Playing game
    entries.append(.toggle(id, .ghostPlayingGame, detailedTexts.ghostPlayingGameTitle, detailedTexts.ghostPlayingGameText, settings.ghostPlayingGame)); id += 1

    // Recording round video
    entries.append(.toggle(id, .ghostRecordingRound, detailedTexts.ghostRecordingRoundTitle, detailedTexts.ghostRecordingRoundText, settings.ghostRecordingRound)); id += 1

    // Uploading round video
    entries.append(.toggle(id, .ghostUploadingRound, detailedTexts.ghostUploadingRoundTitle, detailedTexts.ghostUploadingRoundText, settings.ghostUploadingRound)); id += 1

    // Speaking in group call
    entries.append(.toggle(id, .ghostSpeakingInGroupCall, detailedTexts.ghostSpeakingInGroupCallTitle, detailedTexts.ghostSpeakingInGroupCallText, settings.ghostSpeakingInGroupCall)); id += 1

    // Choosing sticker
    entries.append(.toggle(id, .ghostChoosingSticker, detailedTexts.ghostChoosingStickerTitle, detailedTexts.ghostChoosingStickerText, settings.ghostChoosingSticker)); id += 1

    // Emoji interaction
    entries.append(.toggle(id, .ghostEmojiInteraction, detailedTexts.ghostEmojiInteractionTitle, detailedTexts.ghostEmojiInteractionText, settings.ghostEmojiInteraction)); id += 1

    // Emoji reaction
    entries.append(.toggle(id, .ghostEmojiReaction, detailedTexts.ghostEmojiReactionTitle, detailedTexts.ghostEmojiReactionText, settings.ghostEmojiReaction)); id += 1

    // Footer
    let footerText = isRu 
        ? "Эти настройки позволяют точно контролировать, какие индикаторы активности отправляются собеседникам. Главный переключатель 'Режим призрака' блокирует все активности сразу."
        : "These settings allow precise control over which activity indicators are sent to your contacts. The main 'Ghost Mode' toggle blocks all activities at once."
    entries.append(.footer(9999, footerText))

    return entries
}

// MARK: - Controller

public func mqgramAdvancedGhostController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    let arguments = MQGramAdvancedGhostArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            updatePromise.set(true)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRu = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
        let title = isRu ? "Детальные настройки" : "Advanced Settings"

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )

        let entries = mqgramAdvancedGhostEntries(settings: MQGramSettings.shared, strings: presentationData.strings)

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
