// SoccerUI.swift
// Shared building blocks for the redesigned screens: drill artwork and cards,
// the favorite button, chips, section headers, progress indicators, search,
// and option selectors. Everything uses the existing Color+Soccer palette.

import SwiftUI

/// A drill's stock photo, tinted with the drill's own stable hue.
struct DrillArtwork: View {
    let drillName: String
    var height: CGFloat = 110

    var body: some View {
        Image(
            DrillPresentation.imageName(
                for: drillName,
                category: DrillPresentation.category(for: drillName)
            )
        )
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .overlay {
            // Only a handful of stock photos ship, so each drill tints its shared
            // photo with its own stable hue.
            Color(hue: DrillPresentation.photoHue(for: drillName), saturation: 0.6, brightness: 0.9)
                .opacity(0.4)
                .blendMode(.hue)
        }
        .clipped()
    }
}

/// A drill as a card: artwork, name, skill, and the facts a player scans for.
/// Callers add the favorite button outside any NavigationLink wrapping this card.
struct DrillCardView: View {
    let info: DrillInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DrillArtwork(drillName: info.name, height: 104)

            VStack(alignment: .leading, spacing: 8) {
                Text(info.skill.uppercased())
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(Color.soccerAccent)

                Text(info.name)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.soccerText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)

                HStack(spacing: 6) {
                    MetaChip(text: "\(info.minutes) min", icon: "clock.fill")
                    MetaChip(text: info.level.rawValue, icon: "gauge.with.dots.needle.33percent")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }
}

/// A heart that toggles a drill in or out of favorites.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.soft()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.headline)
                .foregroundStyle(isFavorite ? Color.red : Color.soccerText)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.94), in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

/// A small icon-and-text tag used for duration, level, players, and equipment.
struct MetaChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.soccerText.opacity(0.8))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.soccerSurfaceStrong, in: Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3)
                .fontWeight(.heavy)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.soccerText.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = .soccerAccent

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

struct LinearProgressBar: View {
    let fraction: Double
    var tint: Color = .soccerAccent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.15))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)
            }
        }
        .frame(height: 8)
    }
}

struct SearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.soccerText.opacity(0.5))

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.soccerText.opacity(0.4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Multi-select chips that wrap onto as many rows as they need.
struct ChipSelector: View {
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.contains(option)
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.2)) {
                        if isSelected {
                            selection.remove(option)
                        } else {
                            selection.insert(option)
                        }
                    }
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.soccerAccent : Color.soccerSurface, in: Capsule())
                        .foregroundStyle(isSelected ? Color.white : Color.soccerText)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

/// One choice from a short list, shown as tappable rows with a checkmark.
struct SingleChoiceList<Value: Hashable>: View {
    let options: [(value: Value, title: String, subtitle: String?)]
    @Binding var selection: Value

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let isSelected = selection == option.value
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.2)) {
                        selection = option.value
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title)
                                .font(.headline)
                            if let subtitle = option.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.soccerText.opacity(0.6))
                            }
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.soccerAccent : Color.soccerText.opacity(0.25))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected ? Color.soccerAccent.opacity(0.1) : Color.soccerSurface,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.soccerAccent : Color.clear, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
