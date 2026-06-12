import Foundation
import com_awareframework_ios_core
import GRDB

public struct BatteryData: BaseDbModelSQLite {
    public var id: Int64?
    public var timestamp: Int64 = 0
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var label: String = ""
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1
    public static let databaseTableName = "ios_battery"

    public var status: Int = 0
    public var level:  Int = 0
    public var scale:  Int = 0

    public init() {}
    public init(_ dict: Dictionary<String, Any>) {
        timestamp = dict["timestamp"] as? Int64 ?? 0; label = dict["label"] as? String ?? ""
        deviceId  = dict["deviceId"]  as? String ?? AwareUtils.getCommonDeviceId()
        status = dict["status"] as? Int ?? 0; level = dict["level"] as? Int ?? 0
        scale  = dict["scale"]  as? Int ?? 0
    }
    public static func createTable(queue: DatabaseQueue) throws {
        try queue.write { db in try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("deviceId",.text).notNull(); t.column("timestamp",.integer).notNull()
            t.column("label",.text).notNull(); t.column("status",.integer).notNull()
            t.column("timezone",.integer).notNull(); t.column("os",.text).notNull()
            t.column("jsonVersion",.integer).notNull()
            t.column("level",.integer).notNull(); t.column("scale",.integer).notNull()
        }}
    }
    public func toDictionary() -> Dictionary<String, Any> {
        ["id": id ?? -1, "timestamp": timestamp, "deviceId": deviceId,
         "label": label, "status": status, "level": level, "scale": scale]
    }
}
