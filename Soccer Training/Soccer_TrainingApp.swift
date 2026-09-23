//
//  Soccer_TrainingApp.swift
//  Soccer Training
//
//  Created by Thomas Telintelo on 9/13/26.
//

import SwiftUI

struct LaunchContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                PlayerSignInView(isSignedIn: $hasCompletedOnboarding)
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

private struct WelcomeStartView: View {
    let startTraining: () -> Void

    var body: some View {
        ZStack {
            Image("SoccerHero")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.soccerNavy.opacity(0.20),
                    Color.soccerGreen.opacity(0.55),
                    Color.soccerNavy.opacity(0.96),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "figure.soccer")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Color.soccerLime)
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 5)

                Text("Futbol Trainnier")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.soccerCream)

                Text("Train smarter. Play stronger.")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.soccerCream.opacity(0.85))

                Button(action: startTraining) {
                    Label("Start Training", systemImage: "play.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.soccerLime)
                        .foregroundStyle(Color.soccerNavy)
                        .clipShape(.rect(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
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
    @AppStorage("favoriteTeam") private var favoriteTeam = ""

    @State private var username = ""
    @State private var position = ""
    @State private var bestSkill = ""

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
            && !favoriteTeam.isEmpty
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.soccerNavy.opacity(0.96), Color.soccerGreen.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.soccerLime)

                    Text("Create Your Player")
                        .font(.largeTitle)
                        .fontWeight(.heavy)

                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.soccerCream.opacity(0.14))
                        .clipShape(.rect(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pick your favorite team")
                            .font(.headline)

                        Picker("Favorite team", selection: $favoriteTeam) {
                            Text("Select a team").tag("")
                            ForEach(FavoriteTeam.allCases) { team in
                                Text(team.rawValue).tag(team.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerCream.opacity(0.14))
                        .clipShape(.rect(cornerRadius: 12))

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
                        .background(Color.soccerCream.opacity(0.14))
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
                        .background(Color.soccerCream.opacity(0.14))
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    Button("Sign In") {
                        savedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        savedPosition = position
                        savedBestSkill = bestSkill
                        isSignedIn = true
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSignIn ? Color.soccerLime : Color.gray)
                    .foregroundStyle(Color.soccerNavy)
                    .clipShape(.rect(cornerRadius: 14))
                    .disabled(!canSignIn)
                }
                .padding(24)
            }
        }
        .foregroundStyle(Color.soccerCream)
    }
}

@main
struct Soccer_TrainingApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchContainerView()
                .preferredColorScheme(.dark)
        }
    }
}
