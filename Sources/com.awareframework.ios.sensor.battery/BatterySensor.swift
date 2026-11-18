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

    public init(_ config:BatterySensor.Config){
        super.init()
        CONFIG = config
        if config.dbTableName == nil {
            config.dbTableName = BatteryData.databaseTableName
        }
        initializeDbEngine(config: config)
        initializeTables()
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
        super.syncConfig = DbSyncConfig().apply { c in
            c.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.battery.sync.queue")
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    /// Creates the three battery tables, so that the first save does not fail.
    private func initializeTables() {
        guard CONFIG.dbType == .sqlite,
              let queue = (dbEngine as? SQLiteEngine)?.getSQLiteInstance() else { return }
        try? BatteryData.createTable(queue: queue)
        try? BatteryCharge.createTable(queue: queue)
        try? BatteryDischarge.createTable(queue: queue)
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
    /// Each table is uploaded by its own engine with its own sync config and queue.
    override public func sync(force: Bool = false) {
        guard let base = self.syncConfig else { return }
        base.debug = self.CONFIG.debug
        for table in BatterySensor.tables {
            syncEngines[table.name]?.startSync(makeSyncConfig(base, tableName: table.name, objectType: table.type))
        }
        self.notificationCenter.post(name: .actionAwareBatterySync, object: self)
    }

    private func makeSyncConfig(_ base: DbSyncConfig, tableName: String, objectType: Any.Type) -> DbSyncConfig {
        let c = base.copy()
        c.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.battery.sync.\(tableName)")
        c.completionHandler = { (status, error) in
            var userInfo: Dictionary<String,Any> = ["status": status,
                                                    "tableName": tableName,
                                                    "objectType": objectType]
            if let e = error { userInfo["error"] = e }
            self.notificationCenter.post(name: .actionAwareBatterySyncCompletion, object: self, userInfo: userInfo)
        }
        return c
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
