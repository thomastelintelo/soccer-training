// ProfileView.swift
// The Profile tab: level, stats, achievements, and sign out.

import ReplayKit
import SwiftUI
import UIKit

struct ProfileView: View {
    let username: String
    let position: String
    let bestSkill: String
    @Binding var totalPoints: Int
    @AppStorage("hasCompletedOnboarding") private var isSignedIn = false
    @AppStorage("profilePhoto") private var profilePhoto = ""
    @AppStorage("playerAge") private var playerAge = 0
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("categoryXP") private var categoryXPText = ""
    @AppStorage("categoryMinutes") private var categoryMinutesText = ""
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("rewardBoxes") private var rewardBoxes = 0
    @AppStorage("rewardBoxFixVersion") private var rewardBoxFixVersion = 0
    @AppStorage("seenAchievements") private var seenAchievementsText = ""
    @State private var rewardBoxMessage = ""
    @State private var isShowingSignOutConfirmation = false
    @State private var isShowingCamera = false
    @State private var isShowingCameraUnavailable = false
    @State private var justUnlocked: Set<String> = []
    @ObservedObject private var screenRecorder = ScreenRecordingManager.shared
    #if DEBUG
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("lastTrainingDate") private var lastTrainingDate = ""
    @AppStorage("completedWeeklyTasks") private var completedWeeklyTasks = ""
    @AppStorage("completedWeeklyDays") private var completedWeeklyDays = ""
    @State private var devResetMessage = ""
    #endif

    private var savedProfileImage: UIImage? {
        guard
            let data = Data(base64Encoded: profilePhoto),
            let image = UIImage(data: data)
        else {
            return nil
        }
        return image
    }

    private var playerProgress: PlayerProgress {
        PlayerProgress(xp: playerXP)
    }

    private var level: Int { playerProgress.level }
    private var levelTitle: String { playerProgress.levelTitle }
    private var progress: Double { playerProgress.progressToNextLevel }

    private var achievements: [Achievement] {
        [
            Achievement(title: "First Goal", detail: "Score your first training goal", systemImage: "soccerball", isUnlocked: totalGoals >= 1),
            Achievement(title: "Goal Getter", detail: "Score 50 training goals", systemImage: "scope", isUnlocked: totalGoals >= 50),
            Achievement(title: "First Session", detail: "Complete your first training session", systemImage: "play.circle.fill", isUnlocked: totalSessions >= 1),
            Achievement(title: "Session Starter", detail: "Complete 5 training sessions", systemImage: "figure.run", isUnlocked: totalSessions >= 5),
            Achievement(title: "Session Regular", detail: "Complete 10 training sessions", systemImage: "calendar.badge.checkmark", isUnlocked: totalSessions >= 10),
            Achievement(title: "Dedicated", detail: "Complete 25 training sessions", systemImage: "figure.run.circle.fill", isUnlocked: totalSessions >= 25),
            Achievement(title: "Fifty Sessions", detail: "Complete 50 training sessions", systemImage: "medal.fill", isUnlocked: totalSessions >= 50),
            Achievement(title: "Century Trainer", detail: "Complete 100 training sessions", systemImage: "trophy.fill", isUnlocked: totalSessions >= 100),
            Achievement(title: "On a Roll", detail: "Reach a 3-day streak", systemImage: "flame.fill", isUnlocked: trainingStreak >= 3),
            Achievement(title: "Unstoppable", detail: "Reach a 7-day streak", systemImage: "flame.circle.fill", isUnlocked: trainingStreak >= 7),
            Achievement(title: "Month Strong", detail: "Reach a 30-day streak", systemImage: "calendar.badge.clock", isUnlocked: trainingStreak >= 30),
            Achievement(title: "Point Collector", detail: "Hold 1,000 points", systemImage: "star.fill", isUnlocked: totalPoints >= 1_000),
            Achievement(title: "High Roller", detail: "Hold 10,000 points", systemImage: "star.circle.fill", isUnlocked: totalPoints >= 10_000),
            Achievement(title: "Level Five", detail: "Reach level 5", systemImage: "trophy.fill", isUnlocked: level >= 5),
            Achievement(title: "Futbol Elite", detail: "Reach level 15", systemImage: "crown.fill", isUnlocked: level >= 15),
            Achievement(title: "Game Intelligence", detail: "Earn 200 Soccer IQ XP", systemImage: "brain.head.profile", isUnlocked: categoryProgress.xp(for: "Soccer IQ") >= 200),
        ]
    }

