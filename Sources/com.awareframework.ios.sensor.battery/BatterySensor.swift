//
//  BatterySensor.swift
//  com.aware.ios.sensor.battery
//
//  Created by Yuuki Nishiyama on 2018/10/22.
//

import UIKit
import com_awareframework_ios_core
import SwiftyJSON

extension Notification.Name {
    public static let actionAwareBattery    = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY)
    public static let actionAwareBatteryStart    = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_START)
    public static let actionAwareBatteryStop     = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_STOP)
    public static let actionAwareBatterySync     = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_SYNC)
    public static let actionAwareBatterySetLabel = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_SET_LABEL)
    public static let actionAwareBatterySyncCompletion  = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_SYNC_COMPLETION)

    public static let actionAwareBatteryChanged  = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_CHANGED)
    public static let actionAwareBatteryFull     = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_FULL)
    public static let actionAwareBatteryCharging = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_CHARGING)
    public static let actionAwareBatteryDischarging = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_DISCHARGING)
    public static let actionAwareBatteryLow      = Notification.Name(BatterySensor.ACTION_AWARE_BATTERY_LOW)
    // public static let actionAwareBatteryShutdown = Notification.Name(BatterySensor.ACTION_AWARE_PHONE_SHUTDOWN)
    // public static let actionAwareBatteryReboot   = Notification.Name(BatterySensor.ACTION_AWARE_PHONE_REBOOT)
}

public protocol BatteryObserver {
    func onBatteryChanged(data: BatteryData)
    func onBatteryLow()
    func onBatteryCharging()
    func onBatteryDischarging()
    // func onPhoneReboot()
    // func onPhoneShutdown()
}

public class BatterySensor: AwareSensor {
    
    //public typealias AwareBatteryObserver = (_ data:BatteryData, _ error:Error?) -> Void

    public static var TAG = "AWARE::Battery"
    
    // Sensor actions
    public static let ACTION_AWARE_BATTERY = "com.awareframework.ios.sensor.battery"
    
    public static let ACTION_AWARE_BATTERY_START = "com.awareframework.ios.sensor.battery.ACTION_AWARE_BATTERY_START"
    public static let ACTION_AWARE_BATTERY_STOP = "com.awareframework.ios.sensor.battery.ACTION_AWARE_BATTERY_STOP"
    
    public static let ACTION_AWARE_BATTERY_SET_LABEL = "com.awareframework.ios.sensor.battery.ACTION_AWARE_BATTERY_SET_LABEL"
    public static var EXTRA_LABEL = "label"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let EXTRA_TABLE_NAME = "tableName"
    public static let EXTRA_OBJECT_TYPE = "objectType"
    public static let EXTRA_SYNC_ID = "syncID"
    public static let EXTRA_COMPLETED_TABLE_COUNT = "completedTableCount"
    public static let EXTRA_TABLE_COUNT = "tableCount"
    public static let EXTRA_IS_FINAL = "isFinal"
    public static let EXTRA_AGGREGATE_STATUS = "aggregateStatus"
    public static let EXTRA_AGGREGATE_ERROR = "aggregateError"
    public static let EXTRA_FAILED_TABLE_NAMES = "failedTableNames"
    
    public static let ACTION_AWARE_BATTERY_SYNC = "com.awareframework.ios.sensor.battery.ACTION_AWARE_BATTERY_SYNC"
    
    public static let ACTION_AWARE_BATTERY_SYNC_COMPLETION = "com.awareframework.ios.sensor.battery.ACTION_AWARE_BATTERY_SYNC_COMPLETION"
    
    /**
     * Broadcasted event: the battery values just changed
     */
    public static let ACTION_AWARE_BATTERY_CHANGED = "ACTION_AWARE_BATTERY_CHANGED"
    
    /**
     * Broadcasted event: the user just started charging
     */
    public static let ACTION_AWARE_BATTERY_CHARGING = "ACTION_AWARE_BATTERY_CHARGING"
    
    /**
     * Broadcasted event: battery charging over power supply (AC)
     */
    public static let ACTION_AWARE_BATTERY_CHARGING_AC = "ACTION_AWARE_BATTERY_CHARGING_AC"
    
    /**
     * Broadcasted event: battery charging over USB
     */
    public static let ACTION_AWARE_BATTERY_CHARGING_USB = "ACTION_AWARE_BATTERY_CHARGING_USB"
    
    /**
     * Broadcasted event: the user just stopped charging and is running on battery
     */
    public static let ACTION_AWARE_BATTERY_DISCHARGING = "ACTION_AWARE_BATTERY_DISCHARGING"
    
