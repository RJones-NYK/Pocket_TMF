//
//  ArtifactDetailView.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import SwiftUI

struct ArtifactDetailView: View {
    let artifact: TMFArtifact
    @State private var isDefinitionExpanded = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                ArtifactHeaderView(artifact: artifact)
                
                // Definition Section
                DefinitionSectionView(
                    artifact: artifact,
                    isExpanded: $isDefinitionExpanded
                )
                
                // Metadata Sections
                if hasDocumentMetadata {
                    DocumentMetadataView(artifact: artifact)
                }
                
                if hasLevelMetadata {
                    LevelMetadataView(artifact: artifact)
                }
                
                if hasAdditionalMetadata {
                    AdditionalMetadataView(artifact: artifact)
                }
                
                // Recommended Subartifacts
                if let subartifacts = artifact.recommendedSubartifacts, !subartifacts.isEmpty {
                    SubartifactsView(subartifacts: subartifacts)
                }
            }
            .padding()
        }
        .navigationTitle(artifact.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Computed Properties
    
    private var hasICHMetadata: Bool {
        artifact.ichCode?.isEmpty == false ||
        artifact.iso14155Reference?.isEmpty == false
    }
    
    private var hasDocumentMetadata: Bool {
        artifact.sponsorDocument?.isEmpty == false ||
        artifact.investigatorDocument?.isEmpty == false
    }
    
    private var hasProcessMetadata: Bool {
        artifact.processNumber?.isEmpty == false ||
        artifact.processName?.isEmpty == false
    }
    
    private var hasLevelMetadata: Bool {
        artifact.trialLevelDocument?.isEmpty == false ||
        artifact.countryLevelDocument?.isEmpty == false ||
        artifact.siteLevelDocument?.isEmpty == false
    }
    
    private var hasAdditionalMetadata: Bool {
        artifact.datingConvention?.isEmpty == false ||
        artifact.translationRequired?.isEmpty == false ||
        artifact.wetInkSignature?.isEmpty == false
    }
}

struct ArtifactHeaderView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(artifact.number)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let coreRecommended = artifact.coreRecommended {
                    Text(coreRecommended)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(coreRecommended == "Core" ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                        .foregroundColor(coreRecommended == "Core" ? .red : .blue)
                        .clipShape(Capsule())
                }
            }
            
            if let uniqueID = artifact.uniqueID {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)
                    Text("Unique ID: \(String(format: "%03d", uniqueID))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DefinitionSectionView: View {
    let artifact: TMFArtifact
    @Binding var isExpanded: Bool
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Definition & Purpose")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(artifact.definition)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 3)
                    .animation(.easeInOut, value: isExpanded)
            }
        }
    }
}

struct ICHMetadataView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        GroupBox("Regulatory References") {
            VStack(alignment: .leading, spacing: 8) {
                if let ichCode = artifact.ichCode, !ichCode.isEmpty {
                    MetadataRow(icon: "doc.text", label: "ICH Code", value: ichCode)
                }
                
                if let iso14155 = artifact.iso14155Reference, !iso14155.isEmpty {
                    MetadataRow(icon: "doc.badge.gearshape", label: "ISO 14155", value: iso14155)
                }
            }
        }
    }
}

struct DocumentMetadataView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        GroupBox("Document Applicability") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sponsor Document")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if artifact.sponsorDocument == "X" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    Text("Investigator Document")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if artifact.investigatorDocument == "X" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct ProcessMetadataView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        GroupBox("Process Information") {
            VStack(alignment: .leading, spacing: 8) {
                if let processNumber = artifact.processNumber, !processNumber.isEmpty {
                    MetadataRow(icon: "number", label: "Process Number", value: processNumber)
                }
                
                if let processName = artifact.processName, !processName.isEmpty {
                    MetadataRow(icon: "gear", label: "Process Name", value: processName)
                }
            }
        }
    }
}

struct LevelMetadataView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        GroupBox("Artifact Requirements by Level") {
            HStack(spacing: 20) {
                // Trial Level
                RequirementColumn(
                    title: "Trial Level",
                    isRequired: artifact.trialLevelDocument == "X"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Country Level
                RequirementColumn(
                    title: "Country Level", 
                    isRequired: artifact.countryLevelDocument == "X"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Site Level
                RequirementColumn(
                    title: "Site Level",
                    isRequired: artifact.siteLevelDocument == "X"
                )
            }
            .padding(.vertical, 8)
        }
    }
}

struct RequirementColumn: View {
    let title: String
    let isRequired: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            if isRequired {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(.green).frame(width: 24, height: 24))
                    .font(.system(size: 18))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(.red).frame(width: 24, height: 24))
                    .font(.system(size: 18))
            }
        }
        .frame(maxWidth: .infinity)
    }
}



struct AdditionalMetadataView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        GroupBox("Additional Information") {
            VStack(alignment: .leading, spacing: 8) {
                if let datingConvention = artifact.datingConvention, !datingConvention.isEmpty {
                    MetadataRow(icon: "calendar", label: "Dating Convention", value: datingConvention)
                }
                
                if let translationRequired = artifact.translationRequired, translationRequired == "X" {
                    MetadataRow(icon: "globe", label: "Translation Required", value: "Yes")
                }
                
                if let wetInkSignature = artifact.wetInkSignature, !wetInkSignature.isEmpty {
                    MetadataRow(icon: "signature", label: "Wet Ink Signature", value: wetInkSignature)
                }
            }
        }
    }
}

struct SubartifactsView: View {
    let subartifacts: String
    
    var subartifactList: [String] {
        subartifacts.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    var body: some View {
        GroupBox("Recommended Subartifacts") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(subartifactList, id: \.self) { subartifact in
                    HStack {
                        Image(systemName: "doc")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        
                        Text(subartifact.trimmingCharacters(in: .whitespaces))
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        ArtifactDetailView(artifact: TMFData.zones[0].sections[0].artifacts[0])
    }
} 