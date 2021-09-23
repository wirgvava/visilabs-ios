//
//  VisilabsInstance.swift
//  VisilabsIOS
//
//  Created by Egemen on 4.05.2020.
//

import class Foundation.Bundle
import SystemConfiguration
import UIKit

typealias Queue = [[String: String]]

struct VisilabsUser: Codable {
    var cookieId: String?
    var exVisitorId: String?
    var tokenId: String?
    var appId: String?
    var visitData: String?
    var visitorData: String?
    var userAgent: String?
    var identifierForAdvertising: String?
    var sdkVersion: String?
    var lastEventTime: String?
    var nrv = 0
    var pviv = 0
    var tvc = 0
    var lvt: String?
    var appVersion: String?
}

struct VisilabsProfile: Codable {
    var organizationId: String
    var profileId: String
    var dataSource: String
    var channel: String
    var requestTimeoutInSeconds: Int
    var geofenceEnabled: Bool
    var inAppNotificationsEnabled: Bool
    var maxGeofenceCount: Int
    var isIDFAEnabled: Bool
    var requestTimeoutInterval: TimeInterval {
        return TimeInterval(requestTimeoutInSeconds)
    }

    var useInsecureProtocol = false
}

public class VisilabsInstance: CustomDebugStringConvertible {
    var visilabsUser: VisilabsUser!
    var visilabsProfile: VisilabsProfile!
    var visilabsCookie = VisilabsCookie()
    var eventsQueue = Queue()
    var trackingQueue: DispatchQueue!
    var targetingActionQueue: DispatchQueue!
    var recommendationQueue: DispatchQueue!
    var networkQueue: DispatchQueue!
    let readWriteLock: VisilabsReadWriteLock

    // TO_DO: www.relateddigital.com ı değiştirmeli miyim?
    static let reachability = SCNetworkReachabilityCreateWithName(nil, "www.relateddigital.com")

    let visilabsEventInstance: VisilabsEvent
    let visilabsSendInstance: VisilabsSend
    let visilabsTargetingActionInstance: VisilabsTargetingAction
    let visilabsRecommendationInstance: VisilabsRecommendation

    public var debugDescription: String {
        return "Visilabs(siteId : \(visilabsProfile.profileId)" +
            "organizationId: \(visilabsProfile.organizationId)"
    }

