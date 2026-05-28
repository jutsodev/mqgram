// MARK: MQGram - Video Background Integration for ChatHistoryNode
import Foundation
import UIKit
import AVFoundation

// Extension to apply video background in chat
public class MQGramVideoBackgroundManager {
    static let shared = MQGramVideoBackgroundManager()
    
    private var activePlayers: [AVPlayer] = []
    private var activePlayerLayers: [AVPlayerLayer] = []
    
    /// Apply video background to a view
    public func applyVideoBackground(to view: UIView) {
        // Check if feature is enabled
        guard MQGramSettings.shared.videoBackground else {
            removeVideoBackground(from: view)
            return
        }
        
        let backgroundPath = MQGramSettings.shared.videoBackgroundPath
        guard !backgroundPath.isEmpty else {
            removeVideoBackground(from: view)
            return
        }
        
        guard FileManager.default.fileExists(atPath: backgroundPath) else {
            removeVideoBackground(from: view)
            return
        }
        
        // Remove old background if exists
        removeVideoBackground(from: view)
        
        // Create video player
        let url = URL(fileURLWithPath: backgroundPath)
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        
        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.opacity = 0.12 // Subtle opacity for text readability
        
        // Add to view's layer as background
        view.layer.insertSublayer(playerLayer, at: 0)
        playerLayer.frame = view.bounds
        playerLayer.zPosition = -1
        
        // Setup looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        // Store references to prevent deallocation
        view.layer.setValue(player, forKey: "mqgram_bg_player")
        view.layer.setValue(playerLayer, forKey: "mqgram_bg_layer")
        activePlayers.append(player)
        activePlayerLayers.append(playerLayer)
        
        // Start playback
        player.play()
    }
    
    /// Remove video background from view
    public func removeVideoBackground(from view: UIView) {
        if let playerLayer = view.layer.value(forKey: "mqgram_bg_layer") as? AVPlayerLayer {
            playerLayer.removeFromSuperlayer()
        }
        
        if let player = view.layer.value(forKey: "mqgram_bg_player") as? AVPlayer {
            player.pause()
            NotificationCenter.default.removeObserver(player)
            
            // Remove from active players
            if let index = activePlayers.firstIndex(where: { $0 === player }) {
                activePlayers.remove(at: index)
            }
        }
        
        view.layer.setValue(nil, forKey: "mqgram_bg_player")
        view.layer.setValue(nil, forKey: "mqgram_bg_layer")
    }
    
    /// Clean up all active players
    public func cleanup() {
        activePlayers.forEach { $0.pause() }
        activePlayerLayers.forEach { $0.removeFromSuperlayer() }
        activePlayers.removeAll()
        activePlayerLayers.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Usage in ChatController
extension ChatController {
    /// Apply video background when view appears
    public func applyMQGramVideoBackground() {
        MQGramVideoBackgroundManager.shared.applyVideoBackground(to: self.view)
    }
    
    /// Remove video background when view disappears
    public func removeMQGramVideoBackground() {
        MQGramVideoBackgroundManager.shared.removeVideoBackground(from: self.view)
    }
}
