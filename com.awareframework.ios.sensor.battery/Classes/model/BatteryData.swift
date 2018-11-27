//
//  BatteryData.swift
//  com.aware.ios.sensor.battery
//
//  Created by Yuuki Nishiyama on 2018/10/22.
//

import UIKit
import com_awareframework_ios_sensor_core

public class BatteryData: AwareObject {
    public static var TABLE_NAME = "batteryData"
    
    @objc dynamic public var status: Int  = 0
    @objc dynamic public var level:  Int   = 0
    @objc dynamic public var scale:  Int   = 0

    /** iOS does not support following parameter */
//    var voltage: Int = 0
//    var temperature: Int = 0
//    var adaptor: Int = 0
//    var health: Int = 0
//    var technology: String = ""
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["status"] = status
        dict["level"]  = level
        dict["scale"]  = scale
        return dict;
    }
}