    private var categoryProgress: CategoryProgress {
        CategoryProgress(xpText: categoryXPText, minutesText: categoryMinutesText)
    }

    private func skillRating(for xp: Int) -> Int {
        let trainingTimeBonus = totalTrainingMinutes / 30
        return min(99, 40 + xp / 50 + trainingTimeBonus)
    }

    private func skillRating(forCategories categories: [String]) -> Int {
        skillRating(for: categories.reduce(0) { $0 + categoryProgress.xp(for: $1) })
    }

    /// All categories shown in the "Training Time by Category" rings, each with
    /// a fixed accent color. Only categories the player has actually trained in
    /// are displayed, so a new player doesn't see a wall of empty rings.
    private static let allCategories: [(title: String, color: Color)] = [
        ("Shooting", .soccerAccent), ("Dribbling", .soccerAccentLight), ("Passing", .soccerGold),
        ("Control", .blue), ("First Touch", .teal), ("Technique", .pink),
        ("Speed & Finishing", .orange), ("Soccer IQ", .mint), ("Goalkeeping", .purple),
        ("Defense", .indigo), ("Plus Training", .cyan), ("Workout", .brown),
    ]

    private var categoryTrainingTimes: [(title: String, minutes: Int, color: Color)] {
        Self.allCategories
            .map { (title: $0.title, minutes: categoryProgress.minutes(for: $0.title), color: $0.color) }
            .filter { $0.minutes > 0 }
    }

    private var totalCategoryMinutes: Int {
        categoryTrainingTimes.map(\.minutes).reduce(0, +)
    }

    /// A FIFA-style 6-stat summary folding all skill categories (including the
    /// newer ones) into the 6 stats a player card always shows.
    private var cardStats: [PlayerCardStat] {
        [
            PlayerCardStat(label: "PAC", value: skillRating(forCategories: ["Speed & Finishing", "Workout"])),
            PlayerCardStat(label: "SHO", value: skillRating(forCategories: ["Shooting", "Speed & Finishing"])),
            PlayerCardStat(label: "PAS", value: skillRating(forCategories: ["Passing", "Soccer IQ"])),
            PlayerCardStat(label: "DRI", value: skillRating(forCategories: ["Dribbling", "Technique", "First Touch"])),
            PlayerCardStat(label: "DEF", value: skillRating(forCategories: ["Defense", "Goalkeeping"])),
            PlayerCardStat(label: "PHY", value: skillRating(forCategories: ["Workout", "Plus Training"])),
        ]
    }

