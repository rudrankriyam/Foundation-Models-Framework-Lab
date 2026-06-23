//
//  ImageInputAccessibilityFocusTarget.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation

enum ImageInputAccessibilityFocusTarget: Hashable {
    case error(String)
    case result(UUID)
}
#endif