    /**
     * Broadcasted event: the battery is fully charged
     */
    public static let ACTION_AWARE_BATTERY_FULL = "ACTION_AWARE_BATTERY_FULL"
    
    /**
     * Broadcasted event: the battery is running low and should be charged ASAP
     */
    public static let ACTION_AWARE_BATTERY_LOW = "ACTION_AWARE_BATTERY_LOW"
    
    /**
     * Broadcasted event: the phone is about to be shutdown.
     */
    // public static let ACTION_AWARE_PHONE_SHUTDOWN = "ACTION_AWARE_PHONE_SHUTDOWN"
    
    /**
     * Broadcasted event: the phone is about to be rebooted.
     */
    // public static let ACTION_AWARE_PHONE_REBOOT = "ACTION_AWARE_PHONE_REBOOT"
    
    /**
     * [BatteryData.status] Phone shutdown
     */
    public static let STATUS_PHONE_SHUTDOWN = -1
    
    /**
     * [BatteryData.status] Phone rebooted
     */
    public static let STATUS_PHONE_REBOOT = -2
    
    /**
     * [BatteryData.status] Phone finished booting
     */
    public static let STATUS_PHONE_BOOTED = -3 // TODO
    
    public var CONFIG = Config()
    
    public class Config:SensorConfig{
    
        public var sensorObserver: BatteryObserver? = nil
        
        public override init() {
            super.init()
            dbPath = "aware_battery"
            dbTableName = BatteryData.databaseTableName
        }
    
        public func apply(closure:(_ config: BatterySensor.Config ) -> Void ) -> Self {
            closure(self)
            return self
        }
    
    }
    
    
    /**
     * BroadcastReceiver for Battery module
     * - ACTION_BATTERY_CHANGED: battery values changed
     * - ACTION_BATTERY_STATUS_FULL: battery finished charging
     * - ACTION_POWER_CHARGING: power is connected
     * - ACTION_POWER_DISCHARGING: power is disconnected
     * - ACTION_BATTERY_LOW: battery is running low (15% by iOS)
     * - ACTION_SHUTDOWN: phone is about to shut down
     * - ACTION_REBOOT: phone is about to reboot
     */
    public override convenience init() {
        self.init(BatterySensor.Config())
    }
    
    /// The tables this sensor writes, and the object type stored in each.
    static let tables: [(name: String, type: Any.Type)] = [
        (BatteryData.databaseTableName, BatteryData.self),
        (BatteryCharge.databaseTableName, BatteryCharge.self),
        (BatteryDischarge.databaseTableName, BatteryDischarge.self),
    ]

    /// One engine per table, used for upload. An engine uploads only the table named in its config,
    /// so each table needs its own engine. `dbEngine` is reused for the table it already names.
    var syncEngines: [String: Engine] = [:]

    /// Rebuilds every upload engine whenever the app applies a new database configuration.
    /// AWARE Client restores the server URL after constructing its sensors, so keeping the engines
    /// created by `init` would leave them with the old (usually nil) host forever.
    public override func initializeDbEngine(config: SensorConfig) {
        let currentPrimaryEngine = dbEngine
        syncEngines.values.forEach { engine in
            if let currentPrimaryEngine, engine === currentPrimaryEngine { return }
            engine.close()
        }
        syncEngines.removeAll()

        super.initializeDbEngine(config: config)
        initializeTables(config: config)

        for table in BatterySensor.tables {
            if let engine = dbEngine, engine.config.tableName == table.name {
                syncEngines[table.name] = engine
            } else {
                syncEngines[table.name] = Engine.Builder()
                    .setPath(config.dbPath)
                    .setType(config.dbType)
                    .setHost(config.dbHost)
                    .setEncryptionKey(config.dbEncryptionKey)
                    .setTableName(table.name)
                    .build()
            }
        }
    }

