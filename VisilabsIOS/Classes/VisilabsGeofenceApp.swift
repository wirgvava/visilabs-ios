//
//  VisilabsGeofenceApp.swift
//  VisilabsIOS
//
//  Created by Egemen on 21.04.2020.
//

import Foundation

typealias VisilabsCallbackHandler = (Any?, Error?) -> Void

class VisilabsGeofenceApp: NSObject, UIApplicationDelegate {
    private static var instance: VisilabsGeofenceApp?
    
    private var isBridgeInitCalled = false
    private var isRegisterInstallForAppCalled = false
    private var isFinishLaunchOptionCalled = false
    private var isDebugMode = false
    
    var isDefaultLocationServiceEnabled = false
    
    private var _locationManager: VisilabsGeofenceLocationManager?
    var locationManager : VisilabsGeofenceLocationManager? {
        get { return _locationManager }
        set {
            //TODO: bunu kontrol et, bu init doğru mu?
            _locationManager = VisilabsGeofenceLocationManager()
        }
    }
    
    // hiçbir zaman set edilmiyor sanırım. kaldırılabilir.
    var reportWorkHomeLocationOnly: Bool {
        get {
            //TODO: "REPORT_WORKHOME_LOCATION_ONLY" ı VisilabsConfig e al
            return UserDefaults.standard.object(forKey: "REPORT_WORKHOME_LOCATION_ONLY") as? Bool ?? false
        }
        set {
            //TODO: "REPORT_WORKHOME_LOCATION_ONLY" ı VisilabsConfig e al
            UserDefaults.standard.set(newValue, forKey: "REPORT_WORKHOME_LOCATION_ONLY")
            UserDefaults.standard.synchronize()
            //TODO: "SH_LMBridge_StartMonitorGeoLocation" ı VisilabsConfig e al
            NotificationCenter.default.post(name: NSNotification.Name("SH_LMBridge_StartMonitorGeoLocation"), object: nil)
        }
    }
    
    public class func sharedInstance() -> VisilabsGeofenceApp? {
        if instance == nil{
            instance = VisilabsGeofenceApp()
        }
        if (!instance!.isBridgeInitCalled){
            instance!.isBridgeInitCalled = true
            let geofenceBridge: AnyClass? = NSClassFromString("VisilabsGeofenceBridge")
            if let geofenceBridge = geofenceBridge {
                print("Bridge for geofence: \(geofenceBridge).")
            }
            if geofenceBridge != nil {
                if let geofenceBridge = geofenceBridge {
                    //TODO: "SH_InitBridge_Notification" VisilabsConfig'e taşı
                    NotificationCenter.default.addObserver(geofenceBridge, selector: #selector(VisilabsGeofenceBridge.bridgeHandler(_:)), name: NSNotification.Name(rawValue: "SH_InitBridge_Notification"), object: nil)
                }
            }
        }
        return instance
    }
    
    override init() {
        //TODO: SH_GEOLOCATION_LAT isimlerini değiştir ve tipi CGFloat mu olacak kontrol et
        //NSUserDefaults value for passing value between modules. It's not used as local cache for location, and before use it must have notification "SH_LMBridge_UpdateGeoLocation" to update the value.
        //#define SH_GEOLOCATION_LAT      @"SH_GEOLOCATION_LAT"
        //#define SH_GEOLOCATION_LNG      @"SH_GEOLOCATION_LNG"
        VisilabsDataManager.save("SH_GEOLOCATION_LAT", withObject: CGFloat(0))
        VisilabsDataManager.save("SH_GEOLOCATION_LNG", withObject: CGFloat(0))
        
        self.backgroundQueue = OperationQueue()
        self.backgroundQueue.maxConcurrentOperationCount = 1
        self.install_semaphore = DispatchSemaphore(value: 1)
        
    }
    
    var isLocationServiceEnabled: Bool{
        get{
            guard let locationServiceEnabled = VisilabsDataManager.read("ENABLE_LOCATION_SERVICE") as? Bool else{
                return self.isDefaultLocationServiceEnabled
            }
            return locationServiceEnabled
        }set{
            if newValue == self.isLocationServiceEnabled{
                //TODO:
            }
        }
    }
    
    var install_semaphore: DispatchSemaphore
    var backgroundQueue: OperationQueue

    func registerOrUpdateInstall(with handler: VisilabsCallbackHandler) {
        DispatchQueue.global(qos: .default).async(execute: {
            assert(!Thread.isMainThread, "registerOrUpdateInstallWithHandler wait in main thread.")
            if !Thread.isMainThread {
                (self.install_semaphore.wait(timeout: DispatchTime.distantFuture) == .success ? 0 : -1)
            }
        })
    }

}


