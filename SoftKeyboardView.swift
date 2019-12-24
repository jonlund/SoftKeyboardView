//
//  SoftKeyboardView.swift
//  LoyaltyDev
//
//  Created by Jon Lund on 11/26/19.
//  Copyright © 2019 Mana Mobile, LLC. All rights reserved.
//

import UIKit

// TODO: need to send a bunch of events listed in uiwindow

class KeyButton: UIButton {
	var key: SoftKeyboardView.Key!
	private var _isCaps = false
	var isCaps: Bool {
		get { return _isCaps }
		set {
			guard newValue != _isCaps else { return }
			_isCaps = newValue
			if let t = key.textValue {
				guard t != ".com" else {
					_isCaps = false
					return
				}
				let changed = newValue ? t.uppercased() : t.lowercased()
				//guard changed != t else { return }	// no need
				setTitle(changed, for: .normal)
			}
			else if key.isShift {
				self.isSelected = _isCaps
			}
		}
	}
	var textValue: String? {
		if _isCaps { return key.textValue?.uppercased() }
		return key.textValue
	}
}

fileprivate let sharedKeyboardManager = SoftKeyboardManager()

class SoftKeyboardManager {
	
	static var shared: SoftKeyboardManager { return sharedKeyboardManager }
	var keyboards = [UIView:SoftKeyboardView]()
	var removeAction: Timer?
	var removeCompletion: (() -> Void)?
	var disabled = true {
		didSet {
			if disabled == true {
				dismissAll()
			}
		}
	}

	// MARK: - Observing for when needed
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(editingBegan(notifiction:)), name: UITextField.textDidBeginEditingNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(editingEnded(notifiction:)), name: UITextField.textDidEndEditingNotification, object: nil)
	}
	
	private func dismissAll() {
		keyboards.forEach { responder, keyboard in
			keyboard.removeFromSuperview()
		}
		keyboards.removeAll()
	}

	@IBAction func editingBegan(notifiction: Notification) {
		guard disabled == false else { return }
		guard let textField = notifiction.object as? UITextField else { return }
		guard let window = textField.window else { return }
		let keyboard = SoftKeyboardView(frame: .zero)
		window.addSubview(keyboard)
		keyboard.translatesAutoresizingMaskIntoConstraints = false
		keyboard.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
		keyboard.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, multiplier: 1).isActive = true
		keyboard.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: 0).isActive = true
		keyboard.textField = textField
		keyboard.checkForAutoCapitalization()
		keyboards[textField] = keyboard		// save so we can get rid of it
		
		// get rid of bar
		textField.inputAssistantItem.leadingBarButtonGroups = []
		textField.inputAssistantItem.trailingBarButtonGroups = []
		
		// if another is already up make a seamless swap (call the completion so view gets removed but cancel animation)
		if let a = removeAction, let c = removeCompletion {
			a.invalidate()
			c()
			removeAction = nil
			removeCompletion = nil
		}
		else {
			keyboard.updateConstraints()
			keyboard.transform = CGAffineTransform(translationX: 0, y: keyboard.frame.size.height)
			UIView.animate(withDuration: 1.5, delay: 0.001, options: [], animations: {
				keyboard.transform = .identity
			}, completion: nil)
		}
		
	}

	@IBAction func editingEnded(notifiction: Notification) {
		guard let textField = notifiction.object as? UITextField else { return }
		if let kb = keyboards[textField] {
			
			removeCompletion = {
				kb.removeFromSuperview()
			}
			
			removeAction = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: false) { _ in
				self.removeAction = nil
				UIView.animate(withDuration: 1.5, animations: {
					kb.transform = CGAffineTransform(translationX: 0, y: kb.frame.size.height)
				}) { _ in
					self.removeCompletion?()
					self.removeCompletion = nil
				}
			}
		}

		keyboards[textField]?.removeFromSuperview()
		keyboards[textField] = nil
	}
}

extension UIButton {
	static func backgroundImageForColor(_ color: UIColor, cornerRadius: CGFloat) -> UIImage {
		let size = CGSize(width: cornerRadius*2+1, height: cornerRadius*2+1)
		_ = UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		defer { UIGraphicsEndImageContext() }
		let rect = CGRect(origin: .zero, size: size)
		let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
		color.setFill()
		path.fill()
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		let cap: Int = Int(cornerRadius + 0.000)
		return image.stretchableImage(withLeftCapWidth: cap, topCapHeight: cap)
	}
}

class SoftKeyboardView: UIView {

	enum Key {
		case letter(String)
		case backspace
		case shift(Bool)	// isLeft
		case done
		case blank
		case dismiss
		