    public init(_ config:BatterySensor.Config){
        super.init()
        CONFIG = config
        if config.dbTableName == nil {
            config.dbTableName = BatteryData.databaseTableName
        }
        initializeDbEngine(config: config)
        super.syncConfig = DbSyncConfig().apply { c in
            c.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.battery.sync.queue")
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    /// Creates the three battery tables, so that the first save does not fail.
    /// Failures are logged: without the tables, battery data cannot be saved or uploaded.
    private func initializeTables(config: SensorConfig) {
        guard config.dbType == .sqlite else { return }
        guard let queue = (dbEngine as? SQLiteEngine)?.getSQLiteInstance() else {
            print(BatterySensor.TAG, "[Error] Cannot open the database '\(config.dbPath)'. The battery tables are not created.")
            return
        }
        let tables: [(name: String, create: () throws -> Void)] = [
            (BatteryData.databaseTableName, { try BatteryData.createTable(queue: queue) }),
            (BatteryCharge.databaseTableName, { try BatteryCharge.createTable(queue: queue) }),
            (BatteryDischarge.databaseTableName, { try BatteryDischarge.createTable(queue: queue) }),
        ]
        for table in tables {
            do {
                try table.create()
            } catch {
                print(BatterySensor.TAG, "[Error] Cannot create the table '\(table.name)': \(error)")
            }
        }
    }
    
    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false

    }
    
    override public func start() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(batteryStateDidChange(notification:)),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(batteryLevelDidChange(notification:)),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        self.batteryLevelDidChange(notification: NSNotification.init(name: UIDevice.batteryLevelDidChangeNotification, object: nil))
        self.batteryStateDidChange(notification: NSNotification.init(name: UIDevice.batteryStateDidChangeNotification, object: nil))
        
        self.notificationCenter.post(name: .actionAwareBatteryStart , object: self)
    }
    
