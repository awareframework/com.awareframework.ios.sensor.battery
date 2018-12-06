import XCTest
import RealmSwift
import com_awareframework_ios_sensor_battery

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
    
    func testSync(){
        //        let sensor = BatterySensor.init(BatterySensor.Config().apply{ config in
        //            config.debug = true
        //            config.dbType = .REALM
        //        })
        //        sensor.start();
        //        sensor.enable();
        //        sensor.sync(force: true)
        
        //        let syncManager = DbSyncManager.Builder()
        //            .setBatteryOnly(false)
        //            .setWifiOnly(false)
        //            .setSyncInterval(1)
        //            .build()
        //
        //        syncManager.start()
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
}
