# SoftKeyboardView
A pure swift iOS keyboard for times when complete keyboard control is needed. This was originally built for a mac catalyst app using a touch screen. All you have to do is add SoftKeyboardView to your project and somewhere (e.g. `appDidFinishLaunching`) hit the singleton:

# Usage:
		SoftKeyboardManager.shared.disabled = false

Or, you can use it as an inputView for cases where you want a numeric keypad with a done button. (This does not work on mac catalyst because the OS doesn't deal with presenting floating keyboards/input views.

# Input view example:
		textField.inputView = SoftKeyboardView.inputView(for: textField)


Pull requests welcome!
