//
//  Extensions.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import Foundation

// MARK: - String Extensions

extension String {
    /// Formats a section number to ensure the first part is always two digits
    /// Examples: "1.01" -> "01.01", "10.01" -> "10.01"
    var formattedSectionNumber: String {
        let components = self.components(separatedBy: ".")
        guard components.count >= 2,
              let firstNumber = Int(components[0]) else {
            return self // Return original if format doesn't match
        }
        
        let formattedFirst = String(format: "%02d", firstNumber)
        let remaining = components.dropFirst().joined(separator: ".")
        return "\(formattedFirst).\(remaining)"
    }
} 