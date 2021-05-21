//
//  ViewController.swift
//  TestSoftKeyboard
//
//  Created by Jon Lund on 5/8/21.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet var tf: UITextField!
	var i: Int = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Enable
		SoftKeyboardManager.shared.disabled = false
	}
	
	/// cycle through the keyboard types
	@IBAction func togglePressed(_ sender: Any) {
		let types: [UIKeyboardType] = [.asciiCapable,.default,.numberPad,.namePhonePad,.phonePad]
		i += 1
		i = i % types.count
		tf.keyboardType = types[i]
		tf.text = types[i].displayName
	}
	
	/// We can use it two ways
	@IBAction func toggleApproach(_ sender: UIButton) {
		tf.resignFirstResponder()
		
		#if targetEnvironment(macCatalyst)
		sender.jiggle()
		print("input views don't work on mac Catalyst")
		#else
		// toggle
		SoftKeyboardManager.shared.disabled = !SoftKeyboardManager.shared.disabled
		
		if SoftKeyboardManager.shared.disabled {
			tf.inputView = SoftKeyboardView.inputView(for: tf)
		}
		else {
			tf.inputView = nil
		}
		#endif
	}
}


extension UIView {
	func jiggle(verticalAxis: Bool = false) {
		let translated: CGAffineTransform = .identity.translatedBy(x: 10, y: 0)
		UIView.animate(withDuration: 0.01, delay: 0, options: [.curveEaseInOut], animations: { self.transform = translated }) { success in
			UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 129, options: [], animations: { self.transform = .identity })
		}
	}

}


extension UIKeyboardType {
	var displayName: String {
		switch self {
		case .default: 					return "default"
		case .asciiCapable:				return "asciiCapable"
		case .numbersAndPunctuation:	return "numbersAndPunctuation"
		case .URL:						return "URL"
		case .numberPad:				return "numberPad"
		case .phonePad:					return "phonePad"
		case .namePhonePad:				return "namePhonePad"
		case .emailAddress:				return "emailAddress"
		case .decimalPad:				return "decimalPad"
		case .twitter:					return "twitter"
		case .webSearch:				return "webSearch"
		case .asciiCapableNumberPad:	return "asciiCapableNumberPad"
		@unknown default:				return "unknown"
		}
	}
}
