import Carbon.HIToolbox

/// Resolve a character (e.g. "A") to the physical keyCode that produces it
/// on the current keyboard layout. Works on QWERTY, AZERTY, QWERTZ, etc.
///
/// Returns nil if the character cannot be found on the current layout.
func keyCodeForCharacter(_ character: String) -> UInt16? {
    let target = character.lowercased()
    guard target.count == 1 else { return nil }

    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
          let rawPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
        return nil
    }

    let layoutData = unsafeBitCast(rawPtr, to: CFData.self)
    let keyboardLayout = unsafeBitCast(
        CFDataGetBytePtr(layoutData),
        to: UnsafePointer<UCKeyboardLayout>.self
    )

    // Scan all key codes to find which one produces the target character
    for keyCode: UInt16 in 0 ... 127 {
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0

        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDown),
            0,                                     // no modifiers
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            4,
            &length,
            &chars
        )

        if status == noErr, length > 0 {
            let produced = String(utf16CodeUnits: chars, count: length).lowercased()
            if produced == target {
                return keyCode
            }
        }
    }
    return nil
}

/// Convert a keyCode to the character it produces on the current keyboard layout.
/// Falls back to the QWERTY label if layout translation fails.
func characterForKeyCode(_ keyCode: UInt16) -> String {
    if let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
       let rawPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) {
        let layoutData = unsafeBitCast(rawPtr, to: CFData.self)
        let keyboardLayout = unsafeBitCast(
            CFDataGetBytePtr(layoutData),
            to: UnsafePointer<UCKeyboardLayout>.self
        )

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0

        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDown),
            0,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            4,
            &length,
            &chars
        )

        if status == noErr, length > 0 {
            return String(utf16CodeUnits: chars, count: length).uppercased()
        }
    }
    // Fallback: use hardcoded QWERTY map
    return keyCodeToQWERTYString(keyCode)
}

/// Hardcoded QWERTY labels — only used as fallback when layout detection fails.
func keyCodeToQWERTYString(_ code: UInt16) -> String {
    switch Int(code) {
    case kVK_ANSI_A: return "A"
    case kVK_ANSI_S: return "S"
    case kVK_ANSI_D: return "D"
    case kVK_ANSI_F: return "F"
    case kVK_ANSI_G: return "G"
    case kVK_ANSI_H: return "H"
    case kVK_ANSI_J: return "J"
    case kVK_ANSI_K: return "K"
    case kVK_ANSI_L: return "L"
    case kVK_ANSI_Q: return "Q"
    case kVK_ANSI_W: return "W"
    case kVK_ANSI_E: return "E"
    case kVK_ANSI_R: return "R"
    case kVK_ANSI_T: return "T"
    case kVK_ANSI_Y: return "Y"
    case kVK_ANSI_U: return "U"
    case kVK_ANSI_I: return "I"
    case kVK_ANSI_O: return "O"
    case kVK_ANSI_P: return "P"
    case kVK_ANSI_Z: return "Z"
    case kVK_ANSI_X: return "X"
    case kVK_ANSI_C: return "C"
    case kVK_ANSI_V: return "V"
    case kVK_ANSI_B: return "B"
    case kVK_ANSI_N: return "N"
    case kVK_ANSI_M: return "M"
    default: return "?"
    }
}
