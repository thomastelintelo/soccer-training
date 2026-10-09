//
//  Soccer_TrainingApp.swift
//  Soccer Training
//
//  Created by Thomas Telintelo on 9/13/26.
//

import SwiftUI
import UIKit

// MARK: - Excitement Helpers
enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}

struct ConfettiView: View {
    @State private var particles: [UUID] = []
    var body: some View {
        ZStack {
            ForEach(particles, id: \.self) { _ in
                Circle()
                    .fill([Color.soccerAccent, .soccerAccentLight, .soccerGold, .yellow].randomElement()!)
                    .frame(width: 6, height: 6)
                    .modifier(ConfettiMotion())
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<44).map { _ in UUID() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { particles.removeAll() }
        }
    }
}

private struct ConfettiMotion: ViewModifier {
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .offset(x: x, y: y)
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 30, damping: 6)) {
                    x = CGFloat.random(in: -90...90)
                    y = CGFloat.random(in: 120...240)
                }
            }
    }
}

private struct PlayerCreateHeroHeader: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.soccerAccent, Color.soccerAccentLight],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 8) {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .repeating, value: animate)
                Text("Create Your Player")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                Text("Kick off your journey")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.vertical, 16)
        }
        .frame(height: 180)
        .clipShape(.rect(cornerRadius: 22))
        .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
        .onAppear { animate = true }
    }
}

