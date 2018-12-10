import XCTest
import RealmSwift
import com_awareframework_ios_sensor_battery
import com_awareframework_ios_sensor_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
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
        NotificationCenter.default.post(name: Notification.Name.UIDeviceBatteryStateDidChange, object: nil)
        NotificationCenter.default.post(name: Notification.Name.UIDeviceBatteryLevelDidChange, object: nil)
        
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
    
    
    
    func testSyncModule(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real device.")
        
        #else
        // success //
        let sensor = BatterySensor.init(BatterySensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_db"
        })
        if let engine = sensor.dbEngine as? RealmEngine {
            engine.removeAll(BatteryData.self)
            for _ in 0..<100 {
                engine.save(BatteryData())
            }
        }
        let successExpectation = XCTestExpectation(description: "success sync")
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareBatterySyncCompletion,
                                                              object: sensor, queue: .main) { (notification) in
                                                                if let userInfo = notification.userInfo{
                                                                    if let status = userInfo["status"] as? Bool {
                                                                        if status == true {
                                                                            successExpectation.fulfill()
                                                                        }
                                                                    }
                                                                }
        }
        sensor.sync(force: true)
        wait(for: [successExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(observer)
        
        ////////////////////////////////////
        
        // failure //
        let sensor2 = BatterySensor.init(BatterySensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com.com" // wrong url
            config.dbPath = "sync_db"
        })
        let failureExpectation = XCTestExpectation(description: "failure sync")
        let failureObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareBatterySyncCompletion,
                                                                     object: sensor2, queue: .main) { (notification) in
                                                                        if let userInfo = notification.userInfo{
                                                                            if let status = userInfo["status"] as? Bool {
                                                                                if status == false {
                                                                                    failureExpectation.fulfill()
                                                                                }
                                                                            }
                                                                        }
        }
        if let engine = sensor2.dbEngine as? RealmEngine {
            engine.removeAll(BatteryData.self)
            for _ in 0..<100 {
                engine.save(BatteryData())
            }
        }
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)
        
        #endif
    }

    
    
    
    //////////// storage ///////////
    
    var realmToken:NotificationToken? = nil
    
    func testSensorModule(){
        
//        #if targetEnvironment(simulator)
//
//        print("This test requires a real device.")
//
//        #else
        
        let sensor = BatterySensor.init(BatterySensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbPath = "sensor_module"
        })
        
        let expect = expectation(description: "sensor module")
        if let realmEngine = sensor.dbEngine as? RealmEngine {
            // remove old data
            realmEngine.removeAll(BatteryData.self)
            // get a RealmEngine Instance
            if let realm = realmEngine.getRealmInstance() {
                // set Realm DB observer
                realmToken = realm.observe { (notification, realm) in
                    switch notification {
                    case .didChange:
                        // check database size
                        let results = realm.objects(BatteryData.self)
                        print(results.count)
                        XCTAssertGreaterThanOrEqual(results.count, 1)
                        realm.invalidate()
                        expect.fulfill()
                        self.realmToken = nil
                        break;
                    case .refreshRequired:
                        break;
                    }
                }
            }
        }
        
        if let realmEngine = sensor.dbEngine as? RealmEngine {
            realmEngine.save(BatteryData())
        }
        
//        var storageExpect:XCTestExpectation? = expectation(description: "sensor storage notification")
//        var token: NSObjectProtocol?
//        token = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareBattery,
//                                                       object: sensor,
//                                                       queue: .main) { (notification) in
//                                                        if let exp = storageExpect {
//                                                            exp.fulfill()
//                                                            storageExpect = nil
//                                                            NotificationCenter.default.removeObserver(token!)
//                                                        }
//
//        }
//
//        sensor.start() // start sensor
        
        wait(for: [expect], timeout: 10)
        sensor.stop()
//        #endif
    }

}