    public var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                VisilabsLogger.enableLevel(.debug)
                VisilabsLogger.enableLevel(.info)
                VisilabsLogger.enableLevel(.warning)
                VisilabsLogger.enableLevel(.error)
                VisilabsLogger.info("Logging Enabled")
            } else {
                VisilabsLogger.info("Logging Disabled")
                VisilabsLogger.disableLevel(.debug)
                VisilabsLogger.disableLevel(.info)
                VisilabsLogger.disableLevel(.warning)
                VisilabsLogger.disableLevel(.error)
            }
        }
    }

    public var useInsecureProtocol: Bool = false {
        didSet {
            visilabsProfile.useInsecureProtocol = useInsecureProtocol
            VisilabsHelper.setEndpoints(dataSource: visilabsProfile.dataSource,
                                        useInsecureProtocol: useInsecureProtocol)
            VisilabsPersistence.saveVisilabsProfile(visilabsProfile)
        }
    }

    public weak var inappButtonDelegate: VisilabsInappButtonDelegate?

    // swiftlint:disable function_body_length
    init(organizationId: String,
         profileId: String,
         dataSource: String,
         inAppNotificationsEnabled: Bool,
         channel: String,
         requestTimeoutInSeconds: Int,
         geofenceEnabled: Bool,
         maxGeofenceCount: Int,
         isIDFAEnabled: Bool = true) {
        // TO_DO: bu reachability doğru çalışıyor mu kontrol et
        if let reachability = VisilabsInstance.reachability {
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil,
                                                       release: nil, copyDescription: nil)

            func reachabilityCallback(reachability: SCNetworkReachability,
                                      flags: SCNetworkReachabilityFlags,
                                      unsafePointer: UnsafeMutableRawPointer?) {
                let wifi = flags.contains(SCNetworkReachabilityFlags.reachable)
                    && !flags.contains(SCNetworkReachabilityFlags.isWWAN)
                VisilabsLogger.info("reachability changed, wifi=\(wifi)")
            }
            if SCNetworkReachabilitySetCallback(reachability, reachabilityCallback, &context) {
                if !SCNetworkReachabilitySetDispatchQueue(reachability, trackingQueue) {
                    // cleanup callback if setting dispatch queue failed
                    SCNetworkReachabilitySetCallback(reachability, nil, nil)
                }
            }
        }

        visilabsProfile = VisilabsProfile(organizationId: organizationId,
                                          profileId: profileId,
                                          dataSource: dataSource,
                                          channel: channel,
                                          requestTimeoutInSeconds: requestTimeoutInSeconds,
                                          geofenceEnabled: geofenceEnabled,
                                          inAppNotificationsEnabled: inAppNotificationsEnabled,
                                          maxGeofenceCount: (maxGeofenceCount < 0 && maxGeofenceCount > 20) ? 20 : maxGeofenceCount,
                                          isIDFAEnabled: isIDFAEnabled)
        VisilabsPersistence.saveVisilabsProfile(visilabsProfile)

        readWriteLock = VisilabsReadWriteLock(label: "VisilabsInstanceLock")
        let label = "com.relateddigital.\(visilabsProfile.profileId)"
        trackingQueue = DispatchQueue(label: "\(label).tracking)", qos: .utility)
        recommendationQueue = DispatchQueue(label: "\(label).recommendation)", qos: .utility)
        targetingActionQueue = DispatchQueue(label: "\(label).targetingaction)", qos: .utility)
        networkQueue = DispatchQueue(label: "\(label).network)", qos: .utility)
        visilabsEventInstance = VisilabsEvent(visilabsProfile: visilabsProfile)
        visilabsSendInstance = VisilabsSend()
        visilabsTargetingActionInstance = VisilabsTargetingAction(lock: readWriteLock,
                                                                  visilabsProfile: visilabsProfile)
        visilabsRecommendationInstance = VisilabsRecommendation(visilabsProfile: visilabsProfile)

        visilabsUser = unarchive()
        visilabsTargetingActionInstance.inAppDelegate = self

        if isIDFAEnabled {
            VisilabsHelper.getIDFA { uuid in
                if let idfa = uuid {
                    self.visilabsUser.identifierForAdvertising = idfa
                }
            }
        }

        visilabsUser.sdkVersion = "3.0.8"
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: Visilabs.self)
        #endif
        if let infos = bundle.infoDictionary {
            if let shortVersion = infos["CFBundleShortVersionString"] as? String {
                visilabsUser.sdkVersion = shortVersion
            }
        }
        
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            visilabsUser.appVersion = appVersion
        }
        
        if visilabsUser.cookieId.isNilOrWhiteSpace {
            visilabsUser.cookieId = VisilabsHelper.generateCookieId()
            VisilabsPersistence.archiveUser(visilabsUser)
        }

        if visilabsProfile.geofenceEnabled {
            startGeofencing()
        }

        VisilabsHelper.setEndpoints(dataSource: visilabsProfile.dataSource)

        VisilabsHelper.computeWebViewUserAgent { userAgentString in
            self.visilabsUser.userAgent = userAgentString
        }
    }

    convenience init?() {
        if let visilabsProfile = VisilabsPersistence.readVisilabsProfile() {
            self.init(organizationId: visilabsProfile.organizationId,
                      profileId: visilabsProfile.profileId,
                      dataSource: visilabsProfile.dataSource,
                      inAppNotificationsEnabled: visilabsProfile.inAppNotificationsEnabled,
                      channel: visilabsProfile.channel,
                      requestTimeoutInSeconds: visilabsProfile.requestTimeoutInSeconds,
                      geofenceEnabled: visilabsProfile.geofenceEnabled,
                      maxGeofenceCount: visilabsProfile.maxGeofenceCount,
                      isIDFAEnabled: visilabsProfile.isIDFAEnabled)
        } else {
            return nil
        }
    }

    static func sharedUIApplication() -> UIApplication? {
        let shared = UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue()
        guard let sharedApplication = shared as? UIApplication else {
            return nil
        }
        return sharedApplication
    }
}

