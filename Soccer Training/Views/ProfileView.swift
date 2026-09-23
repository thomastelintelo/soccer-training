// ProfileView.swift
// The Profile tab: level, stats, achievements, team choice, and sign out.

import SwiftUI
import UIKit

private struct TrainingAchievement: Identifiable {
    let title: String
    let detail: String
    let systemImage: String
    let isUnlocked: Bool

    var id: String { title }
}

struct ProfileView: View {
    let username: String
    let position: String
    let bestSkill: String
    @Binding var totalPoints: Int
    @AppStorage("favoriteTeam") private var favoriteTeam = ""
    @AppStorage("hasCompletedOnboarding") private var isSignedIn = false
    @AppStorage("profilePhoto") private var profilePhoto = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("shootingXP") private var shootingXP = 0
    @AppStorage("dribblingXP") private var dribblingXP = 0
    @AppStorage("passingXP") private var passingXP = 0
    @AppStorage("controlXP") private var controlXP = 0
    @AppStorage("fitnessXP") private var fitnessXP = 0
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("rewardBoxes") private var rewardBoxes = 0
    @AppStorage("rewardBoxFixVersion") private var rewardBoxFixVersion = 0
    @State private var rewardBoxMessage = ""
    @State private var isShowingSignOutConfirmation = false
    @State private var isShowingCamera = false
    @State private var isShowingCameraUnavailable = false

    private var savedProfileImage: UIImage? {
        guard
            let data = Data(base64Encoded: profilePhoto),
            let image = UIImage(data: data)
        else {
            return nil
        }
        return image
    }

    private var level: Int {
        playerXP / 500 + 1
    }

    private var levelTitle: String {
        switch level {
        case 1...4: "Developing Player"
        case 5...9: "Rising Player"
        case 10...19: "Strong Player"
        default: "Elite Trainer"
        }
    }

    private var progress: Double {
        Double(playerXP % 500) / 500
    }

    private var achievements: [TrainingAchievement] {
        [
            TrainingAchievement(title: "First Goal", detail: "Score your first training goal", systemImage: "soccerball", isUnlocked: totalGoals >= 1),
            TrainingAchievement(title: "Goal Getter", detail: "Score 50 training goals", systemImage: "scope", isUnlocked: totalGoals >= 50),
            TrainingAchievement(title: "Getting Started", detail: "Complete 5 sessions", systemImage: "figure.run", isUnlocked: totalSessions >= 5),
            TrainingAchievement(title: "On a Roll", detail: "Reach a 3-day streak", systemImage: "flame.fill", isUnlocked: trainingStreak >= 3),
            TrainingAchievement(title: "Point Collector", detail: "Hold 1,000 points", systemImage: "star.fill", isUnlocked: totalPoints >= 1_000),
            TrainingAchievement(title: "Level Five", detail: "Reach level 5", systemImage: "trophy.fill", isUnlocked: level >= 5),
        ]
    }

    private func skillRating(for xp: Int) -> Int {
        let trainingTimeBonus = totalTrainingMinutes / 30
        return min(99, 40 + xp / 50 + trainingTimeBonus)
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
                                .foregroundStyle(Color.soccerGreen)
                        }

                        Image(systemName: "camera.fill")
                            .font(.headline)
                            .padding(9)
                            .foregroundStyle(.white)
                            .background(Color.soccerGreen, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Take profile photo")

                Text(username)
                    .font(.largeTitle)
                    .fontWeight(.heavy)

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
                            .foregroundStyle(Color.soccerGreen)
                    }

                    ProgressView(value: progress)
                        .tint(.blue)

                    Text("\(500 - (playerXP % 500)) XP until Level \(level + 1) • Reward: one reward box")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerGreen)
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                HStack(spacing: 12) {
                    profileCard(title: "Position", value: position)
                    profileCard(title: "Best Skill", value: bestSkill)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Player Stats")
                        .font(.title2)
                        .fontWeight(.heavy)

                    HStack(spacing: 10) {
                        skillCard(title: "Shooting", rating: skillRating(for: shootingXP))
                        skillCard(title: "Dribbling", rating: skillRating(for: dribblingXP))
                    }
                    HStack(spacing: 10) {
                        skillCard(title: "Passing", rating: skillRating(for: passingXP))
                        skillCard(title: "Control", rating: skillRating(for: controlXP))
                    }
                    skillCard(title: "Fitness", rating: skillRating(for: fitnessXP))

                    Text("\(totalSessions) sessions completed • \(totalTrainingMinutes) minutes trained")
                        .font(.subheadline)
                    Text("\(totalPasses) accurate passes • \(totalDribblingAttempts) dribbling attempts • \(totalControls) successful controls")
                        .font(.subheadline)
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
                            .foregroundStyle(Color.soccerGreen)
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .fontWeight(.bold)
                                Text(achievement.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: achievement.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                                .foregroundStyle(achievement.isUnlocked ? Color.soccerGreen : Color.gray)
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Label("Choose Your Team", systemImage: "shield.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerLime)

                    Text("Your choice changes the colors across the entire app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Favorite team", selection: $favoriteTeam) {
                        Text("Select a team").tag("")
                        ForEach(TeamLeague.allCases) { league in
                            Section(league.rawValue) {
                                ForEach(FavoriteTeam.teams(in: league)) { team in
                                    Text(team.displayName).tag(team.rawValue)
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.soccerLime)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let team = FavoriteTeam(rawValue: favoriteTeam) {
                        HStack(spacing: 12) {
                            ClubCrestView(team: team, size: 44)

                            Text(team.displayName)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                NavigationLink {
                    MyTeamView()
                } label: {
                    Label("My Team", systemImage: "person.3.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.soccerSurface)
                        .foregroundStyle(Color.soccerCream)
                        .clipShape(.rect(cornerRadius: 14))
                }

                NavigationLink {
                    LeaderboardsView(username: username, totalPoints: totalPoints)
                } label: {
                    Label("Leaderboards", systemImage: "trophy.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.soccerGreen)
                        .foregroundStyle(Color.soccerCream)
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
        .background(Color.soccerNavy)
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("Profile")
        .onAppear {
            if rewardBoxFixVersion < 1 {
                rewardBoxes += 1
                rewardBoxFixVersion = 1
                rewardBoxMessage = "Your missing reward box has been returned."
            }
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
            "Sign out of Futbol Trainnier?",
            isPresented: $isShowingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                isSignedIn = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your points, players, training progress, and team choice will stay saved.")
        }
    }

    private func skillCard(title: String, rating: Int) -> some View {
        VStack(spacing: 6) {
            Text(rating.formatted())
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerLime)
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(Color.soccerNavy.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
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
