import SwiftUI

struct RoleSelectionView: View {
    let onSelect: (AppRole) -> Void

    var body: some View {
        ZStack {
            SoccerBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(Color.soccerAccent)

                Text("How will you use Futbol Elite?")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .multilineTextAlignment(.center)

                Text("Choose your role. You can switch roles later by signing out.")
                    .font(.headline)
                    .foregroundStyle(Color.soccerText.opacity(0.65))
                    .multilineTextAlignment(.center)

                roleButton(
                    role: .player,
                    title: "I’m a Player",
                    detail: "Train individually, earn points, and track your progress.",
                    icon: "figure.soccer"
                )

                roleButton(
                    role: .coach,
                    title: "I’m a Coach",
                    detail: "Plan age-appropriate team sessions from U5 through U21.",
                    icon: "person.3.fill"
                )

                Spacer()
            }
            .padding(24)
        }
        .foregroundStyle(Color.soccerText)
    }

    private func roleButton(
        role: AppRole,
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        icon: String
    ) -> some View {
        Button {
            Haptics.tap()
            onSelect(role)
        } label: {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold))
                    .frame(width: 58, height: 58)
                    .background(Color.soccerAccent, in: Circle())
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.heavy)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerText.opacity(0.65))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.soccerAccent)
            }
            .padding(18)
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct CoachSignInView: View {
    @Binding var isSignedIn: Bool
    let onChooseDifferentRole: () -> Void

    @AppStorage("coachName") private var savedCoachName = ""
    @AppStorage("coachPrimaryAgeGroup") private var savedAgeGroup = ""
    @AppStorage("coachTeamName") private var savedTeamName = ""

    @State private var coachName = ""
    @State private var selectedAgeGroup = ""
    @State private var teamName = ""

    private var canContinue: Bool {
        !coachName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedAgeGroup.isEmpty
            && !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            SoccerBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 58))
                            .foregroundStyle(.white)
                        Text("Create Your Coach Profile")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Text("Build better sessions for your team")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        LinearGradient(
                            colors: [Color.soccerAccent, Color.soccerAccentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22)
                    )

                    TextField("Coach name", text: $coachName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 12))

                    TextField("Team name", text: $teamName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What age group do you coach most?")
                            .font(.headline)

                        Picker("Primary age group", selection: $selectedAgeGroup) {
                            Text("Select an age group").tag("")
                            ForEach(CoachAgeGroup.all) { ageGroup in
                                Text(ageGroup.title).tag(ageGroup.title)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Text("You’ll still be able to open drills for every age group from U5 to U21.")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerText.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        let trimmedName = coachName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty, !selectedAgeGroup.isEmpty else { return }
                        savedCoachName = trimmedName
                        savedAgeGroup = selectedAgeGroup
                        savedTeamName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
                        Haptics.success()
                        isSignedIn = true
                    } label: {
                        Label("Open Coaching Drills", systemImage: "list.bullet.clipboard.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canContinue ? Color.soccerAccent : Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(!canContinue)

                    Button("Choose Player Instead", action: onChooseDifferentRole)
                        .font(.headline)
                }
                .padding(24)
            }
        }
        .foregroundStyle(Color.soccerText)
    }
}



private struct CoachDrillSection: Identifiable {
    let category: CoachDrillCategory
    let drills: [CoachDrill]

    var id: CoachDrillCategory { category }
}

struct CoachContentView: View {
    var body: some View {
        TabView {
            CoachDrillsTabView()
                .tabItem {
                    Label("Drills", systemImage: "list.bullet.clipboard.fill")
                }

            CoachTeamView()
                .tabItem {
                    Label("Team", systemImage: "person.3.fill")
                }

            CoachScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }

            CoachCustomDrillsView()
                .tabItem {
                    Label("Create", systemImage: "square.and.pencil")
                }

            CoachTipsView()
                .tabItem {
                    Label("Coaching Tips", systemImage: "lightbulb.fill")
                }

            CoachProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(Color.soccerAccent)
    }
}

private struct CoachDrillsTabView: View {
    @AppStorage("hasCompletedOnboarding") private var isSignedIn = false
    @AppStorage("accountRole") private var accountRole = ""
    @AppStorage("coachName") private var coachName = ""
    @AppStorage("coachPrimaryAgeGroup") private var primaryAgeGroup = ""

    @State private var selectedAge = 0
    @State private var selectedCategory = "All"
    @State private var maximumDuration = 0
    @State private var searchText = ""
    @State private var showSignOutConfirmation = false

    private var selectedAgeGroup: CoachAgeGroup? {
        guard selectedAge > 0 else { return nil }
        return CoachAgeGroup(age: selectedAge)
    }

    private var categoryFilter: CoachDrillCategory? {
        CoachDrillCategory(rawValue: selectedCategory)
    }

