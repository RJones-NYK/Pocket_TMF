//
//  TMFModels.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import Foundation

// MARK: - TMF Data Models

struct TMFZone: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let name: String
    let sections: [TMFSection]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
    static func == (lhs: TMFZone, rhs: TMFZone) -> Bool {
        lhs.number == rhs.number
    }
}

struct TMFSection: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let name: String
    let artifacts: [TMFArtifact]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
    static func == (lhs: TMFSection, rhs: TMFSection) -> Bool {
        lhs.number == rhs.number
    }
}

struct TMFArtifact: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let name: String
    let definition: String
    let recommendedSubartifacts: String?
    let coreRecommended: String?
    let ichCode: String?
    let iso14155Reference: String?
    let artifactNameV13: String?
    let uniqueID: Int?
    let sponsorDocument: String?
    let investigatorDocument: String?
    let processNumber: String?
    let processName: String?
    let trialLevelDocument: String?
    let trialLevelMilestone: String?
    let countryLevelDocument: String?
    let countryLevelMilestone: String?
    let siteLevelDocument: String?
    let siteLevelMilestone: String?
    let datingConvention: String?
    let artifactOwner: String?
    let artifactLocation: String?
    let wetInkSignature: String?
    let sopReference: String?
    let translationRequired: String?
    let currentArtifactName: String?
    let additionalMetadata: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
    static func == (lhs: TMFArtifact, rhs: TMFArtifact) -> Bool {
        lhs.number == rhs.number
    }
}

// MARK: - Main Data Source

struct TMFData {
    static let zones: [TMFZone] = TMFCompleteData.zones.sorted { zone1, zone2 in
        // Convert zone numbers to integers for proper numerical sorting
        let num1 = Int(zone1.number) ?? 0
        let num2 = Int(zone2.number) ?? 0
        return num1 < num2
    }
} 