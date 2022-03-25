//
//  TransactionTemplate.swift
//  macOS
//
//  Created by Eric Nims on 9/16/21.
//

import Foundation
import GRDB
import Combine
import GRDBQuery

struct TransactionTemplate: Identifiable, Codable, Hashable {
    var id: Int64?
    var template: String
    var templateData: JSONTransactionTemplate? {
        get {
            do {
                return try decodeTemplate()
            } catch {
                print(error)
            }
            return nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, template = "TemplateData"
    }
}

// SQL Database support
extension TransactionTemplate: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "TransactionTemplates"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let template = Column(CodingKeys.template)
    }
}

extension TransactionTemplate {
    static func newTemplate() -> TransactionTemplate {
        // This should never actually fail so we just ignore the exception
        // If it does the runtime crash will be useful
        let jsonData = try! JSONEncoder().encode(JSONTransactionTemplate(name: "", memo: "", amount: 0, tags: []))
        return TransactionTemplate(id: nil, template: String(data: jsonData, encoding: .utf8)!)
    }
    
    func decodeTemplate() throws -> JSONTransactionTemplate? {
        if let jsonData = template.data(using: .utf8) {
            let decoder = JSONDecoder()
            return try decoder.decode(JSONTransactionTemplate.self, from: jsonData)
        }
        return nil
    }
    
    func getName() -> String {
        do {
            let data = try decodeTemplate()
            if let data = data {
                return data.name
            }
        } catch {}
        return "Decoding Error"
    }
    
    func render() -> Transaction? {
        do {
            let data = try decodeTemplate()
            return data?.renderTransaction(date: Date())
        } catch {}
        return nil
    }
}

struct AllTemplates: Queryable {
    static var defaultValue: [TransactionTemplate] { [] }
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[TransactionTemplate], Error> {
        ValueObservation
            .tracking(TransactionTemplate.fetchAll)
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

