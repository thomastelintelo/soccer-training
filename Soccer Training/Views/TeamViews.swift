import SwiftUI

struct CoachTeamView: View {
    @AppStorage("coachName") private var coachName = ""
    @AppStorage("coachPrimaryAgeGroup") private var ageGroup = ""
    @AppStorage("coachTeamName") private var savedTeamName = ""
    @AppStorage("coachTeamCode") private var teamCode = ""
    @State private var store = TeamCloudKitStore()
    @State private var teamName = ""
    @State private var showAssign = false
    @State private var assignmentTargetID = "team"
    @State private var playerPendingRemoval: TeamMember?
    @State private var playerBeingEdited: TeamMember?

    var body: some View {
        NavigationStack {
            Group {
                if teamCode.isEmpty { makeTeamView } else { teamView }
            }
            .background(SoccerBackgroundView())
            .navigationTitle("My Team")
            .task(id: teamCode) {
                if teamName.isEmpty { teamName = savedTeamName }
                guard !teamCode.isEmpty else { return }

                // Player registrations are separate CloudKit records so players
                // using another iCloud account can join safely. Poll while this
                // screen is visible so new players appear without reopening it.
                while !Task.isCancelled {
                    await store.loadTeam(code: teamCode)
                    try? await Task.sleep(for: .seconds(5))
                }
            }
            .refreshable {
                if !teamCode.isEmpty { await store.loadTeam(code: teamCode) }
            }
            .sheet(isPresented: $showAssign) {
                AssignTrainingSheet(store: store, initialTargetID: assignmentTargetID)
            }
            .sheet(item: $playerBeingEdited) { member in
                EditPlayerSheet(member: member) { name, age, position in
                    Task { await store.updatePlayer(member.id, name: name, age: age, position: position) }
                }
            }
            .confirmationDialog(
                "Remove \(playerPendingRemoval?.name ?? "this player")?",
                isPresented: Binding(
                    get: { playerPendingRemoval != nil },
                    set: { if !$0 { playerPendingRemoval = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove Player", role: .destructive) {
                    guard let memberID = playerPendingRemoval?.id else { return }
                    playerPendingRemoval = nil
                    Task { await store.removePlayer(memberID) }
                }
                Button("Cancel", role: .cancel) {
                    playerPendingRemoval = nil
                }
            } message: {
                Text("This player and their individual assignments will be removed from the team.")
            }
        }
        .tint(Color.soccerAccent)
    }

    private var makeTeamView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 72)).foregroundStyle(Color.soccerAccent)
                Text("Make a Team").font(.largeTitle.bold())
                Text("Create a team code that players can enter on their own phones.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                TextField("Team name", text: $teamName)
                    .textInputAutocapitalization(.words).teamField()
                Button {
                    Task {
                        let name = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        if let code = await store.createTeam(teamName: name, coachName: coachName, ageGroup: ageGroup) {
                            savedTeamName = name
                            teamCode = code
                            Haptics.success()
                        }
                    }
                } label: {
                    Label("Make My Team", systemImage: "plus.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isLoading || teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                errorText
            }.padding()
        }
    }