    private var cardOverall: Int {
        let values = cardStats.map(\.value)
        return values.reduce(0, +) / values.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isShowingCamera = true
                    } else {
                        isShowingCameraUnavailable = true
                    }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        if let savedProfileImage {
                            Image(uiImage: savedProfileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(Color.soccerAccent)
                        }

                        Image(systemName: "camera.fill")
                            .font(.headline)
                            .padding(9)
                            .foregroundStyle(.white)
                            .background(Color.soccerAccent, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Take profile photo")

                Text(username)
                    .font(.largeTitle)
                    .fontWeight(.heavy)

                ProfilePlayerCardView(
                    name: username,
                    position: position,
                    level: level,
                    overall: cardOverall,
                    photo: savedProfileImage,
                    stats: cardStats
                )

                VStack(spacing: 8) {
                    Text("Level \(level) • \(levelTitle)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Your XP comes from recorded results and training time. Every 30 training minutes also raises all Profile ratings.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Level Progress")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(playerXP) XP")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.soccerAccent)
                    }

                    ProgressView(value: progress)
                        .tint(Color.soccerAccent)

                    Text("\(playerProgress.xpUntilNextLevel) XP until Level \(level + 1) • Reward: one reward box")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerAccent)
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                HStack(spacing: 12) {
                    profileCard(title: "Position", value: position)
                    profileCard(title: "Best Skill", value: bestSkill)
                    if playerAge > 0 {
                        profileCard(title: "Age", value: playerAge.formatted())
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Player Stats")
                        .font(.title2)
                        .fontWeight(.heavy)

                    HStack(spacing: 10) {
                        skillCard(title: "Pace", rating: cardStats[0].value)
                        skillCard(title: "Shooting", rating: cardStats[1].value)
                    }
                    HStack(spacing: 10) {
                        skillCard(title: "Passing", rating: cardStats[2].value)
                        skillCard(title: "Dribbling", rating: cardStats[3].value)
                    }
                    HStack(spacing: 10) {
                        skillCard(title: "Defending", rating: cardStats[4].value)
                        skillCard(title: "Physical", rating: cardStats[5].value)
                    }

                    Text("\(totalSessions) sessions completed • \(totalTrainingMinutes) minutes trained")
                        .font(.subheadline)
                    Text("\(totalDribblingAttempts) dribbling attempts • \(totalControls) successful controls")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Training Time by Category")
                        .font(.title2)
                        .fontWeight(.heavy)

                    Text("How your training minutes are split across each category.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 12)], spacing: 16) {
                        ForEach(categoryTrainingTimes, id: \.title) { category in
                            CategoryTrainingRing(
                                title: category.title,
                                minutes: category.minutes,
                                totalMinutes: totalCategoryMinutes,
                                color: category.color
                            )
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Label("Reward Boxes: \(rewardBoxes)", systemImage: "shippingbox.fill")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.soccerGold)

                    Text("Earn one box every time you level up. Each box contains 150 points.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Open Reward Box") {
                        guard rewardBoxes > 0 else { return }
                        totalPoints += 150
                        rewardBoxes -= 1
                        rewardBoxMessage = "You received 150 points! Your new balance is \(totalPoints) points."
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(rewardBoxes == 0)

                    if !rewardBoxMessage.isEmpty {
                        Label(rewardBoxMessage, systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.soccerAccent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(.title2)
                        .fontWeight(.heavy)

                    ForEach(achievements) { achievement in
                        HStack(spacing: 12) {
                            Image(systemName: achievement.systemImage)
                                .frame(width: 28)
                                .foregroundStyle(achievement.isUnlocked ? Color.soccerGold : Color.gray)
                                .symbolEffect(.bounce, value: justUnlocked.contains(achievement.id))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .fontWeight(.bold)
                                Text(achievement.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: achievement.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                                .foregroundStyle(achievement.isUnlocked ? Color.soccerAccent : Color.gray)
                        }
                        .scaleEffect(justUnlocked.contains(achievement.id) ? 1.04 : 1)
                        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: justUnlocked)
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Label(
                        "Record a Video",
                        systemImage: screenRecorder.isRecording ? "record.circle.fill" : "video.fill"
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(screenRecorder.isRecording ? Color.red : Color.soccerAccent)
                    .symbolEffect(.pulse, isActive: screenRecorder.isRecording)

                    Text(
                        screenRecorder.isRecording
                            ? "Recording your screen, voice, and camera. Narrate over the app, then tap Stop when you're done."
                            : "Record your screen with your voice and camera to make a video explaining the app. When you stop, you'll get a share sheet to save or post it right away."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Toggle("Show me on camera", isOn: $screenRecorder.isCameraEnabled)
                        .tint(Color.soccerAccent)
                        .disabled(screenRecorder.isRecording)

                    if screenRecorder.isCameraEnabled {
                        Picker("Camera", selection: $screenRecorder.cameraPosition) {
                            Text("Front").tag(RPCameraPosition.front)
                            Text("Back").tag(RPCameraPosition.back)
                        }
                        .pickerStyle(.segmented)
                        .disabled(screenRecorder.isRecording)
                    }

                    Button(screenRecorder.isRecording ? "Stop Recording" : "Start Recording") {
                        Haptics.tap()
                        screenRecorder.toggleRecording()
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(screenRecorder.isRecording ? Color.red : Color.soccerAccent)
                    .foregroundStyle(Color.white)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))
                .alert(
                    "Recording Issue",
                    isPresented: Binding(
                        get: { screenRecorder.errorMessage != nil },
                        set: { isPresented in if !isPresented { screenRecorder.errorMessage = nil } }
                    )
                ) {
                    Button("OK") { }
                } message: {
                    Text(screenRecorder.errorMessage ?? "")
                }

                #if DEBUG
                VStack(alignment: .leading, spacing: 12) {
                    Label("Developer Tools", systemImage: "wrench.and.screwdriver.fill")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.orange)

                    Text("Debug-only tools. Not shown in release builds.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Add Points")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    HStack(spacing: 10) {
                        ForEach([100, 500, 1_000], id: \.self) { amount in
                            Button("+\(amount)") {
                                addPoints(amount)
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    Button("Reset Points", role: .destructive) {
                        resetPoints()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("Reset Level & Training", role: .destructive) {
                        resetLevelAndTraining()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    if !devResetMessage.isEmpty {
                        Label(devResetMessage, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.soccerAccent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))
                #endif

                NavigationLink {
                    LeaderboardsView(username: username, totalPoints: totalPoints)
                } label: {
                    Label("Leaderboards", systemImage: "trophy.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.soccerAccent)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button(role: .destructive) {
                    isShowingSignOutConfirmation = true
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
        .navigationTitle("Profile")
        .onAppear {
            if rewardBoxFixVersion < 1 {
                rewardBoxes += 1
                rewardBoxFixVersion = 1
                rewardBoxMessage = "Your missing reward box has been returned."
            }
            checkForNewAchievements()
        }
        .sheet(isPresented: $isShowingCamera) {
            ProfileCameraPicker { image in
                guard let data = image.jpegData(compressionQuality: 0.7) else { return }
                profilePhoto = data.base64EncodedString()
            }
            .ignoresSafeArea()
        }
        .alert("Camera Unavailable", isPresented: $isShowingCameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Use an iPhone with a camera to take your profile picture.")
        }
        .confirmationDialog(
            "Sign out of Futbol Elite?",
            isPresented: $isShowingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                isSignedIn = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your points and training progress will stay saved.")
        }
    }

    #if DEBUG
    private func addPoints(_ amount: Int) {
        totalPoints += amount
        devResetMessage = "Added \(amount) points. New balance is \(totalPoints)."
        Haptics.success()
    }

    private func resetPoints() {
        totalPoints = 0
        devResetMessage = "Points reset to 0."
        Haptics.soft()
    }

    private func resetLevelAndTraining() {
        playerXP = 0
        categoryXPText = ""
        categoryMinutesText = ""
        totalTrainingMinutes = 0
        totalGoals = 0
        totalShots = 0
        totalPasses = 0
        totalDribblingAttempts = 0
        totalControls = 0
        totalSessions = 0
        trainingStreak = 0
        lastTrainingDate = ""
        completedWeeklyTasks = ""
        completedWeeklyDays = ""
        rewardBoxes = 0
        devResetMessage = "Level and training progress reset."
        Haptics.soft()
    }
    #endif

    private func checkForNewAchievements() {
        let seenIDs = Set(seenAchievementsText.split(separator: "|").map(String.init))
        let unlockedIDs = Set(achievements.filter(\.isUnlocked).map(\.id))
        let newlyUnlocked = unlockedIDs.subtracting(seenIDs)

        guard !newlyUnlocked.isEmpty else { return }
        justUnlocked = newlyUnlocked
        Haptics.success()
        seenAchievementsText = unlockedIDs.union(seenIDs).sorted().joined(separator: "|")
    }

    private func skillCard(title: String, rating: Int) -> some View {
        VStack(spacing: 6) {
            Text(rating.formatted())
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerAccent)
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(Color.soccerSurfaceStrong, in: RoundedRectangle(cornerRadius: 14))
    }

    private func profileCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(8)
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 16))
    }
}

private struct CategoryTrainingRing: View {
    let title: String
    let minutes: Int
    let totalMinutes: Int
    let color: Color

    private var progress: Double {
        guard totalMinutes > 0 else { return 0 }
        return min(1, Double(minutes) / Double(totalMinutes))
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(minutes)m")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 64, height: 64)

            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProfileCameraPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfileCameraPicker

        init(parent: ProfileCameraPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let image {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
    }
}