		var title: String {
			switch self {
			case .letter(let x):	return x
			case .backspace:		return "delete"
			case .shift(_):			return "shift"
			case .done:				return "done"
			case .blank:			return ""
			case .dismiss:			return "dismiss"
			}
		}
		
		var isShift: Bool {
			switch self {
			case .shift(_):	return true
			default:		return false
			}
		}
		
		var textValue: String? {
			switch self {
			case .letter(let x):	return x
			default: 				return nil
			}
		}
		
		var button: KeyButton {
			let button = KeyButton(type: .custom)
			button.key = self
			button.setTitle(title, for: .normal)
			button.layer.cornerRadius = 5
			button.layer.borderColor = UIColor.darkGray.cgColor
			button.layer.borderWidth = 1.5
			button.layer.backgroundColor = UIColor.gray.cgColor

			// Set up coloring
			switch self {
			case .letter(_):
				button.layer.backgroundColor = UIColor.white.cgColor
				button.setTitleColor(.darkText, for: .normal)
			case .dismiss:
				button.layer.backgroundColor = UIColor.gray.cgColor
				if #available(iOS 13.0, *) {
					button.tintColor = .white
					let image = UIImage(systemName: "keyboard.chevron.compact.down")
					button.setImage(image, for: .normal)
					button.setTitle(nil, for: .normal)
				}
			case .blank:
				button.isEnabled = false
				fallthrough
			case .shift:
				let bg = UIButton.backgroundImageForColor(.white, cornerRadius: 5)
				button.setBackgroundImage(bg, for: .selected)
				button.setTitleColor(.darkText, for: .selected)
				fallthrough
			case .backspace, .done:
				button.layer.backgroundColor = UIColor.gray.cgColor
			}
			
		
			return button
		}
	}
	
	override var intrinsicContentSize: CGSize { return CGSize(width: 1024, height: 360) }
	
	private var vStack: UIStackView!
	private var shiftKeys: (left: KeyButton, right: KeyButton) {
		let row = vStack.arrangedSubviews[3] as! UIStackView
		let leftShift  = row.arrangedSubviews.first as! KeyButton
		let rightShift = row.arrangedSubviews.last as! KeyButton
		return (left: leftShift, right: rightShift)
	}
	private var allButtons: [KeyButton] {
		return vStack.arrangedSubviews.flatMap { ($0 as! UIStackView).arrangedSubviews.map({$0 as! KeyButton})}
	}

	var capsOn: Bool = false {
		didSet {
			allButtons.forEach { $0.isCaps = capsOn }
		}
	}
	var textField: UITextField!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = .lightGray
		addKeys()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func addKeys() {
		var row0 = [Key]()
		var row1 = [Key]()
		var row2 = [Key]()
		var row3 = [Key]()
		var row4 = [Key]()

		"`1234567890".forEach { row0.append(.letter(String($0))) }
		row0.append(.backspace)
		row1.append(.blank)
		"qwertyuiop".forEach { row1.append(.letter(String($0))) }
		row1.append(.blank)
		row2.append(.blank)
		"asdfghjkl".forEach  { row2.append(.letter(String($0))) }
		row2.append(.done)
		row3.append(.shift(true))
		"zxcvbnm".forEach  { row3.append(.letter(String($0))) }
		row3.append(.shift(false))
		//row4.append(.blank)
		" .@".forEach  { row4.append(.letter(String($0))) }
		row4.append(.letter(".com"))
		row4.append(.dismiss)
		let allKeys: [[Key]] = [row0,row1,row2,row3,row4]
		
		
		// Make the horizontal stack views
		let rows: [UIStackView] = allKeys.map { UIStackView(arrangedSubviews: $0.map({$0.button}))}
		rows.forEach { stackView in
			stackView.alignment = .center
			stackView.distribution = .fill
			stackView.spacing = 10
			stackView.axis = .horizontal
			let kbs = stackView.arrangedSubviews as! [KeyButton]
			kbs.forEach { addConstraints(button: $0)}
			//allTextKeys.append(contentsOf: kbs.filter({ $0.key.textValue != nil }) )
		}
		
		// Special constraints
		let leftShift  = rows[3].arrangedSubviews.first as! KeyButton
		let rightShift = rows[3].arrangedSubviews.last as! KeyButton
		leftShift.widthAnchor.constraint(equalTo: rightShift.widthAnchor, multiplier: 1.0).isActive = true

		let leftTab  = rows[1].arrangedSubviews.first as! KeyButton
		let rightTab = rows[1].arrangedSubviews.last as! KeyButton
		leftTab.widthAnchor.constraint(equalTo: rightTab.widthAnchor, multiplier: 1.0).isActive = true

		let leftEnter  = rows[2].arrangedSubviews.first as! KeyButton
		let rightEnter = rows[2].arrangedSubviews.last as! KeyButton
		leftEnter.widthAnchor.constraint(equalTo: rightEnter.widthAnchor, multiplier: 1.0).isActive = true

		
		// Put them all into a vertical stack
		vStack = UIStackView(arrangedSubviews: rows)
		vStack.axis = .vertical
		vStack.spacing = 10
		vStack.distribution = .fillEqually
		vStack.tintColor = .darkText
		
		for i in 1...3 {
			rows[i].heightAnchor.constraint(equalTo: rows[0].heightAnchor, multiplier: 1).isActive = true
		}
		
		
		self.addSubview(vStack)
		vStack.translatesAutoresizingMaskIntoConstraints = false
		vStack.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
		vStack.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
		vStack.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
		vStack.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
		
	}
	
	func addConstraints(button: KeyButton) {
		button.translatesAutoresizingMaskIntoConstraints = false
		button.tintColor = .darkText
		button.titleLabel?.textColor = .darkText
		
		switch button.key! {
		case .letter(let x):
			if x != " " {	// spacebar not square
				button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
			}
		case .backspace:
			button.titleLabel?.textAlignment = .right
			button.contentVerticalAlignment = .bottom
		case .shift(let isLeft):
			button.titleLabel?.textAlignment = isLeft ? .left : .right
			button.contentVerticalAlignment = .bottom
		case .done:
			button.titleLabel?.textAlignment = .right
			button.contentVerticalAlignment = .bottom
		case .blank:
			()
		case .dismiss:
			button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
		}

		button.heightAnchor.constraint(equalTo: button.superview!.heightAnchor, multiplier: 1).isActive = true
		button.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
		button.addTarget(self, action: #selector(keyUp(_:)), for: .touchUpInside)
		button.addTarget(self, action: #selector(keyUp(_:)), for: .touchUpOutside)
	}
	
	func enteredString(_ string: String) {
		if let d = textField.delegate,
			d.responds(to: #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))) {
			let range = NSRange(location: textField.text?.count ?? 0, length: string.count)
			guard d.textField!(textField, shouldChangeCharactersIn: range, replacementString: string) else {
				return
			}
		}
		
//		textField.text = (textField.text ?? "").appending(string)
		textField.insertText(string)
		if capsOn && string != " " {
			capsOn = false
		}
		checkForAutoCapitalization()
		
		
		NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: textField)
	}
	
	func checkForAutoCapitalization() {
		guard capsOn == false else { return } // no need
		
		guard let string = textField.text, string.count > 0 else {
			switch textField!.autocapitalizationType {
			case .words,.sentences,.allCharacters:	capsOn = true
			default: ()
			}
			return
		}
		
		switch textField!.autocapitalizationType {
				
		case .words:
			if string.range(of: "\\s$", options: [.regularExpression]) != nil { capsOn = true }
		case .sentences:
			if string.range(of: "[\\.\\!\\?]\\s*", options: [.regularExpression]) != nil { capsOn = true }
		case .allCharacters:
			capsOn = true
		case .none: ()
		@unknown default:
			()
		}
	}
	
	func backspace() {
		if let text = textField.text,
			text.count > 0 {
			//textField.text = String(text.dropLast())
			textField.deleteBackward()
		}
	}
	
	func tryDone(force: Bool = false) {
		guard textField.isFirstResponder else { return }
		guard textField?.delegate?.textFieldShouldReturn?(textField) != false else {
			return
		}
		//guard textField?.delegate?.textFieldShouldEndEditing?(textField) != false else { return }
		guard textField.isFirstResponder else { return }
		guard textField.canResignFirstResponder else { return }
		if force {
			textField.resignFirstResponder()
		}
	}
	
	
	
	// MARK: - UI Callbacks
	
	@IBAction func keyDown(_ sender: KeyButton) {
		sender.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
		sender.transform = CGAffineTransform(scaleX: 2, y: 2)
		sender.layer.zPosition = 999
	}

	@IBAction func keyUp(_ sender: KeyButton) {
		sender.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		sender.transform = .identity
		sender.layer.zPosition = 1
		switch sender.key! {
		case .letter(_):		enteredString(sender.textValue!)
		case .backspace:		backspace()
		case .shift(_):			self.capsOn = !capsOn
		case .done:				tryDone()
		case .blank:			()
		case .dismiss:			tryDone(force: true)
		}
	}

}

