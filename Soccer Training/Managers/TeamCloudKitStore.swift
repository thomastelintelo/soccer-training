import CloudKit
import Foundation
import Observation

@MainActor
@Observable
final class TeamCloudKitStore {
    private(set) var workspace: TeamWorkspace?
    private(set) var isLoading = false
    /// The member ID the player actually joined with. Differs from the one
    /// requested when the coach previously removed that ID from the team.
    private(set) var joinedMemberID: UUID?
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
                customDrills: [],
                schedule: []
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
            var workspace = try self.read(record)
            let registeredMembers = try await self.registeredMembers(code: normalizedCode)
            Self.merge(registeredMembers, into: &workspace)
            self.workspace = workspace
        }
    }

    func joinTeam(code: String, name: String, age: Int, position: String, memberID: UUID) async -> Bool {
        let normalizedCode = Self.normalize(code)
        guard normalizedCode.count == 6 else {
            errorMessage = "Enter the complete six-character team code."
            return false
        }

        await perform {
            let teamRecord = try await self.database.record(for: Self.recordID(for: normalizedCode))
            var workspace = try self.read(teamRecord)
            // A coach-removed ID stays filtered out of the roster forever, so
            // rejoining with it would never show up. Start a fresh identity.
            let memberID = (workspace.removedMemberIDs ?? []).contains(memberID) ? UUID() : memberID
            self.joinedMemberID = memberID
            let member = TeamMember(
                id: memberID,
                name: name.isEmpty ? "Player" : name,
                age: age,
                position: position,
                isCaptain: false,
                points: 0
            )

            try await self.saveMemberRegistration(member, code: normalizedCode)

            let registeredMembers = try await self.registeredMembers(code: normalizedCode)
            Self.merge(registeredMembers + [member], into: &workspace)
            self.workspace = workspace
        }
        return errorMessage == nil && workspace != nil
    }

    func removePlayer(_ memberID: UUID) async {
        await mutateCurrent { workspace in
            workspace.members.removeAll { $0.id == memberID }
            workspace.assignments.removeAll { $0.assignedMemberID == memberID }
            var removedMemberIDs = workspace.removedMemberIDs ?? []
            if !removedMemberIDs.contains(memberID) {
                removedMemberIDs.append(memberID)
            }
            workspace.removedMemberIDs = removedMemberIDs
        }
    }

    func updatePlayer(_ memberID: UUID, name: String, age: Int, position: String) async {
        await mutateCurrent { workspace in
            guard let index = workspace.members.firstIndex(where: { $0.id == memberID }) else { return }
            workspace.members[index].name = name.isEmpty ? workspace.members[index].name : name
            workspace.members[index].age = age
            workspace.members[index].position = position
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

    func addScheduleItem(
        weekday: String,
        startTime: Date,
        focus: String,
        drillName: String,
        durationMinutes: Int
    ) async {
        await mutateCurrent { workspace in
            var schedule = workspace.schedule ?? []
            schedule.append(
                CoachScheduleItem(
                    id: UUID(),
                    weekday: weekday,
                    startTime: startTime,
                    focus: focus,
                    drillName: drillName,
                    durationMinutes: durationMinutes
                )
            )
            workspace.schedule = schedule
        }
    }

    func removeScheduleItem(_ itemID: UUID) async {
        await mutateCurrent { workspace in
            workspace.schedule?.removeAll { $0.id == itemID }
        }
    }

    private func mutateCurrent(_ mutation: @escaping (inout TeamWorkspace) -> Void) async {
        guard let code = workspace?.joinCode else { return }
        await perform { try await self.update(code: code, mutation: mutation) }
    }

    private func update(code: String, mutation: (inout TeamWorkspace) -> Void) async throws {
        let record = try await database.record(for: Self.recordID(for: code))
        var latest = try read(record)
        let registeredMembers = try await registeredMembers(code: code)
        Self.merge(registeredMembers, into: &latest)
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
        } catch let error as CKError where error.code == .notAuthenticated {
            errorMessage = "Sign in to iCloud in Settings, then try joining again."
        } catch let error as CKError where error.code == .permissionFailure {
            errorMessage = "CloudKit denied access to this team. Ask the coach to reopen the team and try again."
        } catch let error as CKError where error.code == .networkUnavailable || error.code == .networkFailure {
            errorMessage = "The team could not be reached. Check the internet connection and try again."
        } catch {
            errorMessage = "Could not join the team. Please try again in a moment."
        }
    }

    private func registeredMembers(code: String) async throws -> [TeamMember] {
        let recordIDs = (0..<Self.maximumTeamSize).map { Self.memberRecordID(code: code, slot: $0) }
        let results = try await database.records(for: recordIDs, desiredKeys: ["member"])

        return results.values.compactMap { result in
            guard
                case .success(let record) = result,
                let data = record["member"] as? Data
            else { return nil }
            return try? decoder.decode(TeamMember.self, from: data)
        }
    }

    private func saveMemberRegistration(_ member: TeamMember, code: String) async throws {
        let occupiedResults = try await database.records(
            for: (0..<Self.maximumTeamSize).map { Self.memberRecordID(code: code, slot: $0) },
            desiredKeys: ["member"]
        )

        // Rejoining with the same ID refreshes the existing registration.
        for case .success(let existing) in occupiedResults.values {
            guard
                let data = existing["member"] as? Data,
                let saved = try? decoder.decode(TeamMember.self, from: data),
                saved.id == member.id
            else { continue }
            existing["member"] = try encoder.encode(member) as CKRecordValue
            _ = try await database.save(existing)
            return
        }

        for slot in 0..<Self.maximumTeamSize {
            let recordID = Self.memberRecordID(code: code, slot: slot)
            guard case .failure = occupiedResults[recordID] else { continue }

            let record = CKRecord(recordType: "FutbolTeamMember", recordID: recordID)
            record["teamCode"] = code as CKRecordValue
            record["member"] = try encoder.encode(member) as CKRecordValue

            do {
                _ = try await database.save(record)
                return
            } catch let error as CKError where error.code == .serverRecordChanged {
                continue
            }
        }

        throw TeamStoreError.teamFull
    }

    private static func merge(_ members: [TeamMember], into workspace: inout TeamWorkspace) {
        let removedMemberIDs = Set(workspace.removedMemberIDs ?? [])
        for member in members where !removedMemberIDs.contains(member.id)
            && !workspace.members.contains(where: { $0.id == member.id }) {
            workspace.members.append(member)
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

    private static let maximumTeamSize = 50

    private static func memberRecordID(code: String, slot: Int) -> CKRecord.ID {
        CKRecord.ID(recordName: "FutbolEliteTeam-\(normalize(code))-Member-\(slot)")
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
    case teamFull
}
