# Aware Battery

[![CI Status](http://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.battery.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.battery)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.battery.svg?style=flat)](http://cocoapods.org/pods/com.awareframework.ios.sensor.battery)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.battery.svg?style=flat)](http://cocoapods.org/pods/com.awareframework.ios.sensor.battery)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.battery.svg?style=flat)](http://cocoapods.org/pods/com.awareframework.ios.sensor.battery)

**Aware Battery** (com.awareframework.ios.sensor.battery) is a plugin for AWARE Framework which is one of an open-source context-aware instrument. This plugin allows us to handle battery conditions and events.

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

## Public functions

### BatterySensor

* `init(config:BatterySensor.Config?)` : Initializes the battery sensor with the optional configuration.
* `start()`: Starts the gyroscope sensor with the optional configuration.
* `stop()`: Stops the service.


### BatterySensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: BatterySensor.Observer`: Callback for live data updates.
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to `Logcat`. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_battery")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

### Fired Broadcasts

+ `Battery.ACTION_AWARE_BATTERY_CHANGED` broadcasted when the battery information changes.
+ `Battery.ACTION_AWARE_BATTERY_CHARGING` broadcasted when the device starts to charge.
+ `Battery.ACTION_AWARE_BATTERY_DISCHARGING` broadcasted when the device is unplugged and is running on battery.
+ `Battery.ACTION_AWARE_BATTERY_FULL` broadcasted when the device has finished charging.
+ `Battery.ACTION_AWARE_BATTERY_LOW` broadcasted when the device is low on battery (15% or less).

### Received Broadcasts

+ `BatterySensor.ACTION_AWARE_BATTERY_START`: received broadcast to start the sensor.
+ `BatterySensor.ACTION_AWARE_BATTERY_STOP`: received broadcast to stop the sensor.
+ `BatterySensor.ACTION_AWARE_BATTERY_SYNC`: received broadcast to send sync attempt to the host.
+ `BatterySensor.ACTION_AWARE_BATTERY_SET_LABEL`: received broadcast to set the data label. Label is expected in the `BatterySensor.EXTRA_LABEL` field of the intent extras.

## Data Representations


### Battery Data

| Field       | Type   | Description                                                                     |
| ----------- | ------ | ------------------------------------------------------------------------------- |
| status      | Int    | One of the [iOS’s battery status](https://developer.apple.com/documentation/uikit/uidevice/batterystate) |
| level       | Int    | Battery level, between 0 and 100                                              |
| scale       | Int    | Maximum battery level                                                           |
| deviceId    | String | AWARE device UUID                                                               |
| label       | String | Customizable label. Useful for data calibration or traceability                 |
| timestamp   | Long   | Unixtime milliseconds since 1970                                                |
| timezone    | Int    | Timezone  of the device                                          |
| os          | String | Operating system of the device (ex. android)                                    |

### Battery Discharges

| Field        | Type   | Description                                                     |
| ------------ | ------ | --------------------------------------------------------------- |
| start        | Int    | Battery level when the device started discharging               |
| end          | Int    | Battery level when the device stopped discharging               |
| endTimestamp | Long   | time instance of the end of discharge                           |
| deviceId     | String | AWARE device UUID                                               |
| label        | String | Customizable label. Useful for data calibration or traceability |
| timestamp    | Long   | Unixtime milliseconds since 1970                                |
| timezone     | Int    | Timezone of the device                          |
| os           | String | Operating system of the device (ex. android)                    |

### Battery Charge

| Field        | Type   | Description                                                     |
| ------------ | ------ | --------------------------------------------------------------- |
| start        | Int    | Battery level when the device started charging                  |
| end          | Int    | Battery level when the device stopped charging                  |
| endTimestamp | Long   | time instance of the end of charge                              |
| deviceId     | String | AWARE device UUID                                               |
| label        | String | Customizable label. Useful for data calibration or traceability |
| timestamp    | Long   | Unixtime milliseconds since 1970                                |
| timezone     | Int    | Timezone  of the device                          |
| os           | String | Operating system of the device (ex. android)                   


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

## Related links
* [ Apple | Battery State ](https://developer.apple.com/documentation/uikit/uidevice/batterystate)

## License
Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

