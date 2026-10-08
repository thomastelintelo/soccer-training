import SwiftUI

struct SoccerTestsView: View {
    @AppStorage("soccerTestBests") private var bestsText = ""
    @State private var selectedCategory = "All"
    @State private var searchText = ""

    private var bests: [String: Double] { SoccerTestResults.decode(bestsText) }

    private var filteredTests: [SoccerTest] {
        SoccerTestCatalog.all.filter { test in
            let matchesCategory = selectedCategory == "All" || test.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || test.name.localizedCaseInsensitiveContains(searchText)
                || test.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                SoccerTestsHeader(completedCount: bests.count, totalCount: SoccerTestCatalog.all.count)
                SoccerTestCategoryFilter(selection: $selectedCategory)

                ForEach(filteredTests) { test in
                    NavigationLink {
                        SoccerTestDetailView(test: test, bestsText: $bestsText)
                    } label: {
                        SoccerTestRow(test: test, best: bests[test.id])
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Soccer Tests")
        .searchable(text: $searchText, prompt: "Search tests")
    }
}

struct SoccerTestProfileSummary: View {
    @AppStorage("soccerTestBests") private var bestsText = ""

    private var bests: [String: Double] { SoccerTestResults.decode(bestsText) }

    var body: some View {
        NavigationLink {
            SoccerTestsView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.soccerAccent, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Soccer Tests").font(.title3.bold())
                    Text("\(bests.count) of \(SoccerTestCatalog.all.count) completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Open tests and beat your personal bests")
                        .font(.caption)
                        .foregroundStyle(Color.soccerAccent)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.soccerAccent)
            }
            .padding()
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct SoccerTestsHeader: View {
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Test Your Game", systemImage: "checkmark.seal.fill")
                .font(.largeTitle.bold())
            Text("Complete measurable soccer challenges and beat your personal bests.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
            Text("\(completedCount) of \(totalCount) tests completed")
                .font(.subheadline.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white, in: Capsule())
                .foregroundStyle(Color.soccerAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .foregroundStyle(.white)
        .background(Color.soccerAccent.gradient, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct SoccerTestCategoryFilter: View {
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(["All"] + SoccerTestCatalog.categories, id: \.self) { category in
                    Button(category) { selection = category }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(selection == category ? Color.soccerAccent : Color.soccerSurface, in: Capsule())
                        .foregroundStyle(selection == category ? .white : Color.soccerText)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct SoccerTestRow: View {
    let test: SoccerTest
    let best: Double?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: test.icon)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.soccerAccent, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(test.name).font(.headline)
                Text(test.category).font(.caption.bold()).foregroundStyle(Color.soccerAccent)
                if let best {
                    Text("Personal best: \(SoccerTestResults.formatted(best, unit: test.unit))")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Target: \(SoccerTestResults.formatted(test.target, unit: test.unit))")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.soccerAccent)
        }
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 17))
    }
}

private struct SoccerTestDetailView: View {
    let test: SoccerTest
    @Binding var bestsText: String
    @State private var resultText = ""
    @State private var resultMessage = ""

    private var currentBest: Double? { SoccerTestResults.decode(bestsText)[test.id] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SoccerTestDetailHeader(test: test, currentBest: currentBest)
                SoccerTestInformation(title: "How to do the test", icon: "list.number", text: test.instructions)
                SoccerTestInformation(title: "Equipment", icon: "shippingbox.fill", text: test.equipment)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Record Your Result").font(.title2.bold())
                    TextField("Enter \(test.unit)", text: $resultText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Button("Save Result") { saveResult() }
                        .buttonStyle(.borderedProminent)
                        .disabled(Double(resultText) == nil)
                    if !resultMessage.isEmpty {
                        Label(resultMessage, systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.soccerAccent)
                    }
                }
                .padding()
                .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .navigationTitle(test.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveResult() {
        guard let result = Double(resultText), result > 0 else { return }
        var bests = SoccerTestResults.decode(bestsText)
        let previous = bests[test.id]
        let isBetter = previous.map { test.lowerIsBetter ? result < $0 : result > $0 } ?? true
        if isBetter {
            bests[test.id] = result
            bestsText = SoccerTestResults.encode(bests)
            resultMessage = previous == nil ? "First result saved!" : "New personal best!"
            Haptics.success()
        } else {
            resultMessage = "Result saved, but your personal best is still \(SoccerTestResults.formatted(previous ?? result, unit: test.unit))."
        }
    }
}

private struct SoccerTestDetailHeader: View {
    let test: SoccerTest
    let currentBest: Double?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: test.icon).font(.system(size: 48, weight: .bold))
            Text(test.name).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(currentBest.map { "Best: \(SoccerTestResults.formatted($0, unit: test.unit))" }
                ?? "Target: \(SoccerTestResults.formatted(test.target, unit: test.unit))")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .foregroundStyle(.white)
        .background(Color.soccerAccent.gradient, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct SoccerTestInformation: View {
    let title: String
    let icon: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.title3.bold()).foregroundStyle(Color.soccerAccent)
            Text(text).lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
    }
}