    override public func stop() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.batteryStateDidChangeNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.batteryLevelDidChangeNotification,
                                                  object: nil)
        self.notificationCenter.post(name: .actionAwareBatteryStop , object: self)
    }
    
    /// Uploads the three battery tables (`ios_battery`, `ios_battery_charge`, `ios_battery_discharge`).
    /// Each table keeps its legacy completion notification. The last notification also contains the
    /// aggregate result so clients can wait for the whole Battery sensor upload to finish.
    override public func sync(force: Bool = false) {
        let syncID = UUID().uuidString
        self.notificationCenter.post(name: .actionAwareBatterySync, object: self)
        guard let base = self.syncConfig else {
            postUnavailableSyncCompletion(syncID: syncID)
            return
        }
        base.debug = self.CONFIG.debug
        startSequentialSync(
            tables: BatterySensor.tables,
            engines: syncEngines,
            syncConfig: base,
            currentIndex: 0,
            failedTableNames: [],
            lastError: nil,
            syncID: syncID)
    }

    private func makeSyncConfig(
        _ base: DbSyncConfig,
        tableIndex: Int,
        tableCount: Int,
        completionHandler: DbSyncCompletionHandler?
    ) -> DbSyncConfig {
        let c = base.copy()
        c.dispatchQueue = DispatchQueue(
            label: "com.awareframework.ios.sensor.battery.sync.\(tableIndex)")
        c.progressHandler = { progress, error in
            let tableWeight = 1.0 / Double(max(tableCount, 1))
            let overallProgress =
                (Double(tableIndex) * tableWeight) + (progress * tableWeight)
            base.progressHandler?(min(1.0, max(0.0, overallProgress)), error)
        }
        c.completionHandler = completionHandler
        return c
    }

    private func startSequentialSync(
        tables: [(name: String, type: Any.Type)],
        engines: [String: Engine],
        syncConfig: DbSyncConfig,
        currentIndex: Int,
        failedTableNames: [String],
        lastError: Error?,
        syncID: String
    ) {
        guard currentIndex < tables.count else { return }

        let table = tables[currentIndex]
        let completion: DbSyncCompletionHandler = { [weak self] status, error in
            guard let self else { return }
            let completedTableCount = currentIndex + 1
            let isFinal = completedTableCount == tables.count
            let updatedFailedTableNames =
                status ? failedTableNames : failedTableNames + [table.name]
            let completionError: Error?
            if status == false, error == nil {
                completionError = syncError("Sync failed for \(table.name)")
            } else {
                completionError = error
            }
            let aggregateError = completionError ?? lastError

            var userInfo: [String: Any] = [
                BatterySensor.EXTRA_STATUS: status,
                BatterySensor.EXTRA_TABLE_NAME: table.name,
                BatterySensor.EXTRA_OBJECT_TYPE: table.type,
                BatterySensor.EXTRA_SYNC_ID: syncID,
                BatterySensor.EXTRA_COMPLETED_TABLE_COUNT: completedTableCount,
                BatterySensor.EXTRA_TABLE_COUNT: tables.count,
                BatterySensor.EXTRA_IS_FINAL: isFinal,
            ]
            if let completionError {
                userInfo[BatterySensor.EXTRA_ERROR] = completionError
            }
            if isFinal {
                userInfo[BatterySensor.EXTRA_AGGREGATE_STATUS] =
                    updatedFailedTableNames.isEmpty
                userInfo[BatterySensor.EXTRA_FAILED_TABLE_NAMES] = updatedFailedTableNames
                if let aggregateError {
                    userInfo[BatterySensor.EXTRA_AGGREGATE_ERROR] = aggregateError
                }
            }
            self.notificationCenter.post(
                name: .actionAwareBatterySyncCompletion,
                object: self,
                userInfo: userInfo)

            guard isFinal == false else { return }
            self.startSequentialSync(
                tables: tables,
                engines: engines,
                syncConfig: syncConfig,
                currentIndex: completedTableCount,
                failedTableNames: updatedFailedTableNames,
                lastError: aggregateError,
                syncID: syncID)
        }

        guard let engine = engines[table.name] else {
            completion(false, syncError("Sync engine is unavailable for \(table.name)"))
            return
        }
        guard engine.config.host != nil else {
            completion(false, syncError("Sync host is unavailable for \(table.name)"))
            return
        }

        let perTableConfig = makeSyncConfig(
            syncConfig,
            tableIndex: currentIndex,
            tableCount: tables.count,
            completionHandler: completion)
        engine.startSync(perTableConfig)
    }

    private func postUnavailableSyncCompletion(syncID: String) {
        let error = syncError("Sync configuration is unavailable")
        notificationCenter.post(
            name: .actionAwareBatterySyncCompletion,
            object: self,
            userInfo: [
                BatterySensor.EXTRA_STATUS: false,
                BatterySensor.EXTRA_ERROR: error,
                BatterySensor.EXTRA_SYNC_ID: syncID,
                BatterySensor.EXTRA_COMPLETED_TABLE_COUNT: 0,
                BatterySensor.EXTRA_TABLE_COUNT: BatterySensor.tables.count,
                BatterySensor.EXTRA_IS_FINAL: true,
                BatterySensor.EXTRA_AGGREGATE_STATUS: false,
                BatterySensor.EXTRA_AGGREGATE_ERROR: error,
                BatterySensor.EXTRA_FAILED_TABLE_NAMES: BatterySensor.tables.map { $0.name },
            ])
    }

    private func syncError(_ message: String) -> NSError {
        NSError(
            domain: BatterySensor.TAG,
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    /////////
    @objc func batteryStateDidChange(notification: NSNotification){
        // The stage did change: plugged, unplugged, full charge...
//        BATTERY_STATUS_CHARGING     2
//        BATTERY_STATUS_DISCHARGING  3
//        BATTERY_STATUS_FULL         5
//        BATTERY_STATUS_NOT_CHARGING 4
//        BATTERY_STATUS_UNKNOWN      1
        let currentBatteryState = UIDevice.current.batteryState
        switch currentBatteryState{
        case .unknown:
            break
        case .unplugged:
            self.notificationCenter.post(name: .actionAwareBatteryDischarging , object: self)
            if let engin = self.dbEngine {
                var data = BatteryDischarge()
                data.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                data.label = self.CONFIG.label
                engin.save([data])
            }
            if let observer = self.CONFIG.sensorObserver{
                observer.onBatteryDischarging()
            }
            break
        case .charging:
            self.notificationCenter.post(name: .actionAwareBatteryCharging , object: self)
            if let engin = self.dbEngine {
                var data = BatteryCharge()
                data.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                data.label = self.CONFIG.label
                engin.save([data])
            }
            if let observer = self.CONFIG.sensorObserver{
                observer.onBatteryCharging()
            }
            break
        case .full:
            self.notificationCenter.post(name: .actionAwareBatteryFull , object: self)
            break
        @unknown default:
            break
        }
        self.notificationCenter.post(name: .actionAwareBattery, object: self)
    }
    
    @objc func batteryLevelDidChange(notification: NSNotification){
        // The battery's level did change (98%, 99%, ...)
        let currentBatteryLevel:Int = Int(UIDevice.current.batteryLevel * 100);
        let currentBatteryState = UIDevice.current.batteryState
        
        var data = BatteryData()
        data.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        data.level = currentBatteryLevel
        data.scale = 100
        data.label = self.CONFIG.label
        switch currentBatteryState{
        case .unknown:
            data.status = 1
            break
        case .unplugged:
            data.status = 3
            break
        case .charging:
            data.status = 2
            break
        case .full:
            data.status = 5
            break
        @unknown default:
            data.status = 1
        }
        
        if let engin = self.dbEngine {
            engin.save([data])
        }

        if let observer = self.CONFIG.sensorObserver{
            observer.onBatteryChanged(data: data)
        }

        if currentBatteryLevel < 15 {
            self.notificationCenter.post(name: .actionAwareBatteryLow , object: self)
            if let observer = self.CONFIG.sensorObserver{
                observer.onBatteryLow()
            }
        }
        self.notificationCenter.post(name: .actionAwareBattery, object: self)
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareBatterySetLabel,
                                     object: self,
                                     userInfo: [BatterySensor.EXTRA_LABEL:label])
    }
    
}
