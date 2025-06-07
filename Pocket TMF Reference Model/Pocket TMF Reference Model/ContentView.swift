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
    @State private var showingSettings = false
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var appIconManager = AppIconManager()
    @Environment(\.colorScheme) var colorScheme
    
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
                    .environmentObject(colorSchemeManager)
                    .zIndex(1) // Ensure it appears above the list
                }
                
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
                            // Find the zone containing this artifact
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
            if let selectedZone = selectedZone {
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

// MARK: - Search Components

struct SearchSuggestionsView: View {
    let artifacts: [TMFArtifact]
    let onArtifactSelected: (TMFArtifact) -> Void
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
        .cornerRadius(0) // Remove corner radius for top positioning
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        .padding(.horizontal, 0) // Remove horizontal padding for full width
    }
}

struct ArtifactSearchResultsView: View {
    let searchText: String
    let artifacts: [TMFArtifact]
    let onArtifactSelected: (TMFArtifact) -> Void
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @Environment(\.colorScheme) var colorScheme
    
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
                .listRowBackground(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
            }
            .scrollContentBackground(.hidden)
            .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ZoneRowView: View {
    let zone: TMFZone
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        HStack {
            // Zone number badge
            Text(zone.number)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(colorSchemeManager.selectedScheme.color)
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
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @Environment(\.colorScheme) var colorScheme
    
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
                            .environmentObject(colorSchemeManager)
                        StatCard(title: "Total Sections", value: "\(TMFData.zones.reduce(0) { $0 + $1.sections.count })")
                            .environmentObject(colorSchemeManager)
                        StatCard(title: "Total Artifacts", value: "\(TMFData.zones.reduce(0) { $0 + $1.sections.reduce(0) { $0 + $1.artifacts.count } })")
                            .environmentObject(colorSchemeManager)
                        StatCard(title: "Version", value: "3.3.1")
                            .environmentObject(colorSchemeManager)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("TMF Reference Model")
        .navigationBarTitleDisplayMode(.inline)
        .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(colorSchemeManager.selectedScheme.color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Theme Management

enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: SwiftUI.ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

struct ColorScheme: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
    let hexValue: String
    
    static let availableSchemes = [
        ColorScheme(name: "Green", color: Color(hex: "#5EBD3E"), hexValue: "#5EBD3E"),
        ColorScheme(name: "Yellow", color: Color(hex: "#FFB900"), hexValue: "#FFB900"),
        ColorScheme(name: "Orange", color: Color(hex: "#F78200"), hexValue: "#F78200"),
        ColorScheme(name: "Red", color: Color(hex: "#E23838"), hexValue: "#E23838"),
        ColorScheme(name: "Purple", color: Color(hex: "#973999"), hexValue: "#973999"),
        ColorScheme(name: "Blue", color: Color(hex: "#009CDF"), hexValue: "#009CDF")
    ]
    
    static let defaultScheme = availableSchemes.last! // Blue (#009CDF)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom View Modifiers

struct CustomBackgroundModifier: ViewModifier {
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @Environment(\.colorScheme) var colorScheme
    let priority: BackgroundPriority
    
    enum BackgroundPriority {
        case primary
        case secondary
        case tertiary
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColorForPriority())
    }
    
    private func backgroundColorForPriority() -> Color {
        switch priority {
        case .primary:
            return colorSchemeManager.primaryBackgroundColor(for: colorScheme)
        case .secondary:
            return colorSchemeManager.secondaryBackgroundColor(for: colorScheme)
        case .tertiary:
            return colorSchemeManager.tertiaryBackgroundColor(for: colorScheme)
        }
    }
}

extension View {
    func customBackground(_ priority: CustomBackgroundModifier.BackgroundPriority = .primary) -> some View {
        self.modifier(CustomBackgroundModifier(priority: priority))
    }
}

// MARK: - App Icon Management

struct AppIcon: Identifiable, Equatable {
    let id: String
    let name: String
    let lightIconName: String
    let darkIconName: String
    let bundleName: String?
    
    static let availableIcons = [
        AppIcon(
            id: "default",
            name: "Default",
            lightIconName: "New Home",
            darkIconName: "New Home_Dark",
            bundleName: nil
        ),
        AppIcon(
            id: "veryOrange",
            name: "Very Orange",
            lightIconName: "Very Orange",
            darkIconName: "Very Orange_Dark",
            bundleName: "Very Orange"
        )
    ]
}

class AppIconManager: ObservableObject {
    @Published var selectedIcon: AppIcon {
        didSet {
            setAppIcon(selectedIcon)
            UserDefaults.standard.set(selectedIcon.id, forKey: "selectedAppIcon")
        }
    }
    
    init() {
        let savedIconId = UserDefaults.standard.string(forKey: "selectedAppIcon") ?? "default"
        self.selectedIcon = AppIcon.availableIcons.first { $0.id == savedIconId } ?? AppIcon.availableIcons[0]
    }
    
    private func setAppIcon(_ icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        UIApplication.shared.setAlternateIconName(icon.bundleName) { error in
            if let error = error {
                print("Error setting alternate app icon: \(error.localizedDescription)")
            }
        }
    }
    
    var supportsAlternateIcons: Bool {
        return UIApplication.shared.supportsAlternateIcons
    }
}

class ColorSchemeManager: ObservableObject {
    @Published var selectedScheme: ColorScheme {
        didSet {
            UserDefaults.standard.set(selectedScheme.hexValue, forKey: "selectedColorScheme")
        }
    }
    
    @Published var selectedThemeMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(selectedThemeMode.rawValue, forKey: "selectedThemeMode")
        }
    }
    
    init() {
        let savedHex = UserDefaults.standard.string(forKey: "selectedColorScheme") ?? ColorScheme.defaultScheme.hexValue
        self.selectedScheme = ColorScheme.availableSchemes.first { $0.hexValue == savedHex } ?? ColorScheme.defaultScheme
        
        let savedTheme = UserDefaults.standard.string(forKey: "selectedThemeMode") ?? ThemeMode.system.rawValue
        self.selectedThemeMode = ThemeMode(rawValue: savedTheme) ?? .system
    }
    
    // Custom background colors - Dark blue theme for dark mode, warm off-white for light mode
    func primaryBackgroundColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.078, green: 0.089, blue: 0.161) // #141729 - Cursor-like dark blue
        case .light:
            return Color(red: 0.980, green: 0.976, blue: 0.969) // #FAF9F7 - Warm off-white
        @unknown default:
            return Color(.systemBackground)
        }
    }
    
    func secondaryBackgroundColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.098, green: 0.109, blue: 0.180) // #191C2E - Slightly lighter dark blue
        case .light:
            return Color(red: 0.973, green: 0.969, blue: 0.961) // #F8F7F5 - Slightly darker warm off-white
        @unknown default:
            return Color(.secondarySystemBackground)
        }
    }
    
    func tertiaryBackgroundColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.118, green: 0.129, blue: 0.200) // #1E2133 - Even lighter dark blue
        case .light:
            return Color(red: 0.965, green: 0.961, blue: 0.953) // #F6F5F3 - Even more muted warm off-white
        @unknown default:
            return Color(.tertiarySystemBackground)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @EnvironmentObject var appIconManager: AppIconManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isThemeChanging = false
    @State private var showingAppIcons = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    // Theme Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Theme")
                                .font(.headline)
                            
                            Spacer()
                            
                            if isThemeChanging {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorSchemeManager.selectedScheme.color))
                            }
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(ThemeMode.allCases) { theme in
                                ThemeSelectionRow(
                                    theme: theme,
                                    isSelected: theme == colorSchemeManager.selectedThemeMode,
                                    isChanging: isThemeChanging,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isThemeChanging = true
                                        }
                                        
                                        // Slight delay to show the loading animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            colorSchemeManager.selectedThemeMode = theme
                                            
                                            // Hide loading animation after theme change
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isThemeChanging = false
                                                }
                                            }
                                        }
                                    }
                                )
                                .environmentObject(colorSchemeManager)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Color Scheme Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color Scheme")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(ColorScheme.availableSchemes) { scheme in
                                ColorSchemeButton(
                                    scheme: scheme,
                                    isSelected: scheme.id == colorSchemeManager.selectedScheme.id,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            colorSchemeManager.selectedScheme = scheme
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // App Icons Navigation Section
                if appIconManager.supportsAlternateIcons {
                    Section("App Icons") {
                        Button(action: {
                            showingAppIcons = true
                        }) {
                            HStack {
                                // Current app icon preview
                                VStack(spacing: 4) {
                                    if let currentImage = UIImage(named: appIconManager.selectedIcon.lightIconName) {
                                        Image(uiImage: currentImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 9))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 9)
                                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color.secondary.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Alternative App Icons")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Currently using: \(appIconManager.selectedIcon.name)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section("About") {
                    // TMF Reference Model Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The TMF Reference Model initiative was formerly a sub-group of the Document and Records Management Community of the Drug Information Association (DIA). Since June 2022, it has become part of CDISC. The TMF Reference Model initiative is governed by the rules and procedures of CDISC but the work products are a Public Domain work.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Text("Reference Model Version")
                        Spacer()
                        Text("3.3.1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Release Date")
                        Spacer()
                        Text("August 11, 2023")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("To find out more about the CDISC Reference Model please visit ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            + Text("https://www.cdisc.org/tmf")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://www.cdisc.org/tmf") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAppIcons) {
                AppIconsView()
                    .environmentObject(colorSchemeManager)
                    .environmentObject(appIconManager)
            }
        }
        .preferredColorScheme(colorSchemeManager.selectedThemeMode.colorScheme)
    }
}

struct ThemeSelectionRow: View {
    let theme: ThemeMode
    let isSelected: Bool
    let isChanging: Bool
    let onSelect: () -> Void
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: themeIcon)
                    .foregroundColor(isSelected ? colorSchemeManager.selectedScheme.color : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)
                    
                    Text(themeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colorSchemeManager.selectedScheme.color)
                        .opacity(isChanging ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isChanging)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? colorSchemeManager.selectedScheme.color.opacity(isChanging ? 0.05 : 0.1) : Color.clear)
            .cornerRadius(8)
            .opacity(isChanging && !isSelected ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.2), value: isChanging)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isChanging)
    }
    
    private var themeIcon: String {
        switch theme {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "gear"
        }
    }
    
    private var themeDescription: String {
        switch theme {
        case .light: return "Always use light appearance"
        case .dark: return "Always use dark appearance"
        case .system: return "Follow system preference"
        }
    }
}