// MARK: - EVENT

extension VisilabsInstance {
    public func customEvent(_ pageName: String, properties: [String: String]) {
        
        /*
        if VisilabsRemoteConfig.isBlocked == true {
            VisilabsLogger.info("Too much server load!")
            return
        }
        */
         
        if pageName.isEmptyOrWhitespace {
            VisilabsLogger.error("customEvent can not be called with empty page name.")
            return
        }
        
        trackingQueue.async { [weak self, pageName, properties] in
            guard let self = self else { return }
            var eQueue = Queue()
            var vUser = VisilabsUser()
            var chan = ""
            self.readWriteLock.read {
                eQueue = self.eventsQueue
                vUser = self.visilabsUser
                chan = self.visilabsProfile.channel
            }
            let result = self.visilabsEventInstance.customEvent(pageName: pageName,
                                                                properties: properties,
                                                                eventsQueue: eQueue,
                                                                visilabsUser: vUser,
                                                                channel: chan)
            self.readWriteLock.write {
                self.eventsQueue = result.eventsQueque
                self.visilabsUser = result.visilabsUser
                self.visilabsProfile.channel = result.channel
            }
            self.readWriteLock.read {
                VisilabsPersistence.archiveUser(self.visilabsUser)
                if result.clearUserParameters {
                    VisilabsPersistence.clearTargetParameters()
                }
            }
            if let event = self.eventsQueue.last {
                VisilabsPersistence.saveTargetParameters(event)
                if VisilabsBasePath.endpoints[.action] != nil,
                   self.visilabsProfile.inAppNotificationsEnabled,
                   pageName != VisilabsConstants.omEvtGif {
                    self.checkInAppNotification(properties: event)
                    self.checkTargetingActions(properties: event)
                }
            }
            self.send()
        }
    }

    public func sendCampaignParameters(properties: [String: String]) {
        
        /*
        if VisilabsRemoteConfig.isBlocked == true {
            VisilabsLogger.info("Too much server load!")
            return
        }
         */
        
        trackingQueue.async { [weak self, properties] in
            guard let strongSelf = self else { return }
            var eQueue = Queue()
            var vUser = VisilabsUser()
            var chan = ""
            strongSelf.readWriteLock.read {
                eQueue = strongSelf.eventsQueue
                vUser = strongSelf.visilabsUser
                chan = strongSelf.visilabsProfile.channel
            }
            let result = strongSelf.visilabsEventInstance.customEvent(properties: properties,
                                                                      eventsQueue: eQueue,
                                                                      visilabsUser: vUser,
                                                                      channel: chan)
            strongSelf.readWriteLock.write {
                strongSelf.eventsQueue = result.eventsQueque
                strongSelf.visilabsUser = result.visilabsUser
                strongSelf.visilabsProfile.channel = result.channel
            }
            strongSelf.readWriteLock.read {
                VisilabsPersistence.archiveUser(strongSelf.visilabsUser)
                if result.clearUserParameters {
                    VisilabsPersistence.clearTargetParameters()
                }
            }
            if let event = strongSelf.eventsQueue.last {
                VisilabsPersistence.saveTargetParameters(event)
            }
            strongSelf.send()
        }
    }

    public func login(exVisitorId: String, properties: [String: String] = [String: String]()) {
        if exVisitorId.isEmptyOrWhitespace {
            VisilabsLogger.error("login can not be called with empty exVisitorId.")
            return
        }
        var props = properties
        props[VisilabsConstants.exvisitorIdKey] = exVisitorId
        props["Login"] = exVisitorId
        props["OM.b_login"] = "Login"
        customEvent("LoginPage", properties: props)
    }