struct LaunchContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("accountRole") private var accountRole = ""
    @State private var hasStarted = false
    @State private var hasSeenBenefits = false

    var body: some View {
        ZStack {
            // Built only after the splash is dismissed, so the very first frame
            // doesn't have to construct the whole signed-in tab hierarchy first.
            if hasStarted {
                if hasCompletedOnboarding {
                    if accountRole == AppRole.coach.rawValue {
                        CoachContentView()
                    } else {
                        ContentView()
                    }
                } else if hasSeenBenefits {
                    if accountRole == AppRole.player.rawValue {
                        PlayerSignInView(
                            isSignedIn: $hasCompletedOnboarding,
                            onChooseDifferentRole: { accountRole = "" }
                        )
                    } else if accountRole == AppRole.coach.rawValue {
                        CoachSignInView(
                            isSignedIn: $hasCompletedOnboarding,
                            onChooseDifferentRole: { accountRole = "" }
                        )
                    } else {
                        RoleSelectionView { role in
                            withAnimation(.easeOut(duration: 0.25)) {
                                accountRole = role.rawValue
                            }
                        }
                    }
                } else {
                    AppBenefitsView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            hasSeenBenefits = true
                        }
                    }
                    .transition(.opacity)
                }
            }

            if !hasStarted {
                WelcomeStartView {
                    withAnimation(.easeOut(duration: 0.35)) {
                        hasStarted = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

private struct AppBenefitsView: View {
    let onContinue: () -> Void

    private let benefits: [(icon: String, title: String, detail: String)] = [
        ("list.bullet.clipboard.fill", "150+ Training Drills", "Shooting, dribbling, passing, goalkeeping, and a lot more — for every position."),
        ("checkmark.seal.fill", "Free to Play", "No account needed, and nothing to pay. A few optional extras are in there if you ever want them."),
        ("star.fill", "Earn Points and Level Up", "Complete drills and sessions to earn points, improve your level, and unlock achievements."),
        ("calendar.badge.checkmark", "Daily Challenges", "Fresh challenges every day keep training fun and rewarding."),
        ("chart.bar.fill", "Track Your Progress", "Your Profile shows your level, stats, and achievements as you improve."),
    ]

    var body: some View {
        ZStack {
            SoccerBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Image(systemName: "figure.soccer")
                            .font(.system(size: 54))
                            .foregroundStyle(Color.soccerAccent)
                        Text("Welcome to Futbol Elite")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .multilineTextAlignment(.center)
                        Text("Here's what you're getting.")
                            .font(.title3)
                            .foregroundStyle(Color.soccerText.opacity(0.65))
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        ForEach(benefits, id: \.title) { benefit in
                            HStack(spacing: 16) {
                                Image(systemName: benefit.icon)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.soccerAccent, in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(benefit.title)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text(benefit.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.soccerText.opacity(0.7))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    Button(action: onContinue) {
                        Label("Let's Go", systemImage: "arrow.right.circle.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.soccerAccent)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 16))
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .foregroundStyle(Color.soccerText)
    }
}

private struct WelcomeStartView: View {
    let startTraining: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ballEntered = false
    @State private var logoVisible = false
    @State private var wordsVisible = false
    @State private var featureIndex: Int?
    @State private var controlsVisible = false

    private let features: [(icon: String, title: String, color: Color)] = [
        ("list.bullet.clipboard.fill", "OVER 150+ DRILLS", .cyan),
        ("bolt.fill", "GET BETTER IN NO TIME", .soccerGold),
        ("checkmark.seal.fill", "NO SIGNING UP", .green),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.30),
                    Color(red: 0.05, green: 0.50, blue: 0.38),
                    Color(red: 0.32, green: 0.08, blue: 0.52),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.soccerGold.opacity(0.45), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 360
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.soccerAccent.opacity(0.65), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 430
            )
            .ignoresSafeArea()

            SoccerIntroFieldLines()
                .opacity(logoVisible ? 1 : 0)
                .animation(.easeOut(duration: 1.2), value: logoVisible)

            Image(systemName: "figure.soccer")
                .font(.system(size: 250, weight: .thin))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 105, y: 100)
                .ignoresSafeArea()

            Image(systemName: "soccerball")
                .font(.system(size: 62, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 12, y: 8)
                .rotationEffect(.degrees(ballEntered ? 720 : 0))
                .offset(
                    x: ballEntered ? 0 : -260,
                    y: ballEntered ? -155 : 220
                )

            VStack(spacing: 16) {
                Spacer(minLength: 90)

                Image(systemName: "figure.soccer")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(22)
                    .background(Color.soccerAccent, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.75), lineWidth: 3)
                    }
                    .shadow(color: Color.soccerAccent.opacity(0.8), radius: 30)
                    .scaleEffect(logoVisible ? 1 : 0.3)
                    .opacity(logoVisible ? 1 : 0)

                VStack(spacing: 8) {
                    Text("WELCOME TO")
                        .font(.headline)
                        .fontWeight(.black)
                        .tracking(5)
                        .foregroundStyle(.white.opacity(0.75))

                    Text("FUTBOL ELITE")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                        .foregroundStyle(.white)

                    Text("Train smarter. Play stronger.")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .multilineTextAlignment(.center)
                .offset(y: wordsVisible ? 0 : 28)
                .opacity(wordsVisible ? 1 : 0)

                ZStack {
                    if let featureIndex {
                        Label(
                            features[featureIndex].title,
                            systemImage: features[featureIndex].icon
                        )
                        .font(.headline)
                        .fontWeight(.black)
                        .tracking(1.5)
                        .foregroundStyle(features[featureIndex].color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(features[featureIndex].color.opacity(0.16), in: Capsule())
                        .transition(.blurReplace.combined(with: .scale))
                        .id(featureIndex)
                    }
                }
                .frame(height: 52)

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        Haptics.tap()
                        startTraining()
                    } label: {
                        Label("Enter Futbol Elite", systemImage: "play.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(.white)
                            .foregroundStyle(Color.soccerAccent)
                            .clipShape(.rect(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
                    }

                    Text("PLAYER TRAINING • COACHING • PROGRESS")
                        .font(.caption2)
                        .fontWeight(.black)
                        .tracking(1.2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 54)
                .opacity(controlsVisible ? 1 : 0)
                .offset(y: controlsVisible ? 0 : 24)
            }
            .padding(.horizontal, 18)

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        startTraining()
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.22), in: Capsule())
                }
                Spacer()
            }
            .padding(20)
        }
        .task {
            if reduceMotion {
                ballEntered = true
                logoVisible = true
                wordsVisible = true
                controlsVisible = true
                return
            }

            withAnimation(.spring(response: 2.2, dampingFraction: 0.72)) {
                ballEntered = true
            }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.spring(response: 1.0, dampingFraction: 0.68)) {
                logoVisible = true
            }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 1.0)) {
                wordsVisible = true
            }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                featureIndex = 0
            }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                featureIndex = 1
            }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                featureIndex = 2
            }
            try? await Task.sleep(for: .seconds(1))
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.8)) {
                controlsVisible = true
            }
        }
    }
}