    private var filteredDrills: [CoachDrill] {
        CoachDrillLibrary.drills(
            recommendedFor: selectedAgeGroup,
            category: categoryFilter
        )
        .filter { drill in
            maximumDuration == 0 || drill.durationMinutes <= maximumDuration
        }
        .filter { drill in
            searchText.isEmpty
                || drill.name.localizedCaseInsensitiveContains(searchText)
                || drill.category.rawValue.localizedCaseInsensitiveContains(searchText)
                || drill.players.localizedCaseInsensitiveContains(searchText)
                || drill.setup.localizedCaseInsensitiveContains(searchText)
                || drill.coachingFocus.localizedCaseInsensitiveContains(searchText)
                || drill.equipment.contains {
                    $0.localizedCaseInsensitiveContains(searchText)
                }
        }
    }

    private var sections: [CoachDrillSection] {
        CoachDrillCategory.allCases.compactMap { category in
            let categoryDrills = filteredDrills.filter { $0.category == category }
            guard !categoryDrills.isEmpty else { return nil }
            return CoachDrillSection(category: category, drills: categoryDrills)
        }
    }

    private var primaryAge: Int? {
        Int(primaryAgeGroup.dropFirst())
    }

    private var hasActiveFilters: Bool {
        selectedAge != 0 || selectedCategory != "All" || maximumDuration != 0 || !searchText.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    coachHeader
                    filters

                    HStack {
                        Text("Showing \(filteredDrills.count) coaching drills")
                            .font(.headline)
                            .foregroundStyle(Color.soccerText.opacity(0.7))
                            .contentTransition(.numericText())

                        Spacer()

                        if hasActiveFilters {
                            Button("Clear Filters", systemImage: "xmark.circle.fill") {
                                selectedAge = 0
                                selectedCategory = "All"
                                maximumDuration = 0
                                searchText = ""
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                        }
                    }

                    if filteredDrills.isEmpty {
                        ContentUnavailableView(
                            "No Matching Drills",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different age group, category, or search.")
                        )
                    }

                    ForEach(sections) { section in
                        drillSection(section)
                    }
                }
                .padding()
            }
            .background(SoccerBackgroundView())
            .foregroundStyle(Color.soccerText)
            .navigationTitle("Coaching Drills")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name, skill, setup, or equipment")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                        showSignOutConfirmation = true
                    }
                }
            }
            .confirmationDialog(
                "Sign out of your coach profile?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    accountRole = ""
                    isSignedIn = false
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                if selectedAge == 0, let primaryAge {
                    selectedAge = primaryAge
                }
            }
        }
        .tint(Color.soccerAccent)
    }

    private var coachHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Welcome, Coach \(coachName)", systemImage: "person.3.fill")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(.white)

            Text("Browse \(CoachDrillLibrary.allDrills.count) team drills. Filter by age or skill, then open any drill for equipment and setup.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))

            if let primaryAge {
                Button {
                    withAnimation(.snappy) {
                        selectedAge = primaryAge
                    }
                } label: {
                    Label(
                        "Show recommendations for U\(primaryAge)",
                        systemImage: "star.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white, in: Capsule())
                    .foregroundStyle(Color.soccerAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.soccerAccent, Color.soccerAccentLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended age")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    filterButton(title: "All ages", isSelected: selectedAge == 0) {
                        selectedAge = 0
                    }

                    ForEach(CoachAgeGroup.all) { ageGroup in
                        filterButton(
                            title: ageGroup.title,
                            isSelected: selectedAge == ageGroup.age
                        ) {
                            selectedAge = ageGroup.age
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            Text("Training category")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    filterButton(title: "All", isSelected: selectedCategory == "All") {
                        selectedCategory = "All"
                    }

                    ForEach(CoachDrillCategory.allCases) { category in
                        filterButton(
                            title: category.rawValue,
                            isSelected: selectedCategory == category.rawValue,
                            icon: category.systemImage
                        ) {
                            selectedCategory = category.rawValue
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            Text("Maximum time")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    filterButton(title: "Any", isSelected: maximumDuration == 0) {
                        maximumDuration = 0
                    }
                    filterButton(title: "10 min", isSelected: maximumDuration == 10, icon: "clock") {
                        maximumDuration = 10
                    }
                    filterButton(title: "15 min", isSelected: maximumDuration == 15, icon: "clock") {
                        maximumDuration = 15
                    }
                    filterButton(title: "20 min", isSelected: maximumDuration == 20, icon: "clock") {
                        maximumDuration = 20
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func filterButton(
        title: String,
        isSelected: Bool,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.snappy) {
                action()
            }
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.soccerAccent : Color.soccerSurface,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : Color.soccerText)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func drillSection(_ section: CoachDrillSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(section.category.rawValue, systemImage: section.category.systemImage)
                    .font(.title2)
                    .fontWeight(.heavy)
                Spacer()
                Text("\(section.drills.count) drills")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(section.drills) { drill in
                NavigationLink {
                    CoachDrillDetailView(drill: drill)
                } label: {
                    CoachDrillRow(drill: drill)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CoachTipsView: View {
    private let tips: [(title: String, detail: String, icon: String)] = [
        ("Plan one main goal", "Choose one skill for the session so every activity connects.", "target"),
        ("Keep instructions short", "Show the activity, explain one or two points, then let players begin.", "text.bubble.fill"),
        ("Give every player touches", "Use small groups and several balls so nobody waits in a long line.", "soccerball"),
        ("Coach what you see", "Watch a full repetition before stopping play to offer feedback.", "eye.fill"),
        ("Praise specific actions", "Say exactly what worked, such as a good first touch or support angle.", "hand.thumbsup.fill"),
        ("Ask simple questions", "Help players think by asking what they saw or what they could try next.", "questionmark.bubble.fill"),
        ("Progress gradually", "Start without pressure, add a defender, then finish with a game.", "chart.line.uptrend.xyaxis"),
        ("Make it game-like", "Add direction, goals, teammates, opponents, and decisions when players are ready.", "person.3.fill"),
        ("Include water breaks", "Plan regular recovery, especially in hot weather or intense sessions.", "drop.fill"),
        ("End with a recap", "Ask players for one thing they learned and preview the next session.", "checkmark.circle.fill"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(tips, id: \.title) { tip in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: tip.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.soccerAccent, in: Circle())

                            VStack(alignment: .leading, spacing: 5) {
                                Text(tip.title)
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                Text(tip.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.soccerText.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding()
            }
            .background(SoccerBackgroundView())
            .foregroundStyle(Color.soccerText)
            .navigationTitle("Coaching Tips")
        }
    }
}

private struct CoachProfileView: View {
    @AppStorage("hasCompletedOnboarding") private var isSignedIn = false
    @AppStorage("accountRole") private var accountRole = ""
    @AppStorage("coachName") private var coachName = ""
    @AppStorage("coachPrimaryAgeGroup") private var primaryAgeGroup = ""
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(Color.soccerAccent)

                    Text(coachName)
                        .font(.largeTitle)
                        .fontWeight(.heavy)

                    VStack(spacing: 12) {
                        profileRow(title: "Role", value: "Coach", icon: "person.3.fill")
                        profileRow(
                            title: "Primary team",
                            value: primaryAgeGroup.isEmpty ? "Not selected" : primaryAgeGroup,
                            icon: "star.fill"
                        )
                        profileRow(
                            title: "Drill library",
                            value: "\(CoachDrillLibrary.allDrills.count) drills",
                            icon: "list.bullet.clipboard.fill"
                        )
                    }

                    NavigationLink {
                        CoachPlusView()
                    } label: {
                        HStack {
                            Label("Coach Plus", systemImage: "crown.fill")
                                .font(.headline)
                            Spacer()
                            Text("Advanced plans")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(colors: [Color.soccerAccent, .purple], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .background(SoccerBackgroundView())
            .foregroundStyle(Color.soccerText)
            .navigationTitle("Coach Profile")
            .confirmationDialog(
                "Sign out of Futbol Elite?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    accountRole = ""
                    isSignedIn = false
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func profileRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .fontWeight(.bold)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct CoachDrillRow: View {
    let drill: CoachDrill

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: drill.category.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.soccerAccent, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(drill.name)
                    .font(.headline)
                    .fontWeight(.heavy)

                Text(drill.recommendedAges)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.soccerAccent.opacity(0.12), in: Capsule())

                HStack(spacing: 12) {
                    Label("\(drill.durationMinutes) min", systemImage: "clock.fill")
                    Label(drill.players, systemImage: "person.3.fill")
                }
                .font(.caption)
                .foregroundStyle(Color.soccerText.opacity(0.65))

                Text("Equipment: \(drill.equipment.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(Color.soccerText.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .foregroundStyle(Color.soccerAccent)
        }
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CoachDrillDetailView: View {
    let drill: CoachDrill

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: drill.category.systemImage)
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.white)
                    Text(drill.name)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Text(drill.category.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(drill.recommendedAges)
                        .font(.headline)
                        .fontWeight(.heavy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white, in: Capsule())
                        .foregroundStyle(Color.soccerAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(
                    LinearGradient(
                        colors: [Color.soccerAccent, Color.soccerAccentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22)
                )

                HStack(spacing: 12) {
                    fact(title: "TIME", value: "\(drill.durationMinutes) min", icon: "clock.fill")
                    fact(title: "GROUP", value: drill.players, icon: "person.3.fill")
                }

                detailSection(
                    title: "Equipment",
                    icon: "shippingbox.fill",
                    text: drill.equipment.joined(separator: ", ")
                )
                detailSection(title: "Setup", icon: "square.grid.3x3.fill", text: drill.setup)
                detailSection(
                    title: "Coaching Focus",
                    icon: "lightbulb.fill",
                    text: drill.coachingFocus
                )

                NavigationLink {
                    AssignedDrillTimerView(
                        title: drill.name,
                        details: "Setup: \(drill.setup)\n\nCoaching focus: \(drill.coachingFocus)",
                        minutes: drill.durationMinutes
                    )
                } label: {
                    Label("Start \(drill.durationMinutes)-Minute Timer", systemImage: "timer")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Drill Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fact(title: LocalizedStringKey, value: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(Color.soccerAccent)
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
            Text(value)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(8)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func detailSection(
        title: LocalizedStringKey,
        icon: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerAccent)
            Text(text)
                .font(.body)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
    }
}