    public func signUp(exVisitorId: String, properties: [String: String] = [String: String]()) {
        if exVisitorId.isEmptyOrWhitespace {
            VisilabsLogger.error("signUp can not be called with empty exVisitorId.")
            return
        }
        var props = properties
        props[VisilabsConstants.exvisitorIdKey] = exVisitorId
        props["SignUp"] = exVisitorId
        props["OM.b_sgnp"] = "SignUp"
        customEvent("SignUpPage", properties: props)
    }

    public func getExVisitorId() -> String? {
        return visilabsUser.exVisitorId
    }

    public func logout() {
        VisilabsPersistence.clearUserDefaults()
        visilabsUser.cookieId = nil
        visilabsUser.exVisitorId = nil
        visilabsUser.cookieId = VisilabsHelper.generateCookieId()
        VisilabsPersistence.archiveUser(visilabsUser)
    }
    
}

// MARK: - PERSISTENCE

extension VisilabsInstance {
    private func archive() {
    }

    // TO_DO: kontrol et sıra doğru mu? gelen değerler null ise set'lemeli miyim?
    private func unarchive() -> VisilabsUser {
        return VisilabsPersistence.unarchiveUser()
    }
}

// MARK: - SEND

extension VisilabsInstance {
    private func send() {
        trackingQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var eQueue = Queue()
                var vUser = VisilabsUser()
                var vCookie = VisilabsCookie()
                self.readWriteLock.read {
                    eQueue = self.eventsQueue
                    vUser = self.visilabsUser
                    vCookie = self.visilabsCookie
                }
                self.readWriteLock.write {
                    self.eventsQueue.removeAll()
                }
                let cookie = self.visilabsSendInstance.sendEventsQueue(eQueue,
                                                                       visilabsUser: vUser,
                                                                       visilabsCookie: vCookie,
                                                                       timeoutInterval: self.visilabsProfile.requestTimeoutInterval)
                self.readWriteLock.write {
                    self.visilabsCookie = cookie
                }
            }
        }
    }
}

// MARK: - TARGETING ACTIONS

// MARK: - Favorite Attribute Actions

extension VisilabsInstance {
    public func getFavoriteAttributeActions(actionId: Int? = nil,
                                            completion: @escaping ((_ response: VisilabsFavoriteAttributeActionResponse)
                                                -> Void)) {
        targetingActionQueue.async { [weak self] in
            self?.networkQueue.async { [weak self] in
                guard let self = self else { return }
                var vUser = VisilabsUser()
                self.readWriteLock.read {
                    vUser = self.visilabsUser
                }
                self.visilabsTargetingActionInstance.getFavorites(visilabsUser: vUser,
                                                                  actionId: actionId,
                                                                  completion: completion)
            }
        }
    }
}

// MARK: - InAppNotification

extension VisilabsInstance: VisilabsInAppNotificationsDelegate {
    // This method added for test purposes
    public func showNotification(_ visilabsInAppNotification: VisilabsInAppNotification) {
        visilabsTargetingActionInstance.notificationsInstance.showNotification(visilabsInAppNotification)
    }

    public func showTargetingAction(_ model: TargetingActionViewModel) {
        visilabsTargetingActionInstance.notificationsInstance.showTargetingAction(model)
    }

