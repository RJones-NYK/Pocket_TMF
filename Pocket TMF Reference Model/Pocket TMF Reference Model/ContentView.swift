//
//  ContentView.swift
//  Pocket TMF Reference Model
//
//  Created by Robert Jones on 06/06/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedZone: TMFZone?
    @State private var selectedArtifactFromSearch: TMFArtifact?
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var showingFilters = false
    @State private var showingSettings = false
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var appIconManager = AppIconManager()
    @Environment(\.colorScheme) var colorScheme
    
    private enum Constants {
        static let searchSuggestionsTopPadding: CGFloat = 60
        static let maxSearchResults = 25
    }
    
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
        guard !searchText.isEmpty else { return [] }
        
        return allArtifacts.filter { artifact in
            artifact.name.localizedCaseInsensitiveContains(searchText) ||
            artifact.number.localizedCaseInsensitiveContains(searchText)
        }.prefix(Constants.maxSearchResults).map { $0 }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Zone List with Search
            VStack(spacing: 0) {
                List(TMFData.zones, id: \.number, selection: $selectedZone) { zone in
                    ZoneRowView(zone: zone)
                        .tag(zone)
                        .environmentObject(colorSchemeManager)
                        .listRowBackground(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
                }
                .scrollContentBackground(.hidden)
                .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
                .navigationTitle("TMF Zones")
                .searchable(text: $searchText, prompt: "Search artifacts...")
                .onSubmit(of: .search) {
                    if !searchText.isEmpty {
                        showingSearchResults = true
                    }
                }
                .onChange(of: selectedZone) { _, newZone in
                    // Clear selected artifact from search when a different zone is selected
                    if let selectedArtifact = selectedArtifactFromSearch,
                       let newZone = newZone,
                       let artifactZone = findZoneContaining(artifact: selectedArtifact),
                       artifactZone.number != newZone.number {
                        selectedArtifactFromSearch = nil
                    }
                }
                .overlay(alignment: .top) {
                    // Search suggestions overlay positioned under the search bar
                    if !searchText.isEmpty && !filteredArtifacts.isEmpty {
                        SearchSuggestionsView(
                            artifacts: filteredArtifacts,
                            onArtifactSelected: { artifact in
                                // Set the selected artifact for direct navigation
                                selectedArtifactFromSearch = artifact
                                // Also find and set the zone containing this artifact
                                if let zone = findZoneContaining(artifact: artifact) {
                                    selectedZone = zone
                                }
                                searchText = ""
                            }
                        )
                        .environmentObject(colorSchemeManager)
                        .padding(.top, Constants.searchSuggestionsTopPadding) // Position below the search bar
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .zIndex(1000) // Ensure it appears above everything
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                    
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
                            // Set the selected artifact for direct navigation
                            selectedArtifactFromSearch = artifact
                            // Also find and set the zone containing this artifact
                            if let zone = findZoneContaining(artifact: artifact) {
                                selectedZone = zone
                            }
                            showingSearchResults = false
                        }
                    )
                    .environmentObject(colorSchemeManager)
                }
                .sheet(isPresented: $showingFilters) {
                    FiltersView()
                        .environmentObject(colorSchemeManager)
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(colorSchemeManager)
                        .environmentObject(appIconManager)
                }
            }
        } detail: {
            // Detail View
            if let selectedArtifact = selectedArtifactFromSearch {
                NavigationStack {
                    ArtifactDetailView(artifact: selectedArtifact)
                        .environmentObject(colorSchemeManager)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Back to Zone") {
                                    selectedArtifactFromSearch = nil
                                }
                            }
                        }
                }
            } else if let selectedZone = selectedZone {
                ZoneDetailView(zone: selectedZone)
                    .environmentObject(colorSchemeManager)
            } else {
                TMFOverviewView()
                    .environmentObject(colorSchemeManager)
            }
        }
        .preferredColorScheme(colorSchemeManager.selectedThemeMode.colorScheme)
        .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
        .toolbarBackground(colorSchemeManager.primaryBackgroundColor(for: colorScheme), for: .navigationBar)
        .toolbarBackground(colorSchemeManager.primaryBackgroundColor(for: colorScheme), for: .tabBar)
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


#Preview {
    ContentView()
}
