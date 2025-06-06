//
//  ContentView.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedZone: TMFZone?
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var showingFilters = false
    
    // Computed property to get all artifacts for search
    private var allArtifacts: [TMFArtifact] {
        TMFData.zones.flatMap { zone in
            zone.sections.flatMap { section in
                section.artifacts
            }
        }
    }
    
    // Filtered artifacts based on search text
    private var filteredArtifacts: [TMFArtifact] {
        if searchText.isEmpty {
            return []
        }
        return allArtifacts.filter { artifact in
            artifact.name.localizedCaseInsensitiveContains(searchText) ||
            artifact.number.localizedCaseInsensitiveContains(searchText)
        }.prefix(10).map { $0 } // Limit to 10 suggestions
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Zone List with Search
            VStack(spacing: 0) {
                // Type-ahead suggestions - positioned at top below search
                if !searchText.isEmpty && !filteredArtifacts.isEmpty {
                    SearchSuggestionsView(
                        artifacts: filteredArtifacts,
                        onArtifactSelected: { artifact in
                            // Find the zone containing this artifact
                            if let zone = findZoneContaining(artifact: artifact) {
                                selectedZone = zone
                            }
                            searchText = ""
                        }
                    )
                    .zIndex(1) // Ensure it appears above the list
                }
                
                List(TMFData.zones, id: \.number, selection: $selectedZone) { zone in
                    ZoneRowView(zone: zone)
                        .tag(zone)
                }
                .navigationTitle("TMF Zones")
                .searchable(text: $searchText, prompt: "Search artifacts...")
                .onSubmit(of: .search) {
                    if !searchText.isEmpty {
                        showingSearchResults = true
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingFilters = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text("Filters")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingSearchResults) {
                    ArtifactSearchResultsView(
                        searchText: searchText,
                        artifacts: filteredArtifacts,
                        onArtifactSelected: { artifact in
                            // Find the zone containing this artifact
                            if let zone = findZoneContaining(artifact: artifact) {
                                selectedZone = zone
                            }
                            showingSearchResults = false
                        }
                    )
                }
                .sheet(isPresented: $showingFilters) {
                    FiltersView()
                }
            }
        } detail: {
            // Detail View
            if let selectedZone = selectedZone {
                ZoneDetailView(zone: selectedZone)
            } else {
                TMFOverviewView()
            }
        }
    }
    
    // Helper function to find which zone contains a specific artifact
    private func findZoneContaining(artifact: TMFArtifact) -> TMFZone? {
        return TMFData.zones.first { zone in
            zone.sections.contains { section in
                section.artifacts.contains { $0.number == artifact.number }
            }
        }
    }
}

// MARK: - Search Components

struct SearchSuggestionsView: View {
    let artifacts: [TMFArtifact]
    let onArtifactSelected: (TMFArtifact) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(artifacts) { artifact in
                Button(action: {
                    onArtifactSelected(artifact)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artifact.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text(artifact.number)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if artifact.id != artifacts.last?.id {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(0) // Remove corner radius for top positioning
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 0) // Remove horizontal padding for full width
    }
}

struct ArtifactSearchResultsView: View {
    let searchText: String
    let artifacts: [TMFArtifact]
    let onArtifactSelected: (TMFArtifact) -> Void
    
    var body: some View {
        NavigationView {
            List(artifacts) { artifact in
                Button(action: {
                    onArtifactSelected(artifact)
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(artifact.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
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
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ZoneRowView: View {
    let zone: TMFZone
    
    var body: some View {
        HStack {
            // Zone number badge
            Text(zone.number)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(zone.sections.count) sections")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TMFOverviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("TMF Reference Model")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 3.3.1 • August 11, 2023")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Overview Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("The TMF Reference Model provides standardized taxonomy and metadata and outlines a reference definition of TMF content using standard nomenclature.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("The Model is not intended to be used 'off-the-shelf' but can be adapted to an electronic or paper TMF.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Quick Stats
                GroupBox("Quick Statistics") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Zones", value: "\(TMFData.zones.count)")
                        StatCard(title: "Total Sections", value: "\(TMFData.zones.reduce(0) { $0 + $1.sections.count })")
                        StatCard(title: "Total Artifacts", value: "\(TMFData.zones.reduce(0) { $0 + $1.sections.reduce(0) { $0 + $1.artifacts.count } })")
                        StatCard(title: "Version", value: "3.3.1")
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("TMF Reference Model")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
