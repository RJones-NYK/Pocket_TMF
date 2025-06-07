//
//  ZoneDetailView.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import SwiftUI

struct ZoneDetailView: View {
    let zone: TMFZone
    @State private var searchText = ""
    @State private var collapsedSections: Set<String> = []
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var filteredSections: [TMFSection] {
        if searchText.isEmpty {
            return zone.sections
        } else {
            return zone.sections.filter { section in
                section.name.localizedCaseInsensitiveContains(searchText) ||
                section.artifacts.contains { artifact in
                    artifact.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    private func isSectionCollapsed(_ section: TMFSection) -> Bool {
        collapsedSections.contains(section.number)
    }
    
    private func toggleSection(_ section: TMFSection) {
        if collapsedSections.contains(section.number) {
            collapsedSections.remove(section.number)
        } else {
            collapsedSections.insert(section.number)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Zone Header
                Section {
                    ZoneHeaderView(zone: zone)
                        .environmentObject(colorSchemeManager)
                }
                
                // Sections
                ForEach(filteredSections) { section in
                    Section(header: CollapsibleSectionHeaderView(
                        section: section,
                        isCollapsed: isSectionCollapsed(section),
                        onToggle: { toggleSection(section) }
                    )
                    .environmentObject(colorSchemeManager)) {
                        if !isSectionCollapsed(section) {
                            ForEach(section.artifacts) { artifact in
                                NavigationLink(destination: ArtifactDetailView(artifact: artifact)
                                    .environmentObject(colorSchemeManager)) {
                                    ArtifactRowView(artifact: artifact)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Zone \(zone.number)")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search artifacts...")
        }
    }
}

struct ZoneHeaderView: View {
    let zone: TMFZone
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var totalArtifacts: Int {
        zone.sections.reduce(0) { $0 + $1.artifacts.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(zone.number)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(colorSchemeManager.selectedScheme.color)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(zone.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Zone \(zone.number)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Stats
            HStack(spacing: 20) {
                StatPill(title: "Sections", value: "\(zone.sections.count)")
                    .environmentObject(colorSchemeManager)
                StatPill(title: "Artifacts", value: "\(totalArtifacts)")
                    .environmentObject(colorSchemeManager)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SectionHeaderView: View {
    let section: TMFSection
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Section \(section.number.formattedSectionNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(section.artifacts.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(colorSchemeManager.selectedScheme.color)
                .clipShape(Circle())
        }
    }
}

struct CollapsibleSectionHeaderView: View {
    let section: TMFSection
    let isCollapsed: Bool
    let onToggle: () -> Void
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Section \(section.number.formattedSectionNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(section.artifacts.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(colorSchemeManager.selectedScheme.color)
                        .clipShape(Circle())
                    
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(colorSchemeManager.selectedScheme.color)
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
            }
            .contentShape(Rectangle()) // Makes entire header tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ArtifactRowView: View {
    let artifact: TMFArtifact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(artifact.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let coreRecommended = artifact.coreRecommended {
                    Text(coreRecommended)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(coreRecommended == "Core" ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .foregroundColor(coreRecommended == "Core" ? .red : .blue)
                        .clipShape(Capsule())
                }
            }
            
            Text(artifact.number)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            if !artifact.definition.isEmpty {
                Text(artifact.definition)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Metadata Pills
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), alignment: .leading, spacing: 4) {
                if let sponsorDoc = artifact.sponsorDocument, sponsorDoc == "X" {
                    MetadataPill(label: "Sponsor", value: "✓", color: .green)
                }
                
                if let investigatorDoc = artifact.investigatorDocument, investigatorDoc == "X" {
                    MetadataPill(label: "Investigator", value: "✓", color: .green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorSchemeManager.selectedScheme.color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct MetadataPill: View {
    let label: String
    let value: String
    let color: Color
    
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    init(label: String, value: String, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color ?? Color.accentColor // Will be overridden in body
    }
    
    var body: some View {
        let finalColor = color == Color.accentColor ? colorSchemeManager.selectedScheme.color : color
        
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(finalColor.opacity(0.15))
        .foregroundColor(finalColor)
        .clipShape(Capsule())
    }
}

#Preview {
    ZoneDetailView(zone: TMFData.zones[0])
} 