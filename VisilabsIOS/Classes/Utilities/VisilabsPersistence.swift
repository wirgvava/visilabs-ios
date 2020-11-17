//
//  VisilabsPersistence.swift
//  VisilabsIOS
//
//  Created by Egemen on 15.04.2020.
//

import Foundation

public class VisilabsPersistence {

    // MARK: - ARCHIVE

    private static let archiveQueueUtility = DispatchQueue(label: "com.relateddigital.archiveQueue", qos: .utility)

    private class func filePath(filename: String) -> String? {
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        guard let urlUnwrapped = url?.appendingPathComponent(filename).path else {
            return nil
        }
        return urlUnwrapped
    }

    class func archiveUser(_ visilabsUser: VisilabsUser) {
        archiveQueueUtility.sync { [visilabsUser] in
            let propertiesFilePath = filePath(filename: VisilabsConstants.userArchiveKey)
            guard let path = propertiesFilePath else {
                VisilabsLogger.error("bad file path, cant fetch file")
                return
            }
            var userDic = [String: String?]()
            userDic[VisilabsConstants.cookieIdKey] = visilabsUser.cookieId
            userDic[VisilabsConstants.exvisitorIdKey] = visilabsUser.exVisitorId
            userDic[VisilabsConstants.appidKey] = visilabsUser.appId
            userDic[VisilabsConstants.tokenIdKey] = visilabsUser.tokenId
            userDic[VisilabsConstants.userAgentKey] = visilabsUser.userAgent
            userDic[VisilabsConstants.visitorCappingKey] = visilabsUser.visitorData
            userDic[VisilabsConstants.visitorData] = visilabsUser.visitorData
            userDic[VisilabsConstants.mobileIdKey] = visilabsUser.identifierForAdvertising

            VisilabsExceptionWrapper.try({ [cObject = userDic, cPath = path] in
                if !NSKeyedArchiver.archiveRootObject(cObject, toFile: cPath) {
                    VisilabsLogger.error("failed to archive user")
                    return
                }
            }, catch: { (error) in
                VisilabsLogger.error("failed to archive user due to an uncaught exception")
                VisilabsLogger.error(error.debugDescription)
                return
            }, finally: {})
        }
    }

    //TODO: bunu ExceptionWrapper içine al
    class func unarchiveUser() -> VisilabsUser {
        var visilabsUser = VisilabsUser()
        //Before Visilabs.identity is used as archive key, to retrieve Visilabs.cookieID set by objective-c library
        //we added this control.
        if let cidfp = filePath(filename: VisilabsConstants.identityArchiveKey),
           let cid = NSKeyedUnarchiver.unarchiveObject(withFile: cidfp) as? String {
            visilabsUser.cookieId = cid
        }
        if let cidfp = filePath(filename: VisilabsConstants.cookieidArchiveKey),
           let cid = NSKeyedUnarchiver.unarchiveObject(withFile: cidfp) as? String {
            visilabsUser.cookieId = cid
        }
        if let exvidfp = filePath(filename: VisilabsConstants.exvisitorIdArchiveKey),
           let exvid = NSKeyedUnarchiver.unarchiveObject(withFile: exvidfp) as? String {
            visilabsUser.exVisitorId = exvid
        }
        if let appidfp = filePath(filename: VisilabsConstants.appidArchiveKey),
           let aid = NSKeyedUnarchiver.unarchiveObject(withFile: appidfp) as? String {
            visilabsUser.appId = aid
        }
        if let tidfp = filePath(filename: VisilabsConstants.tokenidArchiveKey),
           let tid = NSKeyedUnarchiver.unarchiveObject(withFile: tidfp) as? String {
            visilabsUser.tokenId = tid
        }
        if let uafp = filePath(filename: VisilabsConstants.useragentArchiveKey),
           let userAgent = NSKeyedUnarchiver.unarchiveObject(withFile: uafp) as? String {
            visilabsUser.userAgent = userAgent
        }

        if let propsfp = filePath(filename: VisilabsConstants.userArchiveKey),
           let props = NSKeyedUnarchiver.unarchiveObject(withFile: propsfp) as? [String: String?] {
            if let cid = props[VisilabsConstants.cookieIdKey], !cid.isNilOrWhiteSpace {
                visilabsUser.cookieId = cid
            }
            if let exvid = props[VisilabsConstants.exvisitorIdKey], !exvid.isNilOrWhiteSpace {
                visilabsUser.exVisitorId = exvid
            }
            if let aid = props[VisilabsConstants.appidKey], !aid.isNilOrWhiteSpace {
                visilabsUser.appId = aid
            }
            if let tid = props[VisilabsConstants.tokenIdKey], !tid.isNilOrWhiteSpace {
                visilabsUser.tokenId = tid
            }
            if let userAgent = props[VisilabsConstants.userAgentKey], !userAgent.isNilOrWhiteSpace {
                visilabsUser.userAgent = userAgent
            }
            if let visitorData = props[VisilabsConstants.visitorData], !visitorData.isNilOrWhiteSpace {
                visilabsUser.visitorData = visitorData
            }
            //TODO: visilabsUserda ya üstteki kod gereksiz ya da alttaki yanlış
            if let visitorData = props[VisilabsConstants.visitorCappingKey], !visitorData.isNilOrWhiteSpace {
                visilabsUser.visitorData = visitorData
            }
            if let madid = props[VisilabsConstants.mobileIdKey], !madid.isNilOrWhiteSpace {
                visilabsUser.identifierForAdvertising = madid
            }

        } else {
            VisilabsLogger.warn("Visilabs: Error while unarchiving properties.")
        }
        return visilabsUser
    }

