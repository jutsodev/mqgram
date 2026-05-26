// MARK: MQGram - Deleted Message Visualizer
// Comprehensive visual system for deleted messages with icons, overlays, and indicators
import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox

/// Visual configuration for deleted messages
public struct MQDeletedMessageVisualConfig {
    /// Show trash icon next to deleted messages
    public var showTrashIcon: Bool
    
    /// Use red color for trash icon
    public var useRedIcon: Bool
    
    /// Show "Deleted" label under message
    public var showDeletedLabel: Bool
    
    /// Apply semi-transparent overlay to deleted messages
    public var applyOverlay: Bool
    
    /// Overlay opacity (0.0 - 1.0)
    public var overlayOpacity: CGFloat
    
    /// Show timestamp when message was deleted
    public var showDeletedTimestamp: Bool
    
    /// Show "View Original" button for edited messages
    public var showViewOriginalButton: Bool
    
    /// Icon size
    public var iconSize: CGSize
    
    /// Icon position offset
    public var iconOffset: CGPoint
    
    public init() {
        self.showTrashIcon = true
        self.useRedIcon = true
        self.showDeletedLabel = true
        self.applyOverlay = true
        self.overlayOpacity = 0.15
        self.showDeletedTimestamp = false
        self.showViewOriginalButton = true
        self.iconSize = CGSize(width: 18.0, height: 18.0)
        self.iconOffset = CGPoint(x: 4.0, y: 2.0)
    }
    
    /// Load configuration from UserDefaults
    public static func loadFromSettings() -> MQDeletedMessageVisualConfig {
        var config = MQDeletedMessageVisualConfig()
        config.showTrashIcon = UserDefaults.standard.bool(forKey: "MQGram.antiRevoke")
        config.useRedIcon = UserDefaults.standard.bool(forKey: "MQGram.redDeleteIcon")
        config.showDeletedLabel = UserDefaults.standard.bool(forKey: "MQGram.showDeletedLabel") || config.showTrashIcon
        config.applyOverlay = UserDefaults.standard.bool(forKey: "MQGram.deletedMessageOverlay") || config.showTrashIcon
        return config
    }
}

/// Manages visual representation of deleted messages
public final class MQDeletedMessageVisualizer {
    
    /// Shared instance
    public static let shared = MQDeletedMessageVisualizer()
    
    /// Current visual configuration
    public var config: MQDeletedMessageVisualConfig
    
    private init() {
        self.config = MQDeletedMessageVisualConfig.loadFromSettings()
    }
    
    /// Reload configuration from settings
    public func reloadConfig() {
        self.config = MQDeletedMessageVisualConfig.loadFromSettings()
    }
    
    // MARK: - Icon Generation
    
    /// Generate trash icon with specified color
    public func generateTrashIcon(color: UIColor, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Draw trash can body
            let bodyRect = CGRect(
                x: size.width * 0.2,
                y: size.height * 0.35,
                width: size.width * 0.6,
                height: size.height * 0.55
            )
            
            color.setFill()
            let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: 2.0)
            bodyPath.fill()
            
            // Draw trash can lid
            let lidRect = CGRect(
                x: size.width * 0.15,
                y: size.height * 0.25,
                width: size.width * 0.7,
                height: size.height * 0.12
            )
            let lidPath = UIBezierPath(roundedRect: lidRect, cornerRadius: 1.5)
            lidPath.fill()
            
            // Draw handle
            let handleRect = CGRect(
                x: size.width * 0.35,
                y: size.height * 0.1,
                width: size.width * 0.3,
                height: size.height * 0.18
            )
            let handlePath = UIBezierPath()
            handlePath.move(to: CGPoint(x: handleRect.minX, y: handleRect.maxY))
            handlePath.addLine(to: CGPoint(x: handleRect.minX, y: handleRect.minY + 3))
            handlePath.addQuadCurve(
                to: CGPoint(x: handleRect.maxX, y: handleRect.minY + 3),
                controlPoint: CGPoint(x: handleRect.midX, y: handleRect.minY - 2)
            )
            handlePath.addLine(to: CGPoint(x: handleRect.maxX, y: handleRect.maxY))
            handlePath.lineWidth = 1.5
            color.setStroke()
            handlePath.stroke()
            
