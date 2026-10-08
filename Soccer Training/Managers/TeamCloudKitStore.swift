import CloudKit
import Foundation
import Observation

@MainActor
@Observable
final class TeamCloudKitStore {
    private(set) var workspace: TeamWorkspace?
    private(set) var isLoading = false
    var errorMessage: String?

    private let database = CKContainer.default().publicCloudDatabase
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func createTeam(teamName: String, coachName: String, ageGroup: String) async -> String? {
        await perform {
            let code = Self.makeCode()
            let workspace = TeamWorkspace(
                teamName: teamName,
                joinCode: code,
                ageGroup: ageGroup,
                coachName: coachName,
                members: [],
                assignments: [],
                customDrills: []
            )
            let record = CKRecord(recordType: "FutbolTeam", recordID: Self.recordID(for: code))
            try self.write(workspace, to: record)
            _ = try await self.database.save(record)
            self.workspace = workspace
        }
        return workspace?.joinCode
    }

    func loadTeam(code: String) async {
        let normalizedCode = Self.normalize(code)
        guard !normalizedCode.isEmpty else { return }
        await perform {
            let record = try await self.database.record(for: Self.recordID(for: normalizedCode))
            self.workspace = try self.read(record)
        }
    }

    func joinTeam(code: String, name: String, age: Int, position: String, memberID: UUID) async -> Bool {
        let normalizedCode = Self.normalize(code)
        await perform {
            try await self.update(code: normalizedCode) { workspace in
                guard !workspace.members.contains(where: { $0.id == memberID }) else { return }
                workspace.members.append(
                    TeamMember(id: memberID, name: name, age: age, position: position, isCaptain: false, points: 0)
                )
            }
        }
        return errorMessage == nil && workspace != nil
    }

    func addPlayer(name: String, age: Int, position: String) async {
        await mutateCurrent { workspace in
            workspace.members.append(
                TeamMember(id: UUID(), name: name, age: age, position: position, isCaptain: false, points: 0)
            )
        }
    }

    func toggleCaptain(_ memberID: UUID) async {
        await mutateCurrent { workspace in
            for index in workspace.members.indices {
                workspace.members[index].isCaptain = workspace.members[index].id == memberID
                    ? !workspace.members[index].isCaptain
                    : false
            }
        }
    }

    func addPoints(_ amount: Int, to memberID: UUID) async {
        await mutateCurrent { workspace in
            guard let index = workspace.members.firstIndex(where: { $0.id == memberID }) else { return }
            workspace.members[index].points += amount
        }
    }

    func assign(title: String, details: String, equipment: String, memberID: UUID?) async {
        await mutateCurrent { workspace in
            workspace.assignments.insert(
                TeamAssignment(
                    id: UUID(), title: title, details: details, equipment: equipment,
                    assignedMemberID: memberID, createdAt: .now
                ),
                at: 0
            )
        }
    }

    func createCustomDrill(name: String, category: String, instructions: String, equipment: String) async {
        await mutateCurrent { workspace in
            workspace.customDrills.insert(
                TeamCustomDrill(
                    id: UUID(), name: name, category: category,
                    instructions: instructions, equipment: equipment
                ),
                at: 0
            )
        }
    }

    private func mutateCurrent(_ mutation: @escaping (inout TeamWorkspace) -> Void) async {
        guard let code = workspace?.joinCode else { return }
        await perform { try await self.update(code: code, mutation: mutation) }
    }

    private func update(code: String, mutation: (inout TeamWorkspace) -> Void) async throws {
        let record = try await database.record(for: Self.recordID(for: code))
        var latest = try read(record)
        mutation(&latest)
        try write(latest, to: record)
        _ = try await database.save(record)
        workspace = latest
    }

    private func perform(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch let error as CKError where error.code == .unknownItem {
            errorMessage = "That team code was not found. Check it and try again."
        } catch {
            errorMessage = "Could not connect to the team. Check iCloud and your internet connection."
        }
    }

    private func read(_ record: CKRecord) throws -> TeamWorkspace {
        guard let data = record["workspace"] as? Data else { throw TeamStoreError.invalidData }
        return try decoder.decode(TeamWorkspace.self, from: data)
    }

    private func write(_ workspace: TeamWorkspace, to record: CKRecord) throws {
        record["workspace"] = try encoder.encode(workspace) as CKRecordValue
        record["joinCode"] = workspace.joinCode as CKRecordValue
        record["teamName"] = workspace.teamName as CKRecordValue
    }

    private static func recordID(for code: String) -> CKRecord.ID {
        CKRecord.ID(recordName: "FutbolEliteTeam-\(normalize(code))")
    }

    private static func normalize(_ code: String) -> String {
        code.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func makeCode() -> String {
        String((0..<6).compactMap { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement() })
    }
}

private enum TeamStoreError: Error {
    case invalidData
}
