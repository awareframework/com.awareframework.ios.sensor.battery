# AWARE: Battery

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

**Aware Battery** (com.awareframework.ios.sensor.battery) is a plugin for AWARE Framework which is one of an open-source context-aware instrument. This plugin allows us to handle battery conditions and events.

## Requirements
iOS 13 or later.

## Installation


You can integrate this framework into your project via Swift Package Manager (SwiftPM).

### SwiftPM
1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...`

2. Find the package using the manager
    * Select `Search Package URL` and type `git@github.com:awareframework/com.awareframework.ios.sensor.battery.git`

3. Import the package into your target.

4. Import com.awareframework.ios.sensor.battery library into your source code.
```swift
import com_awareframework_ios_sensor_battery
```

## Public Functions

### BatterySensor

+ `init(config:BatterySensor.Config?)`: Initializes the battery sensor with the optional configuration.
+ `start()`: Starts the battery sensor with the optional configuration.
+ `stop()`: Stops the service.

### BatterySensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: BatteryObserver`: Callback for live data updates.
+ `enabled: Bool`: Sensor is enabled or not. (default = `false`)
+ `debug: Bool`: Enable/disable logging. (default = `false`)
+ `label: String`: Label for the data. (default = `""`)
+ `deviceId: String`: Id of the device that will be associated with the events and the sensor. (default = `""`)
+ `dbEncryptionKey: String?`: Encryption key for the database. (default = `nil`)
+ `dbType: DatabaseType`: Which db engine to use for saving data. (default = `.none`)
+ `dbPath: String`: Path of the database. (default = `"aware_battery"`)
+ `dbHost: String?`: Host for syncing the database. (default = `nil`)

## Broadcasts

### Fired Broadcasts

+ `Battery.ACTION_AWARE_BATTERY_CHANGED`: broadcasted when the battery information changes.
+ `Battery.ACTION_AWARE_BATTERY_CHARGING`: broadcasted when the device starts to charge.
+ `Battery.ACTION_AWARE_BATTERY_DISCHARGING`: broadcasted when the device is unplugged and is running on battery.
+ `Battery.ACTION_AWARE_BATTERY_FULL`: broadcasted when the device has finished charging.
+ `Battery.ACTION_AWARE_BATTERY_LOW`: broadcasted when the device is low on battery (15% or less).

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
| level       | Int    | Battery level, between 0 and 100                                                |
| scale       | Int    | Maximum battery level                                                           |
| deviceId    | String | AWARE device UUID                                                               |
| label       | String | Customizable label. Useful for data calibration or traceability                 |
| timestamp   | Int64  | Unixtime milliseconds since 1970                                                |
| timezone    | Int    | Timezone of the device                                                          |
| os          | String | Operating system of the device (ex. ios)                                        |
| jsonVersion | Int    | JSON schema version                                                             |

### Battery Discharges

| Field       | Type   | Description                                                     |
| ----------- | ------ | --------------------------------------------------------------- |
| deviceId    | String | AWARE device UUID                                               |
| label       | String | Customizable label. Useful for data calibration or traceability |
| timestamp   | Int64  | Unixtime milliseconds since 1970                                |
| timezone    | Int    | Timezone of the device                                          |
| os          | String | Operating system of the device (ex. ios)                        |
| jsonVersion | Int    | JSON schema version                                             |

### Battery Charge

| Field       | Type   | Description                                                     |
| ----------- | ------ | --------------------------------------------------------------- |
| deviceId    | String | AWARE device UUID                                               |
| label       | String | Customizable label. Useful for data calibration or traceability |
| timestamp   | Int64  | Unixtime milliseconds since 1970                                |
| timezone    | Int    | Timezone of the device                                          |
| os          | String | Operating system of the device (ex. ios)                        |
| jsonVersion | Int    | JSON schema version                                             |


## Example Usage

```swift
let batterySensor = BatterySensor.init(BatterySensor.Config().apply { config in
    config.sensorObserver = Observer()
    config.debug = true
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

Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## Related Links
* [ Apple | Battery State ](https://developer.apple.com/documentation/uikit/uidevice/batterystate)

## License
Copyright (c) 2025 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

