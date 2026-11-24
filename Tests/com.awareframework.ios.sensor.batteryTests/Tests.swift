import XCTest
@testable import com_awareframework_ios_sensor_battery
import com_awareframework_ios_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testObserver(){
        class Observer:BatteryObserver{
            
            weak var onBatteryStateExpectation: XCTestExpectation?
            
            func onBatteryChanged(data: BatteryData) {
                print(#function)
                self.onBatteryStateExpectation?.fulfill()
                self.onBatteryStateExpectation = nil
            }
            
            func onBatteryLow() {
                print(#function)
                self.onBatteryStateExpectation?.fulfill()
                self.onBatteryStateExpectation = nil
            }
            
            func onBatteryCharging() {
                print(#function)
                self.onBatteryStateExpectation?.fulfill()
                self.onBatteryStateExpectation = nil
            }
            
            func onBatteryDischarging() {
                print(#function)
                self.onBatteryStateExpectation?.fulfill()
                self.onBatteryStateExpectation = nil
            }

        }
        
        let onBatteryStateExpectation = expectation(description: "battery state observer")
        let onBatteryLevelExpectation = expectation(description: "battery level observer")
        
        // test battery state
        let observer = Observer()
        observer.onBatteryStateExpectation = onBatteryStateExpectation
        let sensor = BatterySensor.init(BatterySensor.Config().apply{ config in
            config.sensorObserver = observer
        })
        
        // test battery level
        weak var batteryLevelExpectation: XCTestExpectation?
        batteryLevelExpectation = onBatteryLevelExpectation
        let batteryLevelObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareBattery , object: nil, queue: .main) { (notification) in
            print(#function)
            if let expectation = batteryLevelExpectation {
                expectation.fulfill()
            }
            batteryLevelExpectation = nil
        }
        
        sensor.start()
        
        // send notification
        NotificationCenter.default.post(name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.post(name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        
        // wait 3 second or until fulfill the expectations
        wait(for: [onBatteryStateExpectation,onBatteryLevelExpectation],
             timeout: 3)
        sensor.stop()
        NotificationCenter.default.removeObserver(batteryLevelObserver)
    }
    
    func testControllers(){
        
        let sensor = BatterySensor.init()
        
        /// test set label action ///
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(forName: .actionAwareBatterySetLabel, object: nil, queue: .main) { (notification) in
            let dict = notification.userInfo;
            if let d = dict as? Dictionary<String,String>{
                XCTAssertEqual(d[BatterySensor.EXTRA_LABEL], newLabel)
            }else{
                XCTFail()
            }
            expectSetLabel.fulfill()
        }
        sensor.set(label:newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)
        
        /// test sync action ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareBatterySync , object: nil, queue: .main) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)
        
        
        //// test start action ////
        let expectStart = expectation(description: "start")
        let observer = NotificationCenter.default.addObserver(forName: .actionAwareBatteryStart,
                                                              object: nil,
                                                              queue: .main) { (notification) in
                                                                expectStart.fulfill()
                                                                print("start")
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(observer)
        
        
        /// test stop action ////
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(forName: .actionAwareBatteryStop, object: nil, queue: .main) { (notification) in
            expectStop.fulfill()
            print("stop")
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)
        
    }
    
    func testBatteryData(){
        var dict = BatteryData().toDictionary()
        XCTAssertEqual(dict["status"] as! Int, 0)
        XCTAssertEqual(dict["level"] as! Int, 0)
        XCTAssertEqual(dict["scale"] as! Int, 0)
    }
    
    
    
    // MARK: - Tables and sync (one engine per table)

    private func makeSensor(_ path: String, table: String? = nil) -> BatterySensor {
        BatterySensor(BatterySensor.Config().apply { c in
            c.dbPath = path
            c.dbHost = "localhost"
            if let table { c.dbTableName = table }
        })
    }

    func testDefaultTableName() {
        XCTAssertEqual(BatterySensor.Config().dbTableName, BatteryData.databaseTableName)
        XCTAssertEqual(BatterySensor().CONFIG.dbTableName, BatteryData.databaseTableName)
    }

    func testTablesAreCreated() throws {
        let sensor = makeSensor("battery_test_tables_\(UUID().uuidString)")
        let engine = try XCTUnwrap(sensor.dbEngine as? SQLiteEngine)
        for table in [BatteryData.databaseTableName, BatteryCharge.databaseTableName,
                      BatteryDischarge.databaseTableName] {
            XCTAssertFalse(try engine.fetchTableSchema(tableName: table).isEmpty, "\(table) is missing")
        }
    }

    func testOneSyncEnginePerTable() {
        let sensor = makeSensor("battery_test_engines_\(UUID().uuidString)")
        let names = sensor.syncEngines.values.map { $0.config.tableName }
        XCTAssertEqual(Set(names.compactMap { $0 }),
                       [BatteryData.databaseTableName, BatteryCharge.databaseTableName,
                        BatteryDischarge.databaseTableName])
        XCTAssertEqual(Set(sensor.syncEngines.values.map { ObjectIdentifier($0) }).count, 3)
        XCTAssertTrue(sensor.syncEngines[BatteryData.databaseTableName] === sensor.dbEngine)
    }

    func testCustomTableNameIsNotDuplicated() {
        // An app that points dbTableName at the charge table must not upload that table twice.
        let sensor = makeSensor("battery_test_custom_\(UUID().uuidString)", table: BatteryCharge.databaseTableName)
        XCTAssertEqual(sensor.syncEngines.count, 3)
        XCTAssertTrue(sensor.syncEngines[BatteryCharge.databaseTableName] === sensor.dbEngine)
    }

    func testSyncUploadsEachTableOnce() {
        let sensor = makeSensor("battery_test_sync_\(UUID().uuidString)")
        var charge = BatteryCharge(); charge.timestamp = 1
        var discharge = BatteryDischarge(); discharge.timestamp = 2
        var level = BatteryData(); level.timestamp = 3
        sensor.dbEngine?.save([level, charge, discharge])
        sensor.syncConfig?.test = true  // run the sync without network access

        let done = expectation(description: "three tables synced")
        done.expectedFulfillmentCount = 3
        var tables: [String] = []
        var syncIDs: [String] = []
        var completedTableCounts: [Int] = []
        var finalNotification: Notification?
        let lock = NSLock()
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareBatterySyncCompletion, object: sensor, queue: nil) { note in
            lock.lock(); defer { lock.unlock() }
            if let table = note.userInfo?[BatterySensor.EXTRA_TABLE_NAME] as? String {
                tables.append(table)
            }
            if let syncID = note.userInfo?[BatterySensor.EXTRA_SYNC_ID] as? String {
                syncIDs.append(syncID)
            }
            if let count = note.userInfo?[BatterySensor.EXTRA_COMPLETED_TABLE_COUNT] as? Int {
                completedTableCounts.append(count)
            }
            XCTAssertEqual(note.userInfo?[BatterySensor.EXTRA_STATUS] as? Bool, true)
            if note.userInfo?[BatterySensor.EXTRA_IS_FINAL] as? Bool == true {
                finalNotification = note
            }
            done.fulfill()
        }
        sensor.sync(force: true)
        wait(for: [done], timeout: 10)
        NotificationCenter.default.removeObserver(observer)
        XCTAssertEqual(tables.sorted(), [BatteryData.databaseTableName, BatteryCharge.databaseTableName,
                                         BatteryDischarge.databaseTableName].sorted())
        XCTAssertEqual(Set(syncIDs).count, 1)
        XCTAssertEqual(completedTableCounts, [1, 2, 3])
        XCTAssertEqual(
            finalNotification?.userInfo?[BatterySensor.EXTRA_AGGREGATE_STATUS] as? Bool, true)
        XCTAssertEqual(
            finalNotification?.userInfo?[BatterySensor.EXTRA_FAILED_TABLE_NAMES] as? [String], [])
    }

    func testSyncAfterEngineReinitialization() {
        let config = BatterySensor.Config().apply { c in
            c.dbPath = "battery_test_reinitialize_\(UUID().uuidString)"
        }
        let sensor = BatterySensor(config)
        XCTAssertTrue(sensor.syncEngines.values.allSatisfy { $0.config.host == nil })

        config.dbHost = "localhost"
        sensor.initializeDbEngine(config: config)

        XCTAssertEqual(sensor.syncEngines.count, 3)
        XCTAssertTrue(sensor.syncEngines.values.allSatisfy { $0.config.host == "localhost" })
        XCTAssertTrue(sensor.syncEngines[BatteryData.databaseTableName] === sensor.dbEngine)

        var charge = BatteryCharge(); charge.timestamp = 1
        var discharge = BatteryDischarge(); discharge.timestamp = 2
        var level = BatteryData(); level.timestamp = 3
        sensor.dbEngine?.save([level, charge, discharge])
        sensor.syncConfig?.test = true

        let done = expectation(description: "reinitialized engines complete all tables")
        done.expectedFulfillmentCount = 3
        var finalStatus: Bool?
        let lock = NSLock()
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareBatterySyncCompletion, object: sensor, queue: nil
        ) { note in
            lock.lock(); defer { lock.unlock() }
            if note.userInfo?[BatterySensor.EXTRA_IS_FINAL] as? Bool == true {
                finalStatus = note.userInfo?[BatterySensor.EXTRA_AGGREGATE_STATUS] as? Bool
            }
            done.fulfill()
        }
        sensor.sync(force: true)
        wait(for: [done], timeout: 10)
        NotificationCenter.default.removeObserver(observer)
        XCTAssertEqual(finalStatus, true)
    }

    func testMissingHostPostsFinalFailure() {
        let config = BatterySensor.Config().apply { c in
            c.dbPath = "battery_test_missing_host_\(UUID().uuidString)"
        }
        let sensor = BatterySensor(config)

        let done = expectation(description: "missing host reports every table")
        done.expectedFulfillmentCount = 3
        var finalNotification: Notification?
        let lock = NSLock()
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareBatterySyncCompletion, object: sensor, queue: nil
        ) { note in
            lock.lock(); defer { lock.unlock() }
            if note.userInfo?[BatterySensor.EXTRA_IS_FINAL] as? Bool == true {
                finalNotification = note
            }
            done.fulfill()
        }
        sensor.sync(force: true)
        wait(for: [done], timeout: 2)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertEqual(
            finalNotification?.userInfo?[BatterySensor.EXTRA_AGGREGATE_STATUS] as? Bool, false)
        XCTAssertEqual(
            Set(finalNotification?.userInfo?[BatterySensor.EXTRA_FAILED_TABLE_NAMES] as? [String] ?? []),
            Set(BatterySensor.tables.map { $0.name }))
        XCTAssertNotNil(finalNotification?.userInfo?[BatterySensor.EXTRA_AGGREGATE_ERROR])
    }

    func testPartialFailureIsPreservedInFinalAggregate() {
        let config = BatterySensor.Config().apply { c in
            c.dbPath = "battery_test_partial_failure_\(UUID().uuidString)"
            c.dbHost = "localhost"
        }
        let sensor = BatterySensor(config)
        sensor.syncConfig?.test = true
        sensor.syncEngines.removeValue(forKey: BatteryCharge.databaseTableName)?.close()

        let done = expectation(description: "partial failure completes all tables")
        done.expectedFulfillmentCount = 3
        var finalNotification: Notification?
        let lock = NSLock()
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareBatterySyncCompletion, object: sensor, queue: nil
        ) { note in
            lock.lock(); defer { lock.unlock() }
            if note.userInfo?[BatterySensor.EXTRA_IS_FINAL] as? Bool == true {
                finalNotification = note
            }
            done.fulfill()
        }
        sensor.sync(force: true)
        wait(for: [done], timeout: 10)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertEqual(
            finalNotification?.userInfo?[BatterySensor.EXTRA_STATUS] as? Bool, true,
            "The last table succeeds; aggregateStatus must retain the earlier failure")
        XCTAssertEqual(
            finalNotification?.userInfo?[BatterySensor.EXTRA_AGGREGATE_STATUS] as? Bool, false)
        XCTAssertEqual(
            finalNotification?.userInfo?[BatterySensor.EXTRA_FAILED_TABLE_NAMES] as? [String],
            [BatteryCharge.databaseTableName])
        XCTAssertNotNil(finalNotification?.userInfo?[BatterySensor.EXTRA_AGGREGATE_ERROR])
    }

    func testSyncModule() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires a real device with Realm.")
        #endif
    }

    
    
    
    //////////// storage ///////////
    
    func testSensorModule() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires a real device with Realm.")
        #endif
    }

}
