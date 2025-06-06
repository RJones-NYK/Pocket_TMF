//
//  FiltersView.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import SwiftUI

struct FiltersView: View {
    @State private var selectedFileType: String = ""
    @State private var selectedZone: String = ""
    @State private var selectedSection: String = ""
    @State private var selectedArtifact: String = ""
    
    @State private var fileTypeSearchText = ""
    @State private var zoneSearchText = ""
    @State private var sectionSearchText = ""
    @State private var artifactSearchText = ""
    
    @State private var showingResults = false
    @Environment(\.dismiss) private var dismiss
    
    // Computed properties for filter options
    private var fileTypes: [String] {
        let types = Set(TMFData.zones.flatMap { zone in
            zone.sections.flatMap { section in
                section.artifacts.compactMap { artifact in
                    var documentTypes: [String] = []
                    if artifact.trialLevelDocument == "X" {
                        documentTypes.append("Trial")
                    }
                    if artifact.countryLevelDocument == "X" {
                        documentTypes.append("Country")
                    }
                    if artifact.siteLevelDocument == "X" {
                        documentTypes.append("Site")
                    }
                    return documentTypes
                }
            }
        }.flatMap { $0 })
        
        // Return in specific order: Trial, Country, Site
        let orderedTypes = ["Trial", "Country", "Site"]
        return orderedTypes.filter { types.contains($0) }
    }
    
    private var zones: [TMFZone] {
        return TMFData.zones
    }
    
    private var sections: [TMFSection] {
        return TMFData.zones.flatMap { $0.sections }
    }
    
    private var artifacts: [TMFArtifact] {
        return TMFData.zones.flatMap { zone in
            zone.sections.flatMap { $0.artifacts }
        }
    }
    
    // Filtered options based on search text
    private var filteredFileTypes: [String] {
        fileTypeSearchText.isEmpty ? fileTypes : 
        fileTypes.filter { $0.localizedCaseInsensitiveContains(fileTypeSearchText) }
    }
    
    private var filteredZones: [TMFZone] {
        zoneSearchText.isEmpty ? zones : 
        zones.filter { 
            $0.name.localizedCaseInsensitiveContains(zoneSearchText) || 
            $0.number.localizedCaseInsensitiveContains(zoneSearchText) 
        }
    }
    
    private var filteredSections: [TMFSection] {
        sectionSearchText.isEmpty ? sections : 
        sections.filter { 
            $0.name.localizedCaseInsensitiveContains(sectionSearchText) || 
            $0.number.localizedCaseInsensitiveContains(sectionSearchText) 
        }
    }
    
    private var filteredArtifacts: [TMFArtifact] {
        artifactSearchText.isEmpty ? artifacts : 
        artifacts.filter { 
            $0.name.localizedCaseInsensitiveContains(artifactSearchText) || 
            $0.number.localizedCaseInsensitiveContains(artifactSearchText) 
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter Artifacts")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Select filters to narrow down your artifact search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Filter Options
                    VStack(spacing: 20) {
                        // File Type Filter
                        FilterSection(
                            title: "File Type",
                            selectedValue: $selectedFileType,
                            searchText: $fileTypeSearchText,
                            options: filteredFileTypes.map { FilterOption(id: $0, displayName: $0) },
                            placeholder: "Search file types..."
                        )
                        
                        // Zone Filter
                        FilterSection(
                            title: "Zone",
                            selectedValue: $selectedZone,
                            searchText: $zoneSearchText,
                            options: filteredZones.map { FilterOption(id: $0.number, displayName: "\($0.number) - \($0.name)") },
                            placeholder: "Search zones..."
                        )
                        
                        // Section Filter
                        FilterSection(
                            title: "Section",
                            selectedValue: $selectedSection,
                            searchText: $sectionSearchText,
                            options: filteredSections.map { FilterOption(id: $0.number, displayName: "\($0.number) - \($0.name)") },
                            placeholder: "Search sections..."
                        )
                        
                        // Artifact Filter
                        FilterSection(
                            title: "Artifact",
                            selectedValue: $selectedArtifact,
                            searchText: $artifactSearchText,
                            options: filteredArtifacts.prefix(50).map { FilterOption(id: $0.number, displayName: "\($0.number) - \($0.name)") },
                            placeholder: "Search artifacts..."
                        )
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingResults = true
                        }) {
                            Text("Apply Filters")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                        .disabled(!hasActiveFilters)
                        
                        Button(action: clearAllFilters) {
                            Text("Clear All Filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                FilterResultsView(
                    fileType: selectedFileType,
                    zone: selectedZone,
                    section: selectedSection,
                    artifact: selectedArtifact
                )
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        !selectedFileType.isEmpty || !selectedZone.isEmpty || !selectedSection.isEmpty || !selectedArtifact.isEmpty
    }
    
    private func clearAllFilters() {
        selectedFileType = ""
        selectedZone = ""
        selectedSection = ""
        selectedArtifact = ""
        fileTypeSearchText = ""
        zoneSearchText = ""
        sectionSearchText = ""
        artifactSearchText = ""
    }
}

// MARK: - Supporting Views

struct FilterOption: Identifiable {
    let id: String
    let displayName: String
}

struct FilterSection: View {
    let title: String
    @Binding var selectedValue: String
    @Binding var searchText: String
    let options: [FilterOption]
    let placeholder: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            // Selected Value Display
            if !selectedValue.isEmpty {
                HStack {
                    Text("Selected: \(options.first(where: { $0.id == selectedValue })?.displayName ?? selectedValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedValue = ""
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Expandable Picker Section
            if isExpanded {
                VStack(spacing: 8) {
                    // Search Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField(placeholder, text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Options List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(options.prefix(20)) { option in
                                Button(action: {
                                    selectedValue = option.id
                                    searchText = ""
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isExpanded = false
                                    }
                                }) {
                                    HStack {
                                        Text(option.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        if selectedValue == option.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(selectedValue == option.id ? Color.accentColor.opacity(0.1) : Color.clear)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if option.id != options.last?.id {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FilterResultsView: View {
    let fileType: String
    let zone: String
    let section: String
    let artifact: String
    
    @Environment(\.dismiss) private var dismiss
    
    private var filteredArtifacts: [TMFArtifact] {
        var results = TMFData.zones.flatMap { zone in
            zone.sections.flatMap { $0.artifacts }
        }
        
        // Apply file type filter
        if !fileType.isEmpty {
            results = results.filter { artifact in
                (fileType == "Trial" && artifact.trialLevelDocument == "X") ||
                (fileType == "Country" && artifact.countryLevelDocument == "X") ||
                (fileType == "Site" && artifact.siteLevelDocument == "X")
            }
        }
        
        // Apply zone filter
        if !zone.isEmpty {
            results = results.filter { artifact in
                TMFData.zones.first { z in
                    z.number == zone && z.sections.contains { s in
                        s.artifacts.contains { $0.number == artifact.number }
                    }
                } != nil
            }
        }
        
        // Apply section filter
        if !section.isEmpty {
            results = results.filter { artifact in
                TMFData.zones.contains { z in
                    z.sections.contains { s in
                        s.number == section && s.artifacts.contains { $0.number == artifact.number }
                    }
                }
            }
        }
        
        // Apply artifact filter
        if !artifact.isEmpty {
            results = results.filter { $0.number == artifact }
        }
        
        return results
    }
    
    var body: some View {
        NavigationView {
            List(filteredArtifacts) { artifact in
                NavigationLink(destination: ArtifactDetailView(artifact: artifact)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(artifact.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(artifact.number)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(artifact.definition)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Filter Results (\(filteredArtifacts.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FiltersView()
} 