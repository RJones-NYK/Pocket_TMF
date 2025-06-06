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
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Zone List
            List(TMFData.zones, id: \.number, selection: $selectedZone) { zone in
                ZoneRowView(zone: zone)
                    .tag(zone)
            }
            .navigationTitle("TMF Zones")
            .searchable(text: $searchText, prompt: "Search zones...")
        } detail: {
            // Detail View
            if let selectedZone = selectedZone {
                ZoneDetailView(zone: selectedZone)
            } else {
                TMFOverviewView()
            }
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
