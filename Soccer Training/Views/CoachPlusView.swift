import SwiftUI

struct CoachPlusView: View {
    @Environment(PlusPurchaseStore.self) private var plusStore
    @State private var showingPlus = false

    private let programs = [
        CoachPlusProgram(title: "Preseason Builder", detail: "Four weeks of progressive fitness, ball work, and team play.", icon: "calendar.badge.clock"),
        CoachPlusProgram(title: "Attacking Principles", detail: "Width, support, third-player runs, combinations, and finishing.", icon: "arrow.up.forward.circle.fill"),
        CoachPlusProgram(title: "Defensive Organization", detail: "Pressure, cover, balance, compactness, and recovery runs.", icon: "shield.fill"),
        CoachPlusProgram(title: "High Press System", detail: "Teach pressing triggers, team distances, and counterattacks.", icon: "bolt.fill"),
        CoachPlusProgram(title: "Build from the Back", detail: "Goalkeeper support, center-back spacing, and playing through pressure.", icon: "arrow.triangle.branch"),
        CoachPlusProgram(title: "Finishing Month", detail: "Four weeks covering technique, movement, crossing, and pressure finishes.", icon: "scope"),
        CoachPlusProgram(title: "Possession Curriculum", detail: "Rondos and games that develop scanning, support, and fast decisions.", icon: "point.3.connected.trianglepath.dotted"),
        CoachPlusProgram(title: "Small-Sided Games Pack", detail: "Competitive 2v2 through 7v7 games with coaching objectives.", icon: "person.3.fill"),
        CoachPlusProgram(title: "Goalkeeper Integration", detail: "Include goalkeepers in possession, distribution, and team sessions.", icon: "hand.raised.fill"),
        CoachPlusProgram(title: "Player Evaluation Guide", detail: "Simple technical, tactical, physical, and attitude evaluation sheets.", icon: "checklist"),
        CoachPlusProgram(title: "Matchday Planner", detail: "Warm-up timing, substitutions, player roles, and halftime questions.", icon: "sportscourt.fill"),
        CoachPlusProgram(title: "Season Review", detail: "Track team progress and choose the next development priorities.", icon: "chart.line.uptrend.xyaxis"),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                CoachPlusHeader(isUnlocked: plusStore.isUnlocked)

                if plusStore.isUnlocked {
                    ForEach(programs) { program in
                        CoachPlusProgramRow(program: program)
                    }
                } else {
                    ContentUnavailableView(
                        "Coach Plus is Locked",
                        systemImage: "crown.fill",
                        description: Text("Unlock advanced coaching programs with Futbol Elite Plus.")
                    )
                    Button("See Coach Plus — \(plusStore.displayPrice)/year") {
                        showingPlus = true
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .navigationTitle("Coach Plus")
        .sheet(isPresented: $showingPlus) { FutbolElitePlusView() }
    }
}

private struct CoachPlusProgram: Identifiable {
    let title: String
    let detail: String
    let icon: String
    var id: String { title }
}

private struct CoachPlusHeader: View {
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("COACH PLUS", systemImage: "crown.fill")
                .font(.largeTitle.bold())
            Text("Advanced plans and tools for building better players and teams.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
            Label(isUnlocked ? "Unlocked" : "Included with yearly Plus", systemImage: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color.soccerAccent, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }
}

private struct CoachPlusProgramRow: View {
    let program: CoachPlusProgram

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: program.icon)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.soccerAccent, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(program.title).font(.headline)
                Text(program.detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 17))
    }
}
