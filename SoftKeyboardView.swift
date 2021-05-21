//
//  SoftKeyboardView.swift
//  LoyaltyDev
//
//  Created by Jon Lund on 11/26/19.
//  Copyright © 2019 Mana Mobile, LLC. All rights reserved.
//

import UIKit

// TODO: need to send a bunch of events listed in uiwindow

/// Class for representing a key
fileprivate class KeyButton: UIButton {
	var key: Key!
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

/// Manager for coming and going of keyboards
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
	
	func dismissAll() {
		keyboards.forEach { responder, keyboard in
			keyboard.removeFromSuperview()
		}
		keyboards.removeAll()
	}
	
	@IBAction func editingBegan(notifiction: Notification) {
		guard disabled == false else { return }
		guard let textField = notifiction.object as? UITextField else { return }
		guard let window = textField.window else { return }
		guard textField.inputView == nil else { return }
		let keyboard = SoftKeyboardView(frame: .zero)
		//		keyboard.translatesAutoresizingMaskIntoConstraints = false
		window.addSubview(keyboard)
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
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
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


fileprivate enum Key: ExpressibleByStringLiteral, Equatable {
	case letter(String)
	case backspace
	case shift(Bool)	// isLeft
	case done
	case blank
	case dismiss
	
	init(stringLiteral value: StringLiteralType) {
		self = .letter(value)
	}
	
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
	
	var image: UIImage? {
		switch self {
		case .letter(_):		return nil
		case .backspace:		return UIImage(systemName: "delete.left")
		case .shift(_):			return nil
		case .done:				return nil
		case .blank:			return nil
		case .dismiss:			return UIImage(systemName: "keyboard.chevron.compact.down")
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
		if let image = self.image {
			button.setImage(image, for: .normal)
			button.setTitle(nil, for: .normal)
		}
		else {
			button.setTitle(title, for: .normal)
		}
		button.layer.cornerRadius = 5
		button.layer.borderColor = UIColor.darkGray.cgColor
		button.layer.borderWidth = 1.5
		button.layer.backgroundColor = UIColor.gray.cgColor
		
		// Set up coloring
		switch self {
		case .letter(_):
			button.layer.backgroundColor = UIColor.white.cgColor
			button.setTitleColor(.darkText, for: .normal)
		case .blank:
			button.alpha = 0.0
			button.isEnabled = false
			fallthrough
		case .shift:
			let bg = UIButton.backgroundImageForColor(.white, cornerRadius: 5)
			button.setBackgroundImage(bg, for: .selected)
			button.setTitleColor(.darkText, for: .selected)
			fallthrough
		case .backspace, .dismiss:
			button.layer.backgroundColor = UIColor.gray.cgColor
			button.tintColor = .white
		case .done:
			button.layer.backgroundColor = UIColor.link.cgColor
			button.tintColor = .white
		}
		
		return button
	}
}


class SoftKeyboardView: UIView {

	@available(macCatalyst, unavailable, message: "input views don't work on mac")
	public static func inputView(for textField: UITextField) -> SoftKeyboardView {
		var frame: CGRect = .zero
		if let w = textField.window?.bounds.size {
			let percentHeight: CGFloat = 0.5
			frame = .init(x: 0, y: w.height * 1.0 - percentHeight, width: w.width, height: w.height * percentHeight)
		}
		let keyboard = SoftKeyboardView(frame: frame)
		//		keyboard.translatesAutoresizingMaskIntoConstraints = true
		//		keyboard.autoresizingMask = [.flexibleHeight,.flexibleWidth]
		keyboard.textField = textField
		keyboard.checkForAutoCapitalization()
		return keyboard
	}
	
	fileprivate subscript(index: Key) -> UIView? {
		for v in vStack.arrangedSubviews {
			for h in (v as! UIStackView).arrangedSubviews {
				guard let k = h as? KeyButton else { continue }
				if k.key == index {
					return k
				}
			}
		}
		return nil
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
	
	
	private var timerObserver: Timer?
	private var prevType: UIKeyboardType?
	
	weak var textField: UITextField? {
		didSet {
			timerObserver?.invalidate()
			
			guard let tf = textField else { return }
			self.didChangeKeyboardType(tf.keyboardType)
			prevType = tf.keyboardType
			timerObserver = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
				if tf.keyboardType != self?.prevType {
					print("Change")
					self?.prevType = tf.keyboardType
					self?.didChangeKeyboardType(tf.keyboardType)
				}
			})
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = .lightGray
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		timerObserver?.invalidate()
	}
	
	func didChangeKeyboardType(_ keyboardType: UIKeyboardType) {
		self.subviews.forEach { $0.removeFromSuperview() }
		
		
		
		var aspectRatio: CGFloat = 1.0
		let allKeys: [[Key]]
		
		switch keyboardType {
		
		case .default,.asciiCapable,.numbersAndPunctuation,.URL,.emailAddress,.twitter,.webSearch:
			allKeys	= [
				["`","1","2","3","4","5","6","7","8","9","0",.backspace],
				[.blank,"q","w","e","r","t","y","u","i","o","p",.blank],
				[.blank,"a","s","d","f","g","h","j","k","l",.done],
				[.shift(true),"z","x","c","v","b","n","m",.shift(false)],
				[" ",".","@",".com",.dismiss]
			]
			
		case .numberPad,.phonePad,.namePhonePad,.decimalPad,.asciiCapableNumberPad:
			allKeys	= [
				[.blank,"1","2","3",.blank],
				[.blank,"4","5","6",.blank],
				[.blank,"7","8","9",.blank],
				[.blank,.done,"0",.backspace,.blank]
			]
			if traitCollection.userInterfaceIdiom != .phone {
				aspectRatio = 1.33
			}
			
			
		@unknown default:
			fatalError()
		}
		
		var padding: CGFloat = 10.0
		// make smaller for iPhone
		if let v = textField?.window,
		   v.frame.size.width < 767.0 {
			//v.traitCollection.userInterfaceIdiom == .phone {
			padding = 4.0
		}
		
		
		// Put them all into a vertical stack
		vStack = UIStackView()
		vStack.axis = .vertical
		vStack.spacing = padding
		vStack.distribution = .fillEqually
		vStack.tintColor = .darkText
		
		
		
		// Make the horizontal stack views
		let rows: [UIStackView] = allKeys.map { UIStackView(arrangedSubviews: $0.map({$0.button}))}
		rows.forEach { stackView in
			stackView.alignment = .center
			stackView.distribution = .fill
			stackView.spacing = padding
			stackView.axis = .horizontal
			let kbs = stackView.arrangedSubviews as! [KeyButton]
			kbs.forEach { addConstraints(button: $0, aspectRatio: aspectRatio)}
		}
		
		rows.forEach { vStack.addArrangedSubview($0) }
		
		
		// Constraints: make them all the same height
		for i in 1...3 {
			rows[i].heightAnchor.constraint(equalTo: rows[0].heightAnchor, multiplier: 1).isActive = true
		}
		
		// Special constraints (when there are shift keys it's the normal keyboard and we need to do a few things)
		if let leftShift  = self[.shift(true)],
		   let rightShift = self[.shift(false)] {
			leftShift.widthAnchor.constraint(equalTo: rightShift.widthAnchor, multiplier: 1.0).isActive = true
			
			let leftTab  = rows[1].arrangedSubviews.first as! KeyButton
			let rightTab = rows[1].arrangedSubviews.last as! KeyButton
			leftTab.widthAnchor.constraint(equalTo: rightTab.widthAnchor, multiplier: 1.0).isActive = true
			
			let leftEnter  = rows[2].arrangedSubviews.first as! KeyButton
			let rightEnter = rows[2].arrangedSubviews.last as! KeyButton
			leftEnter.widthAnchor.constraint(equalTo: rightEnter.widthAnchor, multiplier: 1.0).isActive = true
		}
		else {
			for row in rows {
				let left = row.arrangedSubviews.first!
				let right = row.arrangedSubviews.last!
				left.widthAnchor.constraint(equalTo: right.widthAnchor).isActive = true
			}
			let first = self["1"]!
			let done = self[.done]!
			let bksp = self[.backspace]!
			done.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
			bksp.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
		}
		
		
		
		
		self.addSubview(vStack)
		vStack.translatesAutoresizingMaskIntoConstraints = false
		vStack.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
		vStack.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
		vStack.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
		vStack.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
		
	}
	
	private func addConstraints(button: KeyButton, aspectRatio: CGFloat = 1.0) {
		button.translatesAutoresizingMaskIntoConstraints = false
		button.tintColor = .darkText
		button.titleLabel?.textColor = .darkText
		
		switch button.key! {
		case .letter(let x):
			if x != " " {	// spacebar not square
				button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: aspectRatio).isActive = true
			}
		case .backspace:
			button.widthAnchor.constraint(greaterThanOrEqualTo: button.heightAnchor, multiplier: aspectRatio).isActive = true
		//			button.titleLabel?.textAlignment = .right
		//			button.contentVerticalAlignment = .bottom
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
		if let d = textField?.delegate,
		   d.responds(to: #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))) {
			let range = NSRange(location: textField?.text?.count ?? 0, length: string.count)
			guard let result = d.textField?(textField!, shouldChangeCharactersIn: range, replacementString: string),
				  result == true else {
				return
			}
		}
		
		//		textField.text = (textField.text ?? "").appending(string)
		textField?.insertText(string)
		if capsOn && string != " " {
			capsOn = false
		}
		checkForAutoCapitalization()
		
		
		NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: textField)
	}
	
	func checkForAutoCapitalization() {
		guard capsOn == false else { return } // no need
		
		guard let string = textField?.text, string.count > 0 else {
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
		if let text = textField?.text,
		   text.count > 0 {
			//textField.text = String(text.dropLast())
			textField?.deleteBackward()
		}
	}
	
	func tryDone(sender: UIButton, force: Bool = false) {
		guard let textField = textField else { return }
		guard textField.isFirstResponder else { return }
		guard textField.delegate?.textFieldShouldReturn?(textField) != false else {
			return
		}
		//guard textField?.delegate?.textFieldShouldEndEditing?(textField) != false else { return }
		guard textField.canResignFirstResponder else { return }
		if force || textField.delegate == nil {
			textField.resignFirstResponder()
		}
	}
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		
		// let's switch to constraints
		if //translatesAutoresizingMaskIntoConstraints == true,
			let window = self.superview {
			self.translatesAutoresizingMaskIntoConstraints = false
			self.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
			self.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, multiplier: 1).isActive = true
			self.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
		}
	}
	
	// MARK: - UI Callbacks
	
	@IBAction func keyDown(_ sender: UIButton) {
		sender.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
		sender.transform = CGAffineTransform(scaleX: 2, y: 2)
		sender.layer.zPosition = 999
	}
	
	@IBAction func keyUp(_ sender: UIButton) {
		sender.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		sender.transform = .identity
		sender.layer.zPosition = 1
		guard let sender = sender as? KeyButton else { return }
		switch sender.key! {
		case .letter(_):		enteredString(sender.textValue!)
		case .backspace:		backspace()
		case .shift(_):			self.capsOn = !capsOn
		case .done:				tryDone(sender: sender)
		case .blank:			()
		case .dismiss:			tryDone(sender: sender, force: true)
		}
	}
	
}