    func checkInAppNotification(properties: [String: String]) {
        trackingQueue.async { [weak self, properties] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, properties] in
                guard let self = self else { return }
                self.visilabsTargetingActionInstance.checkInAppNotification(properties: properties,
                                                                            visilabsUser: self.visilabsUser,
                                                                            completion: { visilabsInAppNotification in
                                                                                if let notification = visilabsInAppNotification {
                                                                                    self.visilabsTargetingActionInstance.notificationsInstance.inappButtonDelegate = self.inappButtonDelegate
                                                                                    self.visilabsTargetingActionInstance.notificationsInstance.showNotification(notification)
                                                                                }
                                                                            })
            }
        }
    }

    func notificationDidShow(_ notification: VisilabsInAppNotification) {
        visilabsUser.visitData = notification.visitData
        visilabsUser.visitorData = notification.visitorData
        VisilabsPersistence.archiveUser(visilabsUser)
    }

    func trackNotification(_ notification: VisilabsInAppNotification, event: String, properties: [String: String]) {
        if notification.queryString == nil || notification.queryString == "" {
            VisilabsLogger.info("Notification or query string is nil or empty")
            return
        }
        let queryString = notification.queryString
        let qsArr = queryString!.components(separatedBy: "&")
        var properties = properties
        properties[VisilabsConstants.domainkey] = "\(visilabsProfile.dataSource)_IOS"
        properties["OM.zn"] = qsArr[0].components(separatedBy: "=")[1]
        properties["OM.zpc"] = qsArr[1].components(separatedBy: "=")[1]
        customEvent(VisilabsConstants.omEvtGif, properties: properties)
    }

    // İleride inapp de s.visilabs.net/mobile üzerinden geldiğinde sadece bu metod kullanılacak
    // checkInAppNotification metodu kaldırılacak.
    func checkTargetingActions(properties: [String: String]) {
        trackingQueue.async { [weak self, properties] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, properties] in
                guard let self = self else { return }
                self.visilabsTargetingActionInstance.checkTargetingActions(properties: properties, visilabsUser: self.visilabsUser, completion: { model in
                    if let targetingAction = model {
                        self.showTargetingAction(targetingAction)
                    }
                })
            }
        }
    }

    func subscribeSpinToWinMail(actid: String, auth: String, mail: String) {
        createSubsJsonRequest(actid: actid, auth: auth, mail: mail, type: "spin_to_win_email")
    }

    func trackSpinToWinClick(spinToWinReport: SpinToWinReport) {
        var properties = [String: String]()
        properties[VisilabsConstants.domainkey] = "\(visilabsProfile.dataSource)_IOS"
        properties["OM.zn"] = spinToWinReport.click.parseClick().omZn
        properties["OM.zpc"] = spinToWinReport.click.parseClick().omZpc
        customEvent(VisilabsConstants.omEvtGif, properties: properties)
    }
}

// MARK: - Story

extension VisilabsInstance {
    public func getStoryView(actionId: Int? = nil, urlDelegate: VisilabsStoryURLDelegate? = nil) -> VisilabsStoryHomeView {
        let guid = UUID().uuidString
        let storyHomeView = VisilabsStoryHomeView()
        let storyHomeViewController = VisilabsStoryHomeViewController()
        storyHomeViewController.urlDelegate = urlDelegate
        storyHomeView.controller = storyHomeViewController
        visilabsTargetingActionInstance.visilabsStoryHomeViewControllers[guid] = storyHomeViewController
        visilabsTargetingActionInstance.visilabsStoryHomeViews[guid] = storyHomeView
        storyHomeView.setDelegates()
        storyHomeViewController.collectionView = storyHomeView.collectionView

        trackingQueue.async { [weak self, actionId, guid] in
            guard let self = self else { return }
            self.networkQueue.async { [weak self, actionId, guid] in
                guard let self = self else { return }
                self.visilabsTargetingActionInstance.getStories(visilabsUser: self.visilabsUser,
                                                                guid: guid,
                                                                actionId: actionId,
                                                                completion: { response in
                                                                    if let error = response.error {
                                                                        VisilabsLogger.error(error)
                                                                    } else {
                                                                        if let guid = response.guid, response.storyActions.count > 0,
                                                                           let storyHomeViewController = self.visilabsTargetingActionInstance.visilabsStoryHomeViewControllers[guid],
                                                                           let storyHomeView = self.visilabsTargetingActionInstance.visilabsStoryHomeViews[guid] {
                                                                            DispatchQueue.main.async {
                                                                                storyHomeViewController.loadStoryAction(response.storyActions.first!)
                                                                                storyHomeView.collectionView.reloadData()
                                                                                storyHomeView.setDelegates()
                                                                                storyHomeViewController.collectionView = storyHomeView.collectionView
                                                                            }
                                                                        }
                                                                    }
                                                                })
            }
        }

        return storyHomeView
    }
}

// MARK: - RECOMMENDATION

