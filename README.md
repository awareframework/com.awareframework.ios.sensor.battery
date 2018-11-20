# Aware Battery

[![CI Status](http://img.shields.io/travis/tetujin/com.awareframework.ios.sensor.battery.svg?style=flat)](https://travis-ci.org/tetujin/com.awareframework.ios.sensor.battery)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.battery.svg?style=flat)](http://cocoapods.org/pods/com.awareframework.ios.sensor.battery)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.battery.svg?style=flat)](http://cocoapods.org/pods/com.awareframework.ios.sensor.battery)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.battery.svg?style=flat)](http://cocoapods.org/pods/com.awareframework.ios.sensor.battery)

## Requirements
iOS 10 or later.

## Installation

com.awareframework.ios.sensor.battery is available through [CocoaPods](http://cocoapods.org). 

1. To install it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.battery'
```

2. Import com.awareframework.ios.sensor.battery library into your source code.
```swift
import com_awareframework_ios_sensor_battery
```

## Example usage

```swift
let batterySensor = BatterySensor.init(BatterySensor.Config().apply{ config in
    config.sensorObserver = Observer()
    config.debug = true
    config.dbType = .REALM
    // more configuration...
})
// To start the sensor
batterySensor.start()

// To stop the sensor
batterySensor.stop()
```

```swift
// Implement an interfance of AwareBatteryObserver
class Observer:BatteryObserver {
    func onBatteryChanged(data: BatteryData) {
        // Your code here ..
    }

    func onBatteryCharging() {
        // Your code here ..
    }

    func onBatteryDischarging() {
        // Your code here ..
    }

    func onBatteryLow() {
        // Your code here ..
    }
}
```

## Author

Yuuki Nishiyama, tetujin@ht.sfc.keio.ac.jp

## License
Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