            // Draw vertical lines inside trash can
            let lineSpacing = bodyRect.width / 4.0
            for i in 1...2 {
                let lineX = bodyRect.minX + lineSpacing * CGFloat(i)
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: lineX, y: bodyRect.minY + 3))
                linePath.addLine(to: CGPoint(x: lineX, y: bodyRect.maxY - 3))
                linePath.lineWidth = 1.0
                UIColor.white.withAlphaComponent(0.6).setStroke()
                linePath.stroke()
            }
        }
    }
    
    /// Get trash icon color based on configuration
    public func getTrashIconColor() -> UIColor {
        if config.useRedIcon {
            return UIColor(red: 0.95, green: 0.20, blue: 0.20, alpha: 1.0)
        } else {
            return UIColor(white: 0.5, alpha: 0.8)
        }
    }
    
    // MARK: - Label Generation
    
    /// Generate "Deleted" label text
    public func getDeletedLabelText(languageCode: String) -> String {
        if languageCode.lowercased().hasPrefix("ru") {
            return "Удалено"
        }
        return "Deleted"
    }
    
    /// Generate deleted timestamp text
    public func getDeletedTimestampText(deletedAt: Date, languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: deletedAt)
        
        if languageCode.lowercased().hasPrefix("ru") {
            return "Удалено: \(dateString)"
        }
        return "Deleted: \(dateString)"
    }
    
    // MARK: - Overlay Generation
    
    /// Generate semi-transparent overlay for deleted message background
    public func generateOverlayColor(isDark: Bool) -> UIColor {
        let baseColor: UIColor
        if isDark {
            baseColor = UIColor.white
        } else {
            baseColor = UIColor.black
        }
        return baseColor.withAlphaComponent(config.overlayOpacity)
    }
    
    // MARK: - Position Calculation
    
    /// Calculate icon position relative to message bubble
    public func calculateIconPosition(
        bubbleFrame: CGRect,
        iconSize: CGSize,
        isIncoming: Bool
    ) -> CGPoint {
        let x: CGFloat
        if isIncoming {
            // Place icon to the left of incoming message
            x = max(2.0, bubbleFrame.minX - iconSize.width - config.iconOffset.x)
        } else {
            // Place icon to the right of outgoing message
            x = bubbleFrame.maxX + config.iconOffset.x
        }
        
        // Place icon at the bottom of the bubble
        let y = bubbleFrame.maxY - iconSize.height - config.iconOffset.y
        
        return CGPoint(x: x, y: y)
    }
    
    /// Calculate label position relative to message bubble
    public func calculateLabelPosition(
        bubbleFrame: CGRect,
        labelSize: CGSize,
        isIncoming: Bool
    ) -> CGPoint {
        let x: CGFloat
        if isIncoming {
            x = bubbleFrame.minX + 8.0
        } else {
            x = bubbleFrame.maxX - labelSize.width - 8.0
        }
        
        let y = bubbleFrame.maxY + 2.0
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Message Analysis
    
    /// Check if message should show deleted indicators
    public func shouldShowDeletedIndicators(message: Message) -> Bool {
        guard config.showTrashIcon else { return false }
        return MQDeletedMessages.isMessageDeleted(message)
    }
    
    /// Get deleted message info for display
    public func getDeletedMessageInfo(message: Message) -> MQDeletedMessageInfo? {
        guard shouldShowDeletedIndicators(message: message) else { return nil }
        return MQDeletedMessageInfo(message: message)
    }
    
    // MARK: - Statistics
    
    private var displayedDeletedMessagesCount: Int = 0
    
    /// Increment displayed deleted messages counter
    public func incrementDisplayedCount() {
        displayedDeletedMessagesCount += 1
        UserDefaults.standard.set(displayedDeletedMessagesCount, forKey: "MQGram.displayedDeletedMessagesCount")
    }
    
    /// Get total displayed deleted messages count
    public func getDisplayedCount() -> Int {
        return UserDefaults.standard.integer(forKey: "MQGram.displayedDeletedMessagesCount")
    }
    
    /// Reset statistics
    public func resetStatistics() {
        displayedDeletedMessagesCount = 0
        UserDefaults.standard.removeObject(forKey: "MQGram.displayedDeletedMessagesCount")
    }
}