extension VisilabsInstance {
    public func recommend(zoneID: String,
                          productCode: String? = nil,
                          filters: [VisilabsRecommendationFilter] = [],
                          properties: [String: String] = [:],
                          completion: @escaping ((_ response: VisilabsRecommendationResponse) -> Void)) {
        recommendationQueue.async { [weak self, zoneID, productCode, filters, properties, completion] in
            self?.networkQueue.async { [weak self, zoneID, productCode, filters, properties, completion] in
                guard let self = self else { return }
                var vUser = VisilabsUser()
                var channel = "IOS"
                self.readWriteLock.read {
                    vUser = self.visilabsUser
                    channel = self.visilabsProfile.channel
                }
                self.visilabsRecommendationInstance.recommend(zoneID: zoneID,
                                                              productCode: productCode,
                                                              visilabsUser: vUser,
                                                              channel: channel,
                                                              properties: properties,
                                                              filters: filters) { response in
                    completion(response)
                }
            }
        }
    }
    
    public func trackRecommendationClick(qs: String) {
        let qsArr = qs.components(separatedBy: "&")
        var properties = [String: String]()
        properties[VisilabsConstants.domainkey] = "\(visilabsProfile.dataSource)_IOS"
        if(qsArr.count > 1) {
            for queryItem in qsArr {
                let arrComponents = queryItem.components(separatedBy: "=")
                if arrComponents.count == 2 {
                    properties[arrComponents[0]] = arrComponents[1]
                }
            }
        } else {
            VisilabsLogger.info("qs length is less than 2")
            return
        }
        customEvent(VisilabsConstants.omEvtGif, properties: properties)
    }
    
}

// MARK: - GEOFENCE

extension VisilabsInstance {
    private func startGeofencing() {
        VisilabsGeofence.sharedManager?.startGeofencing()
    }

    public var locationServicesEnabledForDevice: Bool {
        return VisilabsGeofence.sharedManager?.locationServicesEnabledForDevice ?? false
    }

    public var locationServiceStateStatusForApplication: VisilabsCLAuthorizationStatus {
        return VisilabsGeofence.sharedManager?.locationServiceStateStatusForApplication ?? .none
    }
    
    public func sendLocationPermission() {
        VisilabsLocationManager.sharedManager.sendLocationPermissions()
    }

    // swiftlint:disable file_length
}

// MARK: - SUBSCRIPTION MAIL

extension VisilabsInstance {
    public func subscribeMail(click: String, actid: String, auth: String, mail: String) {
        if click.isEmpty {
            VisilabsLogger.info("Notification or query string is nil or empty")
            return
        }

        var properties = [String: String]()
        properties[VisilabsConstants.domainkey] = "\(visilabsProfile.dataSource)_IOS"
        properties["OM.zn"] = click.parseClick().omZn
        properties["OM.zpc"] = click.parseClick().omZpc
        customEvent(VisilabsConstants.omEvtGif, properties: properties)
        createSubsJsonRequest(actid: actid, auth: auth, mail: mail)
    }

    private func createSubsJsonRequest(actid: String, auth: String, mail: String, type: String = "subscription_email") {
        var props = [String: String]()
        props[VisilabsConstants.organizationIdKey] = visilabsProfile.organizationId // Om.oid
        props[VisilabsConstants.profileIdKey] = visilabsProfile.profileId // Om.siteId
        props[VisilabsConstants.cookieIdKey] = visilabsUser.cookieId
        props[VisilabsConstants.exvisitorIdKey] = visilabsUser.exVisitorId
        props[VisilabsConstants.type] = type
        props["actionid"] = actid
        props[VisilabsConstants.authentication] = auth
        props[VisilabsConstants.subscribedEmail] = mail
        props[VisilabsConstants.channelKey] = visilabsProfile.channel
        VisilabsRequest.sendSubsJsonRequest(properties: props, headers: [String: String](), timeOutInterval: visilabsProfile.requestTimeoutInterval)
    }
}

public protocol VisilabsInappButtonDelegate: AnyObject {
    func didTapButton(_ notification: VisilabsInAppNotification)
}
