import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import Photos
import AVFoundation

private enum MQGramEntry: ItemListNodeEntry {
    case header(Int32, String)
    case info(Int32, String)
    case toggle(Int32, MQGramSettings.Key, String, Bool)
    case action(Int32, String)
    case footer(Int32, String)

    var section: ItemListSectionId {
        switch self {
        case .header:
            return 0
        case .info, .toggle, .action:
            return 1
        case .footer:
            return 2
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(id, _):      return id
        case let .info(id, _):        return id
        case let .toggle(id, _, _, _): return id
        case let .action(id, _):      return id
        case let .footer(id, _):      return id
        }
    }

    static func ==(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        switch lhs {
        case let .header(lId, lText):
            if case let .header(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        case let .info(lId, lText):
            if case let .info(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        case let .toggle(lId, lKey, lTitle, lValue):
            if case let .toggle(rId, rKey, rTitle, rValue) = rhs, lId == rId, lKey == rKey, lTitle == rTitle, lValue == rValue { return true }
            return false
        case let .action(lId, lText):
            if case let .action(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        case let .footer(lId, lText):
            if case let .footer(rId, rText) = rhs, lId == rId, lText == rText { return true }
            return false
        }
    }

    static func <(lhs: MQGramEntry, rhs: MQGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! MQGramArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .info(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        case let .toggle(_, key, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, text: nil, value: value, sectionId: self.section, style: .blocks, updated: { newValue in
                args.toggleSetting(key, newValue)
            })
        case let .action(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.pressedButton()
            })
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .markdown(text), sectionId: self.section)
        }
    }
}

private struct MQGramArguments {
    let toggleSetting: (MQGramSettings.Key, Bool) -> Void
    let pressedButton: () -> Void
}

private enum MQGramVideoBackgroundButtonAction {
    case selectVideo
    case clearBackground
}

public func mqgramVideoBackgroundController(context: AccountContext) -> ViewController {
    let updatePromise = ValuePromise<Bool>(true, ignoreRepeated: false)

    var buttonAction: MQGramVideoBackgroundButtonAction = .selectVideo

    let arguments = MQGramArguments(
        toggleSetting: { key, value in
            MQGramSettings.shared.setBool(value, for: key)
            updatePromise.set(true)
        },
        pressedButton: {
            switch buttonAction {
            case .selectVideo:
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                let videoPath = documentsDirectory.appendingPathComponent("mqgram_background.mp4").path
                if FileManager.default.fileExists(atPath: videoPath) {
                    MQGramSettings.shared.videoBackgroundPath = videoPath
                    UserDefaults.standard.set(videoPath, forKey: "MQGram.videoBackgroundPath")
                    updatePromise.set(true)
                }
            case .clearBackground:
                MQGramSettings.shared.videoBackgroundPath = ""
                UserDefaults.standard.set("", forKey: "MQGram.videoBackgroundPath")
                updatePromise.set(true)
            }
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, updatePromise.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = MQGramSettings.shared
        let strings = presentationData.strings

        var entries: [MQGramEntry] = []
        var id: Int32 = 0

        entries.append(.info(id, "Выбери видео из галереи для фона в чатах. Видео будет проигрываться в полупрозрачном оверлее.")); id += 1
        entries.append(.toggle(id, .videoBackground, "Видеофон включен", settings.videoBackground)); id += 1

        if settings.videoBackground {
            buttonAction = .selectVideo
            entries.append(.action(id, "Выбрать видео из галереи")); id += 1

            if !settings.videoBackgroundPath.isEmpty {
                entries.append(.info(id, "Видео выбрано\n\(settings.videoBackgroundPath)")); id += 1
                buttonAction = .clearBackground
                entries.append(.action(id, "Удалить фон")); id += 1
            } else {
                entries.append(.info(id, "Видео не выбрано. Нажми выше чтобы выбрать видео из галереи")); id += 1
            }
        }

        entries.append(.footer(id, "Совет: Используй видео не более 10MB для лучшей производительности")); id += 1

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Видеофон"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: strings.Common_Back)
        )

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