private struct SoccerIntroFieldLines: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let inset: CGFloat = 22
                let field = CGRect(
                    x: inset,
                    y: inset,
                    width: proxy.size.width - inset * 2,
                    height: proxy.size.height - inset * 2
                )
                path.addRoundedRect(in: field, cornerSize: CGSize(width: 28, height: 28))
                path.move(to: CGPoint(x: field.minX, y: field.midY))
                path.addLine(to: CGPoint(x: field.maxX, y: field.midY))
                path.addEllipse(
                    in: CGRect(
                        x: field.midX - 52,
                        y: field.midY - 52,
                        width: 104,
                        height: 104
                    )
                )
            }
            .stroke(.white.opacity(0.12), lineWidth: 2)
        }
        .padding(.vertical, 36)
        .allowsHitTesting(false)
    }
}

struct PlayerSignInView: View {
    @Binding var isSignedIn: Bool
    let onChooseDifferentRole: () -> Void

    @AppStorage("playerUsername") private var savedUsername = ""
    @AppStorage("playerPosition") private var savedPosition = ""
    @AppStorage("playerBestSkill") private var savedBestSkill = ""
    @AppStorage("playerAge") private var savedAge = 0
    @AppStorage("playerMainFocus") private var savedMainFocus = "None"

    @State private var username = ""
    @State private var age = 0
    @State private var position = ""
    @State private var bestSkill = ""
    @State private var mainFocus = "None"
    @State private var showConfetti = false
    @State private var teamCodeInput = ""
    @State private var teamStore = TeamCloudKitStore()
    @AppStorage("playerTeamCode") private var savedTeamCode = ""
    @AppStorage("playerTeamMemberID") private var savedMemberID = ""

    private var normalizedTeamCode: String {
        String(teamCodeInput.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
    }

    private let positions = [
        "Goalkeeper",
        "Defender",
        "Midfielder",
        "Winger",
        "Striker",
    ]

    private let skills = [
        "Control",
        "Passing",
        "Shooting",
        "Dribbling",
    ]

    private let focusOptions = ["None", "Control", "Passing", "Shooting", "Dribbling", "Fitness"]

    private var canSignIn: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && age > 0
            && !position.isEmpty
            && !bestSkill.isEmpty
    }

    private var recommendedSkill: String {
        switch age {
        case 5...8: "Control"
        case 9...11: "Dribbling"
        case 12...14: "Passing"
        case 15...17: "Shooting"
        case 18...21: "Control"
        default: ""
        }
    }

    private var recommendationDetail: String {
        switch age {
        case 5...8: "Close control builds confidence and makes every other skill easier."
        case 9...11: "Dribbling helps you become comfortable changing direction with the ball."
        case 12...14: "Passing and scanning become especially important as the game gets faster."
        case 15...17: "Finishing practice helps turn good team play into goals."
        case 18...21: "A clean first touch gives you more time for your next decision."
        default: ""
        }
    }

