// MARK: MQGram - Video Background Controller
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

private final class MQGramVideoBackgroundNode: ItemListControllerNode {
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let videoPreviewNode = ASDisplayNode()
    
    override init(controller: ItemListViewController) {
        super.init(controller: controller)
    }
    
    deinit {
        videoPlayer?.pause()
    }
    
    func playVideo(at path: String) {
        guard FileManager.default.fileExists(atPath: path) else { return }
        let url = URL(fileURLWithPath: path)
        videoPlayer = AVPlayer(url: url)
        videoPlayer?.play()
    }
}

public func mqgramVideoBackgroundController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise<MQGramVideoBackgroundState>(MQGramVideoBackgroundState(), ignoreRepeated: true)
    let stateValue = Atomic<MQGramVideoBackgroundState>(MQGramVideoBackgroundState())
    
    let updateState: ((MQGramVideoBackgroundState) -> MQGramVideoBackgroundState) -> Void = { f in
        stateValue.modify { f($0) }
        statePromise.set(stateValue.with { $0 })
    }
    
    var dismissImpl: (() -> Void)?
    
    let arguments = MQGramVideoBackgroundArguments(
        toggleVideoBackground: { enabled in
            MQGramSettings.shared.setBool(enabled, for: .videoBackground)
            UserDefaults.standard.set(enabled, forKey: "MQGram.videoBackground")
            updateState { state in
                var updated = state
                updated.videoBackgroundEnabled = enabled
                return updated
            }
        },
        selectVideo: { [weak context] in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.allowsEditing = false
            picker.delegate = nil
            
            // In real implementation, would present picker
            // For now, just load from documents
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            let videoPath = documentsDirectory.appendingPathComponent("mqgram_background.mp4").path
            
            if FileManager.default.fileExists(atPath: videoPath) {
                MQGramSettings.shared.set(videoPath, for: .videoBackgroundPath)
                UserDefaults.standard.set(videoPath, forKey: "MQGram.videoBackgroundPath")
                updateState { state in
                    var updated = state
                    updated.videoBackgroundPath = videoPath
                    return updated
                }
            }
        },
        clearBackground: {
            MQGramSettings.shared.set("", for: .videoBackgroundPath)
            UserDefaults.standard.set("", forKey: "MQGram.videoBackgroundPath")
            updateState { state in
                var updated = state
                updated.videoBackgroundPath = ""
                return updated
            }
        }
    )
    
    let signal = statePromise.get()
    |> map { state -> [ItemListNodeEntry] in
        var entries: [ItemListNodeEntry] = []
        var id = 0
        
        entries.append(.info(id, "🎬 Видеофон чата (Video Background)\n\nВыбери видео из галереи для фона в чатах. Видео будет проигрываться в полупрозрачном оверлее.")); id += 1
        entries.append(.toggle(id, .videoBackground, "Видеофон включен", state.videoBackgroundEnabled, { value in
            arguments.toggleVideoBackground(value)
        })); id += 1
        
        if state.videoBackgroundEnabled {
            entries.append(.action(id, "📁 Выбрать видео из галереи", { arguments.selectVideo() })); id += 1
            
            if !state.videoBackgroundPath.isEmpty {
                entries.append(.info(id, "✅ Видео выбрано\n\(state.videoBackgroundPath)")); id += 1
                entries.append(.action(id, "❌ Удалить фон", { arguments.clearBackground() })); id += 1
            } else {
                entries.append(.info(id, "⚠️ Видео не выбрано\n\nКликни выше чтобы выбрать видео из галереи")); id += 1
            }
        }
        
        entries.append(.footer(id, "💡 Совет: Используй видео не более 10MB для лучшей производительности")); id += 1
        
        return entries
    }
    
    let controller = ItemListViewController(context: context, state: ItemListControllerState(theme: context.sharedContext.currentPresentationData.with { $0.theme }, title: .text("Видеофон"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: "Назад"), animateChanges: false), tabBarItem: nil, sections: [
        ItemListSection(id: 0, header: nil, footer: nil, items: [])
    ])
    
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    
    return controller
}

private struct MQGramVideoBackgroundState: Equatable {
    var videoBackgroundEnabled: Bool = MQGramSettings.shared.videoBackground
    var videoBackgroundPath: String = MQGramSettings.shared.videoBackgroundPath
}

private struct MQGramVideoBackgroundArguments {
    let toggleVideoBackground: (Bool) -> Void
    let selectVideo: () -> Void
    let clearBackground: () -> Void
}

// MARK: - ChatHistoryNode Video Background Extension
extension ChatHistoryNode {
    func applyVideoBackground() {
        guard MQGramSettings.shared.videoBackground else { return }
        let backgroundPath = MQGramSettings.shared.videoBackgroundPath
        guard !backgroundPath.isEmpty, FileManager.default.fileExists(atPath: backgroundPath) else { return }
        
        let url = URL(fileURLWithPath: backgroundPath)
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.opacity = 0.15 // Полупрозрачность для читаемости текста
        
        // Add to background
        if let layer = self.layer {
            layer.insertSublayer(playerLayer, at: 0)
            playerLayer.frame = layer.bounds
            
            // Loop video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
            
            player.play()
        }
    }
}
