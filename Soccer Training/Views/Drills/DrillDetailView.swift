// DrillDetailView.swift
// Everything about one drill before you start it: artwork, difficulty, duration,
// equipment, players, setup, instructions, coaching points, common mistakes,
// progressions, and regressions. Start Drill opens the timer, where results and
// points are recorded.

import SwiftUI

struct DrillDetailView: View {
    let drillName: String
    @Binding var totalPoints: Int
    @AppStorage(FavoriteDrills.storageKey) private var favoritesText = ""

    private var info: DrillInfo {
        DrillCatalog.info(for: drillName)
    }

    private var coaching: DrillCoaching {
        DrillCoaching.forDrill(info)
    }

    private var isFavorite: Bool {
        FavoriteDrills.set(from: favoritesText).contains(drillName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero

                VStack(alignment: .leading, spacing: 14) {
                    Text(drillName)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)

                    factTiles

                    equipmentRow
                }
                .padding(.horizontal, 20)

                section("Setup", systemImage: "square.dashed") {
                    bulletList(coaching.setup, icon: "circle.fill", tint: Color.soccerAccent)
                }

                section("Instructions", systemImage: "text.alignleft") {
                    Text(DrillTimerView.instructions(forDrill: drillName, minutes: info.minutes))
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(Color.soccerText.opacity(0.85))
                }

                section("Coaching points", systemImage: "lightbulb.fill") {
                    bulletList(coaching.coachingPoints, icon: "checkmark.circle.fill", tint: .green)
                }

                section("Common mistakes", systemImage: "exclamationmark.triangle.fill") {
                    bulletList(coaching.commonMistakes, icon: "xmark.circle.fill", tint: .red)
                }

                section("Progressions", systemImage: "arrow.up.right.circle.fill") {
                    bulletList(coaching.progressions, icon: "arrow.up.circle.fill", tint: Color.soccerAccent)
                }

                section("Regressions", systemImage: "arrow.down.right.circle.fill") {
                    bulletList(coaching.regressions, icon: "arrow.down.circle.fill", tint: .orange)
                }

                Color.clear.frame(height: 90)
            }
            .padding(.bottom, 8)
        }
        .foregroundStyle(Color.soccerText)
        .background(Color.soccerBackground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    // MARK: - Pieces

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            DrillArtwork(drillName: drillName, height: 230)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 8) {
                Label(info.skill, systemImage: DrillPresentation.icon(for: info.skill))
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                if DrillPresentation.isIndoor(drillName) {
                    Label("Indoor", systemImage: "house.fill")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(Color.soccerAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white, in: Capsule())
                }
            }
            .padding(16)
        }
        .frame(height: 230)
        .clipShape(.rect(cornerRadius: 24))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var factTiles: some View {
        HStack(spacing: 10) {
            factTile(title: "DURATION", value: "\(info.minutes) min", icon: "clock.fill")
            factTile(title: "DIFFICULTY", value: info.level.rawValue, icon: "gauge.with.dots.needle.50percent")
            factTile(title: "PLAYERS", value: info.playerCount.rawValue, icon: info.playerCount.icon)
        }
    }

    private func factTile(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.soccerAccent)
            Text(title)
                .font(.caption2)
                .fontWeight(.black)
                .foregroundStyle(Color.soccerText.opacity(0.55))
            Text(value)
                .font(.subheadline)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(8)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var equipmentRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.title3)
                .foregroundStyle(Color.soccerAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text("EQUIPMENT")
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(Color.soccerText.opacity(0.55))
                Text(info.equipmentText.isEmpty ? "1 soccer ball" : "1 soccer ball, \(info.equipmentText)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func section<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3)
                .fontWeight(.heavy)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
    }

    private func bulletList(_ items: [String], icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(tint)
                        .frame(width: 16)
                    Text(item)
                        .font(.body)
                        .foregroundStyle(Color.soccerText.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.soft()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    favoritesText = FavoriteDrills.toggled(drillName, in: favoritesText)
                }
            } label: {
                Label(
                    isFavorite ? "Favorited" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(isFavorite ? Color.red : Color.soccerText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            NavigationLink {
                DrillTimerView(drill: Drill(name: drillName), totalPoints: $totalPoints)
            } label: {
                Label("Start Drill", systemImage: "play.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.soccerAccent.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}