    private func finishSignIn(_ trimmed: String) {
        Haptics.success()
        savedUsername = trimmed
        savedAge = age
        savedPosition = position
        savedBestSkill = bestSkill
        savedMainFocus = mainFocus
        isSignedIn = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showConfetti = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showConfetti = false
        }
    }

    var body: some View {
        ZStack {
            SoccerBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    PlayerCreateHeroHeader()

                    Image(systemName: "figure.soccer")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.soccerAccent)

                    Text("Create Your Player")
                        .font(.largeTitle)
                        .fontWeight(.heavy)

                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How old are you?")
                            .font(.headline)

                        Picker("Age", selection: $age) {
                            Text("Select your age").tag(0)
                            ForEach(5...21, id: \.self) { age in
                                Text("\(age) years old").tag(age)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    if age > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(
                                "Recommended focus: \(recommendedSkill)",
                                systemImage: "lightbulb.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(Color.soccerAccent)

                            Text(recommendationDetail)
                                .font(.subheadline)
                                .foregroundStyle(Color.soccerText.opacity(0.7))

                            Button("Choose \(recommendedSkill)") {
                                bestSkill = recommendedSkill
                            }
                            .font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What position do you play?")
                            .font(.headline)

                        Picker("Position", selection: $position) {
                            Text("Select a position").tag("")
                            ForEach(positions, id: \.self) { position in
                                Text(position).tag(position)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What are you best at?")
                            .font(.headline)

                        Picker("Best skill", selection: $bestSkill) {
                            Text("Select your best skill").tag("")
                            ForEach(skills, id: \.self) { skill in
                                Text(skill).tag(skill)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What do you mainly want to improve?")
                            .font(.headline)
                        Text("This skill will appear first in your drills. Choose None for a balanced plan.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Main focus", selection: $mainFocus) {
                            ForEach(focusOptions, id: \.self) { focus in
                                Text(focus).tag(focus)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Have a team code? (optional)")
                            .font(.headline)
                        Text("Enter your coach's code and you'll join the team with the info above.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("TEAM CODE", text: $teamCodeInput)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.soccerSurface)
                            .clipShape(.rect(cornerRadius: 12))
                            .onChange(of: teamCodeInput) { _, _ in
                                if teamCodeInput != normalizedTeamCode { teamCodeInput = normalizedTeamCode }
                            }
                        if let message = teamStore.errorMessage {
                            Text(message).font(.footnote).foregroundStyle(.red)
                        }
                    }

                    Button {
                        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty, age > 0, !position.isEmpty, !bestSkill.isEmpty else {
                            Haptics.soft()
                            return
                        }
                        Task {
                            if !normalizedTeamCode.isEmpty {
                                let memberID = UUID(uuidString: savedMemberID) ?? UUID()
                                guard normalizedTeamCode.count == 6,
                                      await teamStore.joinTeam(
                                        code: normalizedTeamCode, name: trimmed, age: age,
                                        position: position, memberID: memberID
                                      )
                                else {
                                    if normalizedTeamCode.count != 6 {
                                        teamStore.errorMessage = "Enter the complete six-character team code."
                                    }
                                    Haptics.soft()
                                    return
                                }
                                savedMemberID = (teamStore.joinedMemberID ?? memberID).uuidString
                                savedTeamCode = normalizedTeamCode
                            }
                            finishSignIn(trimmed)
                        }
                    } label: {
                        Label("Create Player Profile", systemImage: "sparkles")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSignIn ? Color.soccerAccent : Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(!canSignIn || teamStore.isLoading)

                    Button("Choose Coach Instead", action: onChooseDifferentRole)
                        .font(.headline)
                }
                .padding(24)
            }
        }
        .foregroundStyle(Color.soccerText)
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
    }
}

@main
struct Soccer_TrainingApp: App {
    @State private var plusStore = PlusPurchaseStore()

    init() {
        DrillTimerLiveActivity.shared.configure()
        Self.migrateCategoryProgressIfNeeded()
    }

    /// The 5 original category XP/minute pairs used to be their own named
    /// @AppStorage keys (one category = one property). That doesn't scale as
    /// categories are added, so progress now lives in a single dictionary-backed
    /// `CategoryProgress` store. This runs once to fold the old values in.
    private static func migrateCategoryProgressIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: "categoryProgressMigrated") < 1 else { return }

        let legacyXPKeys = [
            ("shootingXP", "Shooting"), ("dribblingXP", "Dribbling"), ("passingXP", "Passing"),
            ("controlXP", "Control"), ("fitnessXP", "Workout"),
        ]
        let legacyMinuteKeys = [
            ("shootingMinutes", "Shooting"), ("dribblingMinutes", "Dribbling"), ("passingMinutes", "Passing"),
            ("controlMinutes", "Control"), ("fitnessMinutes", "Workout"),
        ]

        var progress = CategoryProgress(
            xpText: defaults.string(forKey: "categoryXP") ?? "",
            minutesText: defaults.string(forKey: "categoryMinutes") ?? ""
        )
        for (key, category) in legacyXPKeys {
            let value = defaults.integer(forKey: key)
            if value > 0 { progress.addXP(value, to: category) }
        }
        for (key, category) in legacyMinuteKeys {
            let value = defaults.integer(forKey: key)
            if value > 0 { progress.addMinutes(value, to: category) }
        }

        defaults.set(progress.xpText, forKey: "categoryXP")
        defaults.set(progress.minutesText, forKey: "categoryMinutes")
        defaults.set(1, forKey: "categoryProgressMigrated")
    }

    var body: some Scene {
        WindowGroup {
            LaunchContainerView()
                .environment(plusStore)
                .task { await plusStore.prepare() }
                .task { await plusStore.observeTransactionUpdates() }
                .preferredColorScheme(.dark)
        }
    }
}