struct ColorSchemeButton: View {
    let scheme: ColorScheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Circle()
                    .fill(scheme.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: isSelected ? 3 : 0.5)
                            .opacity(isSelected ? 1 : 0.3)
                    )
                
                Text(scheme.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Icons View

struct AppIconsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @EnvironmentObject var appIconManager: AppIconManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedIcon: AppIcon
    
    init() {
        // We'll set this properly in the init method
        _selectedIcon = State(initialValue: AppIcon.availableIcons[0])
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Your App Icon")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Select your preferred app icon that will appear on your home screen. Changes take effect immediately.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Current selection indicator
                    if selectedIcon.id != appIconManager.selectedIcon.id {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(colorSchemeManager.selectedScheme.color)
                            
                            Text("Tap 'Apply' to use the selected icon")
                                .font(.subheadline)
                                .foregroundColor(colorSchemeManager.selectedScheme.color)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(colorSchemeManager.selectedScheme.color.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // App Icon Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 20) {
                        ForEach(AppIcon.availableIcons) { icon in
                            AppIconDetailView(
                                icon: icon,
                                isSelected: icon.id == selectedIcon.id,
                                onSelect: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedIcon = icon
                                    }
                                }
                            )
                            .environmentObject(colorSchemeManager)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Apply Button
                    if selectedIcon.id != appIconManager.selectedIcon.id {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appIconManager.selectedIcon = selectedIcon
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Apply Selected Icon")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorSchemeManager.selectedScheme.color)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(colorSchemeManager.primaryBackgroundColor(for: colorScheme))
            .navigationTitle("App Icons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedIcon = appIconManager.selectedIcon
        }
    }
}

struct AppIconDetailView: View {
    let icon: AppIcon
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon preview container with both light and dark variants
                HStack(spacing: 12) {
                    // Light mode icon
                    VStack(spacing: 4) {
                        if let lightImage = UIImage(named: icon.lightIconName) {
                            Image(uiImage: lightImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 60, height: 60)
                        }
                        
                        Text("Light")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Dark mode icon
                    VStack(spacing: 4) {
                        if let darkImage = UIImage(named: icon.darkIconName) {
                            Image(uiImage: darkImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 60, height: 60)
                        }
                        
                        Text("Dark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Icon details
                VStack(alignment: .leading, spacing: 4) {
                    Text(icon.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Adapts to your device theme")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(colorSchemeManager.selectedScheme.color)
                            Text("Selected")
                                .font(.subheadline)
                                .foregroundColor(colorSchemeManager.selectedScheme.color)
                                .fontWeight(.medium)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(20)
                                .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? colorSchemeManager.selectedScheme.color.opacity(0.1) : colorSchemeManager.secondaryBackgroundColor(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? colorSchemeManager.selectedScheme.color : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ContentView()
}