    //TODO: burada date kısmı yanlış geliyor sanki
    //TODO: buradaki encode işlemleri doğru mu kontrol et, archiveQueue.sync { yerine archiveQueue.sync {[parameters] in
    class func saveTargetParameters(_ parameters: [String: String]) {
        archiveQueueUtility.sync {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormatter.string(from: Date())
            var targetParameters = readTargetParameters()

            for visilabsParameter in VisilabsConstants.visilabsTargetParameters() {
                let key = visilabsParameter.key
                let storeKey = visilabsParameter.storeKey
                let relatedKeys = visilabsParameter.relatedKeys
                let count = visilabsParameter.count
                if let parameterValue = parameters[key], parameterValue.count > 0 {
                    if count == 1 {
                        if relatedKeys != nil && relatedKeys!.count > 0 {
                            var parameterValueToStore = parameterValue.copy() as! String
                            let relatedKey = relatedKeys![0]
                            if parameters[relatedKey] != nil {
                                let relatedKeyValue = (parameters[relatedKey])?
                                    .trimmingCharacters(in: CharacterSet.whitespaces)
                                parameterValueToStore = parameterValueToStore + ("|")
                                parameterValueToStore = parameterValueToStore + (relatedKeyValue ?? "")
                            } else {
                                parameterValueToStore = parameterValueToStore + ("|0")
                            }
                            parameterValueToStore = parameterValueToStore + "|" + dateString
                            targetParameters[storeKey] = parameterValueToStore
                        } else {
                            targetParameters[storeKey] = parameterValue
                        }
                    } else if count > 1 {
                        let previousParameterValue = targetParameters[storeKey]
                        var parameterValueToStore = parameterValue.copy() as! String + ("|")
                        parameterValueToStore = parameterValueToStore + (dateString)
                        if previousParameterValue != nil && previousParameterValue!.count > 0 {
                            let previousParameterValueParts = previousParameterValue!.components(separatedBy: "~")
                            for counter in 0..<previousParameterValueParts.count {
                                if counter == 9 {
                                    break
                                }
                                let decodedPreviousParameterValuePart = previousParameterValueParts[counter] as String
                                //TODO:burayı kontrol et java'da "\\|" yapmak gerekiyordu.
                                let decodedPreviousParameterValuePartArray = decodedPreviousParameterValuePart
                                    .components(separatedBy: "|")
                                if decodedPreviousParameterValuePartArray.count == 2 {
                                    parameterValueToStore = parameterValueToStore + ("~")
                                    parameterValueToStore = parameterValueToStore + (decodedPreviousParameterValuePart )
                                }
                            }
                        }
                        targetParameters[storeKey] = parameterValueToStore
                    }
                }
            }

            saveUserDefaults(VisilabsConstants.userDefaultsTargetKey, withObject: targetParameters)
        }
    }

    class func readTargetParameters() -> [String: String] {
        guard let targetParameters = readUserDefaults(VisilabsConstants.userDefaultsTargetKey)
                as? [String: String] else {
            return [String: String]()
        }
        return targetParameters
    }

    class func clearTargetParameters() {
        removeUserDefaults(VisilabsConstants.userDefaultsTargetKey)
    }

    // MARK: - USER DEFAULTS

    static func saveUserDefaults(_ key: String, withObject value: Any?) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func readUserDefaults(_ key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    static func removeUserDefaults(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }

    static func saveVisilabsProfile(_ visilabsProfile: VisilabsProfile) {
        let encoder = JSONEncoder()
        if let encodedVisilabsProfile = try? encoder.encode(visilabsProfile) {
            saveUserDefaults(VisilabsConstants.userDefaultsProfileKey, withObject: encodedVisilabsProfile)
        }
    }

    static func readVisilabsProfile() -> VisilabsProfile? {
        if let savedVisilabsProfile = readUserDefaults(VisilabsConstants.userDefaultsProfileKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedVisilabsProfile = try? decoder.decode(VisilabsProfile.self, from: savedVisilabsProfile) {
                return loadedVisilabsProfile
            }
        }
        return nil
    }

    static func saveVisilabsGeofenceHistory(_ visilabsGeofenceHistory: VisilabsGeofenceHistory) {
        let encoder = JSONEncoder()
        if let encodedVisilabsGeofenceHistory = try? encoder.encode(visilabsGeofenceHistory) {
            saveUserDefaults(VisilabsConstants.userDefaultsGeofenceHistoryKey,
                             withObject: encodedVisilabsGeofenceHistory)
        }
    }

    public static func readVisilabsGeofenceHistory() -> VisilabsGeofenceHistory {
        if let savedVisilabsGeofenceHistory =
            readUserDefaults(VisilabsConstants.userDefaultsGeofenceHistoryKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedVisilabsGeofenceHistory = try? decoder.decode(VisilabsGeofenceHistory.self,
                                                                       from: savedVisilabsGeofenceHistory) {
                return loadedVisilabsGeofenceHistory
            }
        }
        return VisilabsGeofenceHistory()
    }

    public static func clearVisilabsGeofenceHistory() {
        removeUserDefaults(VisilabsConstants.userDefaultsGeofenceHistoryKey)
    }
}
