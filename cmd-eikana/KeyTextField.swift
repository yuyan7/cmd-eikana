//
//  KeyTextField.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class KeyTextField: NSComboBox {
    /// Custom delegate with other methods than NSTextFieldDelegate.
    var shortcut: KeyboardShortcut? = nil
    var saveAddress: (row: Int, id: String)? = nil
    var isAllowModifierOnly = true
    
    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder();
        if (became) {
            AppState.shared.activeKeyTextField = self
        }
        return became;
    }
    //    override func resignFirstResponder() -> Bool {
    //        let resigned = super.resignFirstResponder();
    //        if (resigned) {
    //        }
    //        return resigned;
    //    }
    
    override func textDidEndEditing(_ obj: Notification) {
        super.textDidEndEditing(obj)
        
        switch self.stringValue {
        case "英数":
            shortcut = KeyboardShortcut(keyCode: 102)
            break
        case "かな":
            shortcut = KeyboardShortcut(keyCode: 104)
            break
        case "⇧かな":
            shortcut = KeyboardShortcut(keyCode: 104, flags: CGEventFlags.maskShift)
            break
        case "前の入力ソースを選択", "select the previous input source":
            guard let symbolichotkeys = UserDefaults.init(suiteName: "com.apple.symbolichotkeys.plist")?.object(forKey: "AppleSymbolicHotKeys") as? NSDictionary,
                  let parameters = symbolichotkeys.value(forKeyPath: "60.value.parameters") as? [Int],
                  parameters.count >= 3 else {
                break
            }
            
            shortcut = KeyboardShortcut(keyCode: CGKeyCode(parameters[1]), flags: CGEventFlags(rawValue: UInt64(parameters[2])))
            break
        case "入力メニューの次のソースを選択", "select next source in input menu":
            guard let symbolichotkeys = UserDefaults.init(suiteName: "com.apple.symbolichotkeys.plist")?.object(forKey: "AppleSymbolicHotKeys") as? NSDictionary,
                  let parameters = symbolichotkeys.value(forKeyPath: "61.value.parameters") as? [Int],
                  parameters.count >= 3 else {
                break
            }
            
            shortcut = KeyboardShortcut(keyCode: CGKeyCode(parameters[1]), flags: CGEventFlags(rawValue: UInt64(parameters[2])))
            break
        case "Disable":
            shortcut = KeyboardShortcut(keyCode: CGKeyCode(999))
            break
        default:
            break
        }
        
        if let shortcut = shortcut {
            self.stringValue = shortcut.toString()
            
            if let saveAddress = saveAddress {
                if saveAddress.id == "input" {
                    AppState.shared.keyMappingList[saveAddress.row].input = shortcut
                }
                else {
                    AppState.shared.keyMappingList[saveAddress.row].output = shortcut
                }
                AppState.shared.keyMappingListToShortcutList()
            }
        }
        else {
            self.stringValue = ""
        }
        
        AppState.shared.saveKeyMappings()
        
        if AppState.shared.activeKeyTextField == self {
            AppState.shared.activeKeyTextField = nil
        }
    }
    func blur() {
        self.window?.makeFirstResponder(nil)
        AppState.shared.activeKeyTextField = nil
    }
}
