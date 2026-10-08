import SwiftUI

struct CoachTeamView: View {
    @AppStorage("coachName") private var coachName = ""
    @AppStorage("coachPrimaryAgeGroup") private var ageGroup = ""
    @AppStorage("coachTeamName") private var savedTeamName = ""
    @AppStorage("coachTeamCode") private var teamCode = ""
    @State private var store = TeamCloudKitStore()
    @State private var teamName = ""
    @State private var showAddPlayer = false
    @State private var showAssign = false

    var body: some View {
        NavigationStack {
            Group {
                if teamCode.isEmpty { makeTeamView } else { teamView }
            }
            .background(SoccerBackgroundView())
            .navigationTitle("My Team")
            .task(id: teamCode) {
                if teamName.isEmpty { teamName = savedTeamName }
                if !teamCode.isEmpty { await store.loadTeam(code: teamCode) }
            }
            .refreshable {
                if !teamCode.isEmpty { await store.loadTeam(code: teamCode) }
            }
            .sheet(isPresented: $showAddPlayer) { AddPlayerSheet(store: store) }
            .sheet(isPresented: $showAssign) { AssignDrillSheet(store: store) }
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
                        Button("Add Player", systemImage: "person.badge.plus") { showAddPlayer = true }
                    }
                    if team.members.isEmpty {
                        Text("Share the code, or add a player yourself.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding().background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                    }
                    ForEach(team.members) { member in
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
                        }.padding().background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                    }

                    Button { showAssign = true } label: {
                        Label("Assign a Drill", systemImage: "paperplane.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                    }.buttonStyle(.borderedProminent)

                    Text("Recent assignments").font(.title2.bold())
                    ForEach(team.assignments.prefix(8)) { assignment in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(assignment.title).font(.headline)
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
    @State private var enteredCode = ""
    @State private var store = TeamCloudKitStore()

    private var memberID: UUID {
        if let id = UUID(uuidString: memberIDText) { return id }
        return UUID()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if teamCode.isEmpty { joinView } else { assignmentsView }
                }.padding()
            }
            .background(SoccerBackgroundView()).navigationTitle("My Team")
            .task(id: teamCode) { if !teamCode.isEmpty { await store.loadTeam(code: teamCode) } }
            .refreshable { if !teamCode.isEmpty { await store.loadTeam(code: teamCode) } }
        }.tint(Color.soccerAccent)
    }

    private var joinView: some View {
        VStack(spacing: 18) {
            Image(systemName: "number.circle.fill").font(.system(size: 72)).foregroundStyle(Color.soccerAccent)
            Text("Join Your Team").font(.largeTitle.bold())
            Text("Enter the 6-character code from your coach.").foregroundStyle(.secondary)
            TextField("TEAM CODE", text: $enteredCode).textInputAutocapitalization(.characters)
                .autocorrectionDisabled().font(.title2.bold()).multilineTextAlignment(.center).teamField()
            Button("Join Team") {
                Task {
                    let id = memberIDText.isEmpty ? UUID() : memberID
                    if await store.joinTeam(code: enteredCode, name: playerName, age: playerAge, position: playerPosition, memberID: id) {
                        memberIDText = id.uuidString
                        teamCode = enteredCode.uppercased().filter { $0.isLetter || $0.isNumber }
                        Haptics.success()
                    }
                }
            }.buttonStyle(.borderedProminent).disabled(store.isLoading || enteredCode.count < 6)
            if let error = store.errorMessage { Text(error).foregroundStyle(.red).font(.footnote) }
        }.frame(maxWidth: .infinity)
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
                        }.frame(maxWidth: .infinity, alignment: .leading).padding()
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            } else { ProgressView("Loading team…").frame(maxWidth: .infinity).padding(.top, 80) }
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
                        TextField("Instructions", text: $instructions, axis: .vertical).lineLimit(3...7)
                        Button("Save Custom Drill", systemImage: "plus.circle.fill") {
                            Task {
                                await store.createCustomDrill(name: name, category: category, instructions: instructions, equipment: equipment)
                                if store.errorMessage == nil { name = ""; instructions = ""; equipment = ""; Haptics.success() }
                            }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Section("Your drills") {
                        ForEach(store.workspace?.customDrills ?? []) { drill in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(drill.name).font(.headline)
                                Text(drill.category).font(.caption.bold()).foregroundStyle(Color.soccerAccent)
                                Text(drill.instructions).font(.subheadline)
                            }
                        }
                    }
                }
            }.scrollContentBackground(.hidden).background(SoccerBackgroundView())
                .navigationTitle("Create Drills")
                .task(id: teamCode) { if !teamCode.isEmpty { await store.loadTeam(code: teamCode) } }
        }.tint(Color.soccerAccent)
    }
}

private struct AddPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: TeamCloudKitStore
    @State private var name = ""
    @State private var age = 10
    @State private var position = "Midfielder"
    var body: some View {
        NavigationStack { Form {
            TextField("Player name", text: $name)
            Stepper("Age: \(age)", value: $age, in: 5...21)
            Picker("Position", selection: $position) { ForEach(["Goalkeeper", "Defender", "Midfielder", "Winger", "Striker"], id: \.self) { Text($0) } }
        }.navigationTitle("Add Player").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Add") { Task { await store.addPlayer(name: name, age: age, position: position); dismiss() } }.disabled(name.isEmpty) } } }
    }
}

private struct AssignDrillSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: TeamCloudKitStore
    @State private var title = ""
    @State private var details = ""
    @State private var equipment = ""
    @State private var targetID = "team"
    var body: some View {
        NavigationStack { Form {
            TextField("Drill name", text: $title)
            TextField("Instructions", text: $details, axis: .vertical)
            TextField("Equipment", text: $equipment)
            Picker("Assign to", selection: $targetID) {
                Text("Whole team").tag("team")
                ForEach(store.workspace?.members ?? []) { Text($0.name).tag($0.id.uuidString) }
            }
        }.navigationTitle("Assign Drill").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Send") { Task { await store.assign(title: title, details: details, equipment: equipment, memberID: UUID(uuidString: targetID)); dismiss() } }.disabled(title.isEmpty) } } }
    }
}

private extension View {
    func teamField() -> some View {
        padding().background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}