// MARK: - ASDisplayNode Extension for Deleted Message Visualization

extension ASDisplayNode {
    /// Add deleted message overlay to node
    public func mqAddDeletedOverlay(config: MQDeletedMessageVisualConfig, isDark: Bool) {
        let overlayColor = MQDeletedMessageVisualizer.shared.generateOverlayColor(isDark: isDark)
        self.backgroundColor = overlayColor
    }
    
    /// Remove deleted message overlay from node
    public func mqRemoveDeletedOverlay() {
        self.backgroundColor = nil
    }
}

// MARK: - Deleted Message Icon Node

public final class MQDeletedMessageIconNode: ASDisplayNode {
    private let imageNode: ASImageNode
    private var config: MQDeletedMessageVisualConfig
    
    public init(config: MQDeletedMessageVisualConfig) {
        self.config = config
        self.imageNode = ASImageNode()
        self.imageNode.displaysAsynchronously = false
        
        super.init()
        
        self.addSubnode(self.imageNode)
        self.updateIcon()
    }
    
    private func updateIcon() {
        let color = MQDeletedMessageVisualizer.shared.getTrashIconColor()
        self.imageNode.image = MQDeletedMessageVisualizer.shared.generateTrashIcon(
            color: color,
            size: config.iconSize
        )
    }
    
    public func updateConfig(_ newConfig: MQDeletedMessageVisualConfig) {
        self.config = newConfig
        self.updateIcon()
    }
    
    override public func layout() {
        super.layout()
        self.imageNode.frame = CGRect(origin: .zero, size: config.iconSize)
    }
    
    override public func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return config.iconSize
    }
}

// MARK: - Deleted Message Label Node

public final class MQDeletedMessageLabelNode: ASDisplayNode {
    private var config: MQDeletedMessageVisualConfig
    private var languageCode: String
    public let textNode = ASTextNode()
    
    public init(config: MQDeletedMessageVisualConfig, languageCode: String, deletedAt: Date? = nil) {
        self.config = config
        self.languageCode = languageCode
        
        super.init()
        
        self.isUserInteractionEnabled = false
        self.textNode.displaysAsynchronously = false
        self.addSubnode(self.textNode)
        
        let text: String
        if let deletedAt = deletedAt, config.showDeletedTimestamp {
            text = MQDeletedMessageVisualizer.shared.getDeletedTimestampText(
                deletedAt: deletedAt,
                languageCode: languageCode
            )
        } else {
            text = MQDeletedMessageVisualizer.shared.getDeletedLabelText(languageCode: languageCode)
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11.0, weight: .medium),
            .foregroundColor: UIColor(white: 0.5, alpha: 0.8)
        ]
        
        self.textNode.attributedText = NSAttributedString(string: text, attributes: attributes)
    }
    
    override public func layout() {
        super.layout()
        let textSize = self.textNode.measure(self.bounds.size)
        self.textNode.frame = CGRect(origin: CGPoint(x: (self.bounds.width - textSize.width) / 2, y: (self.bounds.height - textSize.height) / 2), size: textSize)
    }
    
    override public func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return self.textNode.measure(constrainedSize)
    }
}

// MARK: - Helper Extensions

extension Message {
    /// Check if this message is marked as deleted by MQGram
    public var mqIsDeleted: Bool {
        return MQDeletedMessages.isMessageDeleted(self)
    }
    
    /// Get deleted message visual info
    public var mqDeletedInfo: MQDeletedMessageInfo? {
        return MQDeletedMessageVisualizer.shared.getDeletedMessageInfo(message: self)
    }
}