    private var teamView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let team = store.workspace {
                    VStack(spacing: 8) {
                        Text(team.teamName).font(.title.bold()).foregroundStyle(.white)
                        Text(team.ageGroup).font(.headline).foregroundStyle(.white.opacity(0.85))
                        Text("JOIN CODE").font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
                        Text(team.joinCode).font(.system(.largeTitle, design: .rounded, weight: .black))
                            .tracking(5).foregroundStyle(.white)
                        ShareLink(item: "Join my Futbol Elite team with code \(team.joinCode)") {
                            Label("Share Code", systemImage: "square.and.arrow.up")
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(.white, in: Capsule()).foregroundStyle(Color.soccerAccent)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(22)
                    .background(Color.soccerAccent.gradient, in: RoundedRectangle(cornerRadius: 22))

                    HStack {
                        Text("Players (\(team.members.count))").font(.title2.bold())
                        Spacer()
                        Button {
                            Task { await store.loadTeam(code: teamCode) }
                        } label: {
                            Label("Check for Players", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.isLoading)
                    }
                    if team.members.isEmpty {
                        Text("Share the team code. Players appear here automatically after they join.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding().background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                    }
                    ForEach(team.members) { member in
                        VStack(spacing: 12) {
                            HStack {
                                Button {
                                    Task { await store.toggleCaptain(member.id) }
                                } label: {
                                    Image(systemName: member.isCaptain ? "star.fill" : "star")
                                        .font(.title2).foregroundStyle(member.isCaptain ? .yellow : .secondary)
                                }
                                VStack(alignment: .leading) {
                                    Text(member.name).font(.headline)
                                    Text("Age \(member.age) • \(member.position)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(member.points) pts").font(.headline).foregroundStyle(Color.soccerAccent)
                                Button("+10") { Task { await store.addPoints(10, to: member.id) } }
                                    .buttonStyle(.bordered)
                                Button {
                                    playerBeingEdited = member
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Edit \(member.name)")
                                Button(role: .destructive) {
                                    playerPendingRemoval = member
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Remove \(member.name)")
                            }

                            Button {
                                assignmentTargetID = member.id.uuidString
                                showAssign = true
                            } label: {
                                Label("Assign Training to \(member.name)", systemImage: "paperplane.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }.padding().background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        assignmentTargetID = "team"
                        showAssign = true
                    } label: {
                        Label("Assign Training to Whole Team", systemImage: "person.3.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                    }.buttonStyle(.borderedProminent)

                    Text("Recent assignments").font(.title2.bold())
                    ForEach(team.assignments.prefix(20)) { assignment in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(assignment.title).font(.headline)
                                Spacer()
                                Button(role: .destructive) {
                                    Task { await store.removeAssignment(assignment.id) }
                                } label: { Image(systemName: "trash") }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("Delete \(assignment.title)")
                            }
                            Text(assignment.assignedMemberID.flatMap { id in team.members.first(where: { $0.id == id })?.name } ?? "Whole team")
                                .font(.caption.bold()).foregroundStyle(Color.soccerAccent)
                            if !assignment.details.isEmpty { Text(assignment.details).font(.subheadline) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding()
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                    }
                } else if store.isLoading {
                    ProgressView("Loading team…").frame(maxWidth: .infinity).padding(.top, 80)
                }
                errorText
            }.padding()
        }
    }

    @ViewBuilder private var errorText: some View {
        if let message = store.errorMessage { Text(message).foregroundStyle(.red).font(.footnote) }
    }
}

struct PlayerTeamView: View {
    @AppStorage("playerUsername") private var playerName = ""
    @AppStorage("playerAge") private var playerAge = 0
    @AppStorage("playerPosition") private var playerPosition = ""
    @AppStorage("playerTeamCode") private var teamCode = ""
    @AppStorage("playerTeamMemberID") private var memberIDText = ""
    @AppStorage("totalPoints") private var totalPoints = 0
    @State private var store = TeamCloudKitStore()
    @State private var isConfirmingLeave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if teamCode.isEmpty {
                    ContentUnavailableView(
                        "Join a Team from Profile",
                        systemImage: "person.badge.plus",
                        description: Text("Return to your Profile and enter the code from your coach.")
                    )
                } else {
                    assignmentsView
                }
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .navigationTitle("My Team")
        .task(id: teamCode) { if !teamCode.isEmpty { await store.loadTeam(code: teamCode) } }
        .refreshable { if !teamCode.isEmpty { await store.loadTeam(code: teamCode) } }
        .tint(Color.soccerAccent)
        .toolbar {
            if !teamCode.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Leave Team", role: .destructive) { isConfirmingLeave = true }
                }
            }
        }
        .confirmationDialog("Leave this team?", isPresented: $isConfirmingLeave, titleVisibility: .visible) {
            Button("Leave Team", role: .destructive) {
                Task {
                    if let id = UUID(uuidString: memberIDText) {
                        await store.leaveTeam(code: teamCode, memberID: id)
                        guard store.errorMessage == nil else { return }
                    }
                    teamCode = ""
                    memberIDText = ""
                    Haptics.soft()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll be removed from the coach's roster. You can rejoin later with the team code.")
        }
    }

    /// Real player drill this assignment maps to, if any (older assignments match by title).
    private func playerDrillName(for assignment: TeamAssignment) -> String? {
        if let name = assignment.playerDrillName { return name }
        let known = DrillPresentation.categories.contains { $0.drills.contains(assignment.title) }
        return known ? assignment.title : nil
    }

    private var assignmentsView: some View {
        Group {
            if let team = store.workspace {
                VStack(alignment: .leading, spacing: 18) {
                    Text(team.teamName).font(.largeTitle.bold())
                    if let me = team.members.first(where: { $0.id.uuidString == memberIDText }) {
                        Label("\(me.points) team points", systemImage: me.isCaptain ? "star.fill" : "trophy.fill")
                            .font(.headline).foregroundStyle(Color.soccerAccent)
                    }
                    Text("Drills from Coach \(team.coachName)").font(.title2.bold())
                    let drills = team.assignments.filter { $0.assignedMemberID == nil || $0.assignedMemberID?.uuidString == memberIDText }
                    if drills.isEmpty { ContentUnavailableView("No Drills Yet", systemImage: "figure.soccer", description: Text("Pull down to check for new assignments.")) }
                    ForEach(drills) { drill in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(drill.title).font(.title3.bold())
                            if !drill.details.isEmpty { Text(drill.details) }
                            if !drill.equipment.isEmpty { Label(drill.equipment, systemImage: "shippingbox.fill").font(.caption).foregroundStyle(.secondary) }
                            NavigationLink {
                                if let name = playerDrillName(for: drill) {
                                    DrillTimerView(drill: Drill(name: name), totalPoints: $totalPoints)
                                } else {
                                    AssignedDrillTimerView(title: drill.title, details: drill.details, minutes: drill.durationMinutes ?? 10)
                                }
                            } label: {
                                Label(playerDrillName(for: drill) != nil ? "Start Drill" : "Start \(drill.durationMinutes ?? 10) min Timer", systemImage: "timer")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding()
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            } else { ProgressView("Loading team…").frame(maxWidth: .infinity).padding(.top, 80) }
        }
    }
}

struct PlayerJoinTeamProfileCard: View {
    @AppStorage("playerUsername") private var playerName = ""
    @AppStorage("playerAge") private var playerAge = 0
    @AppStorage("playerPosition") private var playerPosition = ""
    @AppStorage("playerTeamCode") private var teamCode = ""
    @AppStorage("playerTeamMemberID") private var memberIDText = ""
    @State private var enteredCode = ""
    @State private var store = TeamCloudKitStore()
    @State private var isEnteringPlayerDetails = false
    @State private var isShowingTeam = false

    private let positions = ["Goalkeeper", "Defender", "Midfielder", "Winger", "Striker"]

    private var normalizedCode: String {
        String(enteredCode.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(teamCode.isEmpty ? "Join a Team" : "Your Team", systemImage: "person.3.fill")
                .font(.title2.bold())

            if teamCode.isEmpty {
                Text(
                    isEnteringPlayerDetails
                        ? "Add your player information to finish joining."
                        : "Enter the six-character code from your coach."
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isEnteringPlayerDetails {
                    TextField("Player name", text: $playerName)
                        .textInputAutocapitalization(.words)
                        .teamField()

                    Stepper("Age: \(playerAge)", value: $playerAge, in: 5...21)
                        .teamField()

                    Picker("Position", selection: $playerPosition) {
                        ForEach(positions, id: \.self) { position in
                            Text(position).tag(position)
                        }
                    }
                    .pickerStyle(.menu)
                    .teamField()

                    HStack {
                        Button("Back") {
                            withAnimation(.snappy) {
                                isEnteringPlayerDetails = false
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Join Team", systemImage: "person.badge.plus") {
                            Task { await joinTeam() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            store.isLoading
                                || playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                } else {
                    TextField("TEAM CODE", text: $enteredCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .teamField()
                        .onChange(of: enteredCode) { _, _ in
                            if enteredCode != normalizedCode {
                                enteredCode = normalizedCode
                            }
                        }

                    Button("Continue", systemImage: "arrow.right.circle.fill") {
                        Task { await showPlayerDetails() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isLoading || normalizedCode.count != 6)
                }
            } else {
                Text("Team code: \(teamCode)")
                    .font(.headline)
                    .foregroundStyle(Color.soccerAccent)
                Text("See drills and points shared by your coach.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    PlayerTeamView()
                } label: {
                    Label("Open My Team", systemImage: "person.3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
        .navigationDestination(isPresented: $isShowingTeam) {
            PlayerTeamView()
        }
    }

    private func showPlayerDetails() async {
        await store.loadTeam(code: normalizedCode)
        guard store.workspace != nil, store.errorMessage == nil else { return }

        if !(5...21).contains(playerAge) {
            playerAge = 10
        }
        if !positions.contains(playerPosition) {
            playerPosition = "Midfielder"
        }
        withAnimation(.snappy) {
            isEnteringPlayerDetails = true
        }
    }

    private func joinTeam() async {
        let memberID = UUID(uuidString: memberIDText) ?? UUID()
        if await store.joinTeam(
            code: normalizedCode,
            name: playerName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: playerAge,
            position: playerPosition,
            memberID: memberID
        ) {
            memberIDText = (store.joinedMemberID ?? memberID).uuidString
            teamCode = normalizedCode
            Haptics.success()
            isShowingTeam = true
        }
    }
}

struct CoachCustomDrillsView: View {
    @AppStorage("coachTeamCode") private var teamCode = ""
    @State private var store = TeamCloudKitStore()
    @State private var name = ""
    @State private var category = "Shooting"
    @State private var instructions = ""
    @State private var equipment = ""
    @State private var durationMinutes = 10

    var body: some View {
        NavigationStack {
            Form {
                if teamCode.isEmpty {
                    ContentUnavailableView("Make a Team First", systemImage: "person.3.fill", description: Text("Open the Team tab and make your team."))
                } else {
                    Section("Create your own drill") {
                        TextField("Drill name", text: $name)
                        Picker("Category", selection: $category) { ForEach(CoachDrillCategory.allCases) { Text($0.rawValue).tag($0.rawValue) } }
                        TextField("Equipment", text: $equipment)
                        Stepper("Timer: \(durationMinutes) min", value: $durationMinutes, in: 1...90)
                        TextField("Instructions", text: $instructions, axis: .vertical).lineLimit(3...7)
                        Button("Save Custom Drill", systemImage: "plus.circle.fill") {
                            Task {
                                await store.createCustomDrill(name: name, category: category, instructions: instructions, equipment: equipment, durationMinutes: durationMinutes)
                                if store.errorMessage == nil { name = ""; instructions = ""; equipment = ""; Haptics.success() }
                            }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Section("Your drills") {
                        ForEach(store.workspace?.customDrills ?? []) { drill in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(drill.name).font(.headline)
                                Text("\(drill.category) • \(drill.durationMinutes ?? 15) min").font(.caption.bold()).foregroundStyle(Color.soccerAccent)
                                Text(drill.instructions).font(.subheadline)
                            }
                        }
                        .onDelete { offsets in
                            let drills = store.workspace?.customDrills ?? []
                            let ids = offsets.map { drills[$0].id }
                            Task { for id in ids { await store.removeCustomDrill(id) } }
                        }
                    }
                }
            }.scrollContentBackground(.hidden).background(SoccerBackgroundView())
                .navigationTitle("Create Drills")
                .task(id: teamCode) { if !teamCode.isEmpty { await store.loadTeam(code: teamCode) } }
        }.tint(Color.soccerAccent)
    }
}

private enum TrainingAssignmentType: String, CaseIterable, Identifiable {
    case drill = "Drill"
    case task = "Custom Task"

    var id: Self { self }
}

private struct AssignTrainingSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: TeamCloudKitStore
    @State private var selectedDrillID = DrillPresentation.categories.first?.drills.sorted().first.map { "player-\($0)" } ?? ""
    @State private var targetID: String
    @State private var assignmentType = TrainingAssignmentType.drill
    @State private var taskTitle = ""
    @State private var taskInstructions = ""
    @State private var taskEquipment = ""
    @State private var durationMinutes = 10

    init(store: TeamCloudKitStore, initialTargetID: String) {
        self.store = store
        _targetID = State(initialValue: initialTargetID)
    }

    private var options: [CoachDrillOption] {
        CoachDrillOption.options(customDrills: store.workspace?.customDrills ?? [])
    }

    private var selectedOption: CoachDrillOption? {
        options.first { $0.id == selectedDrillID }
    }

    private var canSend: Bool {
        switch assignmentType {
        case .drill:
            selectedOption != nil
        case .task:
            !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !taskInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Assign to") {
                    Picker("Player", selection: $targetID) {
                        Text("Whole team").tag("team")
                        ForEach(store.workspace?.members ?? []) { member in
                            Text(member.name).tag(member.id.uuidString)
                        }
                    }
                }

                Section("Training type") {
                    Picker("Training type", selection: $assignmentType) {
                        ForEach(TrainingAssignmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if assignmentType == .drill {
                    Section("Choose a drill") {
                        NavigationLink {
                            CoachDrillOptionPicker(options: options, selection: $selectedDrillID)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedOption?.name ?? "Select a drill").font(.headline)
                                Text(selectedOption?.category ?? "Browse all drills")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let selectedOption {
                        Section("What the player will see") {
                            Text(selectedOption.instructions)
                            if !selectedDrillID.hasPrefix("player-") {
                                Stepper("Timer: \(durationMinutes) min", value: $durationMinutes, in: 1...90)
                            }
                            Label(selectedOption.equipment, systemImage: "shippingbox.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section("Custom task") {
                        TextField("Task name", text: $taskTitle)
                        TextField("Instructions", text: $taskInstructions, axis: .vertical)
                            .lineLimit(3...6)
                        TextField("Equipment (optional)", text: $taskEquipment)
                        Stepper("Timer: \(durationMinutes) min", value: $durationMinutes, in: 1...90)
                    }
                }
            }
            .onChange(of: selectedDrillID, initial: true) { _, _ in
                if let selectedOption { durationMinutes = selectedOption.durationMinutes }
            }
            .navigationTitle("Assign Training")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task { await sendAssignment() }
                    }
                    .disabled(!canSend || store.isLoading)
                }
            }
        }
    }

    private func sendAssignment() async {
        let assignment: (title: String, details: String, equipment: String)
        switch assignmentType {
        case .drill:
            guard let selectedOption else { return }
            assignment = (selectedOption.name, selectedOption.instructions, selectedOption.equipment)
        case .task:
            assignment = (
                taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                taskInstructions.trimmingCharacters(in: .whitespacesAndNewlines),
                taskEquipment.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        await store.assign(
            title: assignment.title,
            details: assignment.details,
            equipment: assignment.equipment,
            durationMinutes: durationMinutes,
            playerDrillName: assignmentType == .drill && selectedDrillID.hasPrefix("player-")
                ? String(selectedDrillID.dropFirst("player-".count)) : nil,
            memberID: UUID(uuidString: targetID)
        )
        if store.errorMessage == nil {
            Haptics.success()
            dismiss()
        }
    }
}

struct CoachDrillOption: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let instructions: String
    let equipment: String
    let durationMinutes: Int

    static func options(customDrills: [TeamCustomDrill]) -> [CoachDrillOption] {
        let playerDrills = DrillPresentation.categories.flatMap { category in
            category.drills.sorted().map { name in
                CoachDrillOption(
                    id: "player-\(name)",
                    name: name,
                    category: category.name,
                    instructions: "Do the \(name) drill from the Drills tab. Focus: \(DrillPresentation.focus(for: category.name))",
                    equipment: DrillPresentation.equipment(for: name, category: category.name),
                    durationMinutes: max(1, Int((Double(DrillTimerView.duration(for: name)) / 60).rounded(.up)))
                )
            }
        }
        let custom = customDrills.map { drill in
            CoachDrillOption(
                id: "custom-\(drill.id.uuidString)",
                name: drill.name,
                category: drill.category,
                instructions: drill.instructions,
                equipment: drill.equipment,
                durationMinutes: drill.durationMinutes ?? 15
            )
        }
        return custom + playerDrills
    }
}

struct CoachDrillOptionPicker: View {
    let options: [CoachDrillOption]
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredOptions: [CoachDrillOption] {
        guard !searchText.isEmpty else { return options }
        return options.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.category.localizedCaseInsensitiveContains(searchText)
                || $0.equipment.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var orderedCategories: [String] {
        var seen = Set<String>()
        return filteredOptions.map(\.category).filter { seen.insert($0).inserted }
    }

    var body: some View {
        List {
            ForEach(orderedCategories, id: \.self) { category in
                let categoryOptions = filteredOptions.filter { $0.category == category }
                if !categoryOptions.isEmpty {
                    Section(category) {
                        ForEach(categoryOptions) { option in
                            Button {
                                selection = option.id
                                dismiss()
                            } label: {
                                CoachDrillOptionRow(
                                    name: option.name,
                                    equipment: option.equipment,
                                    durationMinutes: option.durationMinutes,
                                    isSelected: selection == option.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select a Drill")
        .searchable(text: $searchText, prompt: "Search drills or equipment")
    }
}

private struct CoachDrillOptionRow: View {
    let name: String
    let equipment: String
    let durationMinutes: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.headline)
                Text("\(durationMinutes) min • \(equipment)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.soccerAccent)
            }
        }
        .contentShape(.rect)
    }
}

private extension View {
    func teamField() -> some View {
        padding().background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct EditPlayerSheet: View {
    let member: TeamMember
    let onSave: (String, Int, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var age: Int
    @State private var position: String

    private let positions = ["Goalkeeper", "Defender", "Midfielder", "Winger", "Striker"]

    init(member: TeamMember, onSave: @escaping (String, Int, String) -> Void) {
        self.member = member
        self.onSave = onSave
        _name = State(initialValue: member.name)
        _age = State(initialValue: member.age)
        _position = State(initialValue: member.position)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Player name", text: $name)
                    .textInputAutocapitalization(.words)
                Stepper("Age: \(age)", value: $age, in: 5...21)
                Picker("Position", selection: $position) {
                    ForEach(positions + (positions.contains(position) ? [] : [position]), id: \.self) { Text($0).tag($0) }
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), age, position)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
