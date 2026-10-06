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
    @State private var hasStarted = false
    @State private var hasSeenBenefits = false

    var body: some View {
        ZStack {
            // Built only after the splash is dismissed, so the very first frame
            // doesn't have to construct the whole signed-in tab hierarchy first.
            if hasStarted {
                if hasCompletedOnboarding {
                    ContentView()
                } else if hasSeenBenefits {
                    PlayerSignInView(isSignedIn: $hasCompletedOnboarding)
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
        ("star.fill", "Earn Points, Build Your Team", "Complete drills to earn points, then sign real players and build your Starting 11."),
        ("calendar.badge.checkmark", "Daily Challenges", "Fresh challenges every day keep training fun and rewarding."),
        ("chart.bar.fill", "Track Your Progress", "Your Profile shows your level, stats, and achievements as you improve."),
    ]

    var body: some View {
        ZStack {
            Color.soccerBackground
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

    var body: some View {
        ZStack {
            Color.soccerBackground
                .ignoresSafeArea()

            // A drawn stick-figure pictogram instead of a real player's
            // photo, so the splash screen isn't tied to any one athlete.
            Image(systemName: "figure.soccer")
                .resizable()
                .scaledToFit()
                .frame(width: 460, height: 460)
                .foregroundStyle(Color.soccerAccent.opacity(0.08))
                .offset(y: -60)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "figure.soccer")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Color.soccerAccent)

                Text("Futbol Elite")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.soccerText)

                Text("Train smarter. Play stronger.")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.soccerText.opacity(0.65))

                Button(action: startTraining) {
                    Label("Start Training", systemImage: "play.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.soccerAccent)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 18))
                        .shadow(color: Color.soccerAccent.opacity(0.35), radius: 10, y: 5)
                }
                .padding(.top, 14)
                .padding(.horizontal, 28)
                .padding(.bottom, 54)
            }
        }
    }
}

struct PlayerSignInView: View {
    @Binding var isSignedIn: Bool
    @AppStorage("playerUsername") private var savedUsername = ""
    @AppStorage("playerPosition") private var savedPosition = ""
    @AppStorage("playerBestSkill") private var savedBestSkill = ""

    @State private var username = ""
    @State private var position = ""
    @State private var bestSkill = ""
    @State private var showConfetti = false

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

    private var canSignIn: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !position.isEmpty
            && !bestSkill.isEmpty
    }

    var body: some View {
        ZStack {
            Color.soccerBackground
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

                    Button {
                        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty, !position.isEmpty, !bestSkill.isEmpty else {
                            Haptics.soft()
                            return
                        }
                        Haptics.success()
                        savedUsername = trimmed
                        savedPosition = position
                        savedBestSkill = bestSkill
                        isSignedIn = true
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showConfetti = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            showConfetti = false
                        }
                    } label: {
                        Label("Sign In", systemImage: "sparkles")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSignIn ? Color.soccerAccent : Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(!canSignIn)

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
                .preferredColorScheme(.light)
        }
    }
}
