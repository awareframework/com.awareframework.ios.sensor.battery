//
//  ViewController.swift
//  com.awareframework.ios.sensor.battery
//
//  Created by tetujin on 11/20/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

import UIKit
import com_awareframework_ios_sensor_battery

class ViewController: UIViewController {
    
    var sensor:BatterySensor?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        sensor = BatterySensor.init(BatterySensor.Config().apply{config in
//            config.debug = true
//            config.sensorObserver = Observer()
//            config.dbType = .REALM
//        })
//        sensor?.start()
    }
    
    class Observer:BatteryObserver{
        func onBatteryChanged(data: BatteryData) {
            print(data)
        }
        
        func onBatteryLow() {
            print(#function)
        }
        
        func onBatteryCharging() {
            print(#function)
        }
        
        func onBatteryDischarging() {
            print(#function)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

