// MARK: MQGram - Passcode Entry Controller
import Foundation
import UIKit
import Display
import AccountContext
import TelegramPresentationData

public enum MQGramPasscodeEntryMode {
    case set
    case verify
    case change
}

public final class MQGramPasscodeEntryController: ViewController {
    private let context: AccountContext
    private let mode: MQGramPasscodeEntryMode
    private let passcodeType: MQGramPasscodeManager.PasscodeType
    private let completion: (Bool) -> Void

    private var containerNode: MQGramPasscodeEntryNode?

    public init(context: AccountContext, mode: MQGramPasscodeEntryMode, passcodeType: MQGramPasscodeManager.PasscodeType, completion: @escaping (Bool) -> Void) {
        self.context = context
        self.mode = mode
        self.passcodeType = passcodeType
        self.completion = completion

        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData))

        switch mode {
        case .set:
            self.title = "Установить код-пароль"
        case .verify:
            self.title = "Введите код-пароль"
        case .change:
            self.title = "Новый код-пароль"
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadDisplayNode() {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        self.containerNode = MQGramPasscodeEntryNode(
            presentationData: presentationData,
            mode: self.mode,
            passcodeType: self.passcodeType,
            completion: { [weak self] success in
                self?.completion(success)
                if success {
                    self?.dismissSelf()
                }
            }
        )
        self.displayNode = self.containerNode!
    }

    private func dismissSelf() {
        if let navigationController = self.navigationController as? NavigationController {
            navigationController.popViewController(animated: true)
        }
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.containerNode?.containerLayoutUpdated(layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }
}

final class MQGramPasscodeEntryNode: ViewControllerTracingNode {
    private let presentationData: PresentationData
    private let mode: MQGramPasscodeEntryMode
    private let passcodeType: MQGramPasscodeManager.PasscodeType
    private let completionHandler: (Bool) -> Void

    private var enteredPasscode: String = ""
    private var firstPasscode: String?
    private var isConfirming: Bool = false

    private let promptLabel: ImmediateTextNode
    private let errorLabel: ImmediateTextNode
    private var dotViews: [UIView] = []
    private var digitButtons: [UIButton] = []
    private let deleteBtn: UIButton

    private let maxDigits: Int

    init(presentationData: PresentationData, mode: MQGramPasscodeEntryMode, passcodeType: MQGramPasscodeManager.PasscodeType, completion: @escaping (Bool) -> Void) {
        self.presentationData = presentationData
        self.mode = mode
        self.passcodeType = passcodeType
        self.completionHandler = completion

        switch passcodeType {
        case .fourDigit:
            self.maxDigits = 4
        case .sixDigit:
            self.maxDigits = 6
        case .custom:
            self.maxDigits = 20
        }

        self.promptLabel = ImmediateTextNode()
        self.promptLabel.maximumNumberOfLines = 2
        self.promptLabel.textAlignment = .center

        self.errorLabel = ImmediateTextNode()
        self.errorLabel.maximumNumberOfLines = 1
        self.errorLabel.textAlignment = .center

        self.deleteBtn = UIButton(type: .system)

        super.init()

        self.backgroundColor = presentationData.theme.list.plainBackgroundColor

        self.addSubnode(self.promptLabel)
        self.addSubnode(self.errorLabel)

        for i in 0..<maxDigits {
            let dot = UIView()
            dot.layer.cornerRadius = 7
            dot.layer.borderWidth = 1.5
            dot.layer.borderColor = presentationData.theme.list.itemPrimaryTextColor.cgColor
            dot.backgroundColor = .clear
            dot.tag = i
            self.view.addSubview(dot)
            self.dotViews.append(dot)
        }

        let textColor = presentationData.theme.list.itemPrimaryTextColor
        let bgColor = presentationData.theme.list.itemBlocksBackgroundColor

        for i in 0...9 {
            let button = UIButton(type: .system)
            button.setTitle("\(i)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .light)
            button.setTitleColor(textColor, for: .normal)
            button.backgroundColor = bgColor
            button.tag = i
            button.addTarget(self, action: #selector(self.digitPressed(_:)), for: .touchUpInside)
            self.view.addSubview(button)
            self.digitButtons.append(button)
        }

        self.deleteBtn.setTitle("⌫", for: .normal)
        self.deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        self.deleteBtn.setTitleColor(textColor, for: .normal)
        self.deleteBtn.addTarget(self, action: #selector(self.deletePressed), for: .touchUpInside)
        self.view.addSubview(self.deleteBtn)

        updatePrompt()
        updateDots()
    }

    private func updatePrompt() {
        let text: String
        if isConfirming {
            text = "Повторите код-пароль"
        } else {
            switch mode {
            case .set:
                text = "Введите новый код-пароль"
            case .verify:
                text = "Введите код-пароль"
            case .change:
                text = "Введите новый код-пароль"
            }
        }
        self.promptLabel.attributedText = NSAttributedString(
            string: text,
            font: Font.regular(17),
            textColor: self.presentationData.theme.list.itemPrimaryTextColor
        )
    }

    private func updateDots() {
        for (i, dot) in dotViews.enumerated() {
            if i < enteredPasscode.count {
                dot.backgroundColor = presentationData.theme.list.itemPrimaryTextColor
            } else {
                dot.backgroundColor = .clear
            }
        }
    }

    private func showError(_ text: String) {
        self.errorLabel.attributedText = NSAttributedString(
            string: text,
            font: Font.regular(14),
            textColor: UIColor(rgb: 0xFF453A)
        )
        if let layout = self.validLayout {
            self.containerLayoutUpdated(layout.0, navigationBarHeight: layout.1, transition: .immediate)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.errorLabel.attributedText = nil
            if let layout = self?.validLayout {
                self?.containerLayoutUpdated(layout.0, navigationBarHeight: layout.1, transition: .immediate)
            }
        }
    }

    @objc private func digitPressed(_ sender: UIButton) {
        guard enteredPasscode.count < maxDigits else { return }
        enteredPasscode += "\(sender.tag)"
        updateDots()

        if enteredPasscode.count == maxDigits {
            processEntry()
        }
    }

    @objc private func deletePressed() {
        guard !enteredPasscode.isEmpty else { return }
        enteredPasscode = String(enteredPasscode.dropLast())
        updateDots()
    }

    private func processEntry() {
        switch mode {
        case .set, .change:
            if isConfirming {
                if enteredPasscode == firstPasscode {
                    MQGramPasscodeManager.shared.setPasscode(enteredPasscode, type: passcodeType)
                    completionHandler(true)
                } else {
                    showError("Коды не совпадают")
                    enteredPasscode = ""
                    firstPasscode = nil
                    isConfirming = false
                    updatePrompt()
                    updateDots()
                }
            } else {
                firstPasscode = enteredPasscode
                enteredPasscode = ""
                isConfirming = true
                updatePrompt()
                updateDots()
            }
        case .verify:
            if MQGramPasscodeManager.shared.verifyPasscode(enteredPasscode) {
                MQGramPasscodeManager.shared.unlock()
                completionHandler(true)
            } else {
                showError("Неверный код-пароль")
                enteredPasscode = ""
                updateDots()
            }
        }
    }

    private var validLayout: (ContainerViewLayout, CGFloat)?

    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.validLayout = (layout, navigationBarHeight)

        let bounds = CGRect(origin: .zero, size: layout.size)

        let dotSize: CGFloat = 14
        let dotSpacing: CGFloat = 18
        let totalDotsWidth = CGFloat(maxDigits) * dotSize + CGFloat(maxDigits - 1) * dotSpacing
        let dotsStartX = (bounds.width - totalDotsWidth) / 2

        let promptSize = self.promptLabel.updateLayout(CGSize(width: bounds.width - 40, height: 60))
        let promptY = navigationBarHeight + 40
        self.promptLabel.frame = CGRect(origin: CGPoint(x: (bounds.width - promptSize.width) / 2, y: promptY), size: promptSize)

        let dotsY = promptY + promptSize.height + 30
        for (i, dot) in dotViews.enumerated() {
            dot.frame = CGRect(x: dotsStartX + CGFloat(i) * (dotSize + dotSpacing), y: dotsY, width: dotSize, height: dotSize)
        }

        let errorSize = self.errorLabel.updateLayout(CGSize(width: bounds.width - 40, height: 30))
        self.errorLabel.frame = CGRect(origin: CGPoint(x: (bounds.width - errorSize.width) / 2, y: dotsY + dotSize + 15), size: errorSize)

        let buttonSize: CGFloat = 75
        let buttonSpacing: CGFloat = 20
        let gridWidth = 3 * buttonSize + 2 * buttonSpacing
        let gridStartX = (bounds.width - gridWidth) / 2
        let gridStartY = dotsY + dotSize + 60

        // Buttons 1-9 (digitButtons[1..9])
        for i in 1...9 {
            let row = (i - 1) / 3
            let col = (i - 1) % 3
            let x = gridStartX + CGFloat(col) * (buttonSize + buttonSpacing)
            let y = gridStartY + CGFloat(row) * (buttonSize + buttonSpacing)
            let button = digitButtons[i]
            button.frame = CGRect(x: x, y: y, width: buttonSize, height: buttonSize)
            button.layer.cornerRadius = buttonSize / 2
            button.clipsToBounds = true
        }

        let lastRowY = gridStartY + 3 * (buttonSize + buttonSpacing)

        // Button 0 (digitButtons[0])
        let zeroX = gridStartX + (buttonSize + buttonSpacing)
        digitButtons[0].frame = CGRect(x: zeroX, y: lastRowY, width: buttonSize, height: buttonSize)
        digitButtons[0].layer.cornerRadius = buttonSize / 2
        digitButtons[0].clipsToBounds = true

        let deleteX = gridStartX + 2 * (buttonSize + buttonSpacing)
        self.deleteBtn.frame = CGRect(x: deleteX, y: lastRowY, width: buttonSize, height: buttonSize)
    }
}
