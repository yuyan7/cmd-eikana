//
//  KeyCodeConstants.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

enum SpecialKeyCode: CGKeyCode {
    case eisu = 102
    case kana = 104
    case commandRight = 54
    case commandLeft = 55
    case shiftLeft = 56
    case shiftRight = 60
    case controlLeft = 59
    case controlRight = 62
    case optionLeft = 58
    case optionRight = 61
    case function = 63
    case capsLock = 57
    case disabled = 999
    
    static let mediaKeyOffset: CGKeyCode = 1000
}
