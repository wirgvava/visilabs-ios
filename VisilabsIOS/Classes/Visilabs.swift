import WebKit
import AdSupport

open class Visilabs{
    
    private static var API: Visilabs?
    private static var visilabsReachability : VisilabsReachability?
    
    var organizationID : String
    var siteID : String
    private var loggerURL : String
    private var dataSource : String
    private var realTimeURL : String
    private var channel : String
    private var requestTimeoutInSeconds : Int
    private var restURL : String?
    private var encryptedDataSource : String?
    internal var targetURL : String?
    private var actionURL : String?
    private var geofenceURL : String?
    private var geofenceEnabled : Bool
    private var maxGeofenceCount : Int
    
    private var sendQueue : [String]
    private var timer: Timer?
    private var segmentConnection: NSURLConnection?
    private var failureStatus = 0
    private var cookieIDArchiveKey: String?
    private var exVisitorIDArchiveKey: String?
    private var propertiesArchiveKey: String?
    private var tokenIDArchiveKey: String?
    private var appIDArchiveKey: String?
    private var userAgentArchiveKey: String?
    private var visitData: String?
    private var visitorData: String?
    private var identifierForAdvertising: String?
    private var serialQueue: DispatchQueue?
    private var currentlyShowingNotification: Any?
    private var notificationViewController: UIViewController?
    private var notificationResponseCached = false
    
    private var loggerCookieKey: String?
    private var loggerCookieValue: String?
    private var realTimeCookieKey: String?
    private var realTimeCookieValue: String?
    private var loggerOM3rdCookieValue: String?
    private var realTimeOM3rdCookieValue: String?
    
    private var webView: WKWebView?
    
    var cookieID: String?
    var exVisitorID: String?
    var tokenID: String?
    var appID: String?
    internal var isOnline: Bool//TODO: burada = true demek lazım mı?
    internal var userAgent: String?
    private var loggingEnabled: Bool = true
    private var checkForNotificationsOnLoggerRequest: Bool = true
    private var miniNotificationPresentationTime: Float = 0.0
    private var miniNotificationBackgroundColor: UIColor = .clear
    
    
    //TODO: burada synchronized olacak
    public class func callAPI() -> Visilabs? {
        
        if Visilabs.API == nil{
            print("zort")
        }
        
        return Visilabs.API
    }
    
    //TODO: Buradaki DispatchQueue doğru yaklaşım mı?
    public class func createAPI(organizationID: String, siteID: String, loggerURL: String, dataSource: String, realTimeURL: String, channel: String, requestTimeoutInSeconds: Int = 60, targetURL: String? = nil, actionURL: String? = nil, geofenceURL: String? = nil, geofenceEnabled: Bool = false, maxGeofenceCount: Int = 20, restURL: String? = nil, encryptedDataSource: String? = nil) -> Visilabs? {
        let lockQueue = DispatchQueue(label: "self")
        lockQueue.sync {
            if API == nil {
                API = Visilabs(organizationID: organizationID, siteID: siteID, loggerURL: loggerURL, dataSource: dataSource, realTimeURL: realTimeURL, channel: channel, requestTimeoutInSeconds: requestTimeoutInSeconds, restURL: restURL, encryptedDataSource: encryptedDataSource, targetURL: targetURL, actionURL: actionURL, geofenceURL: geofenceURL, geofenceEnabled: geofenceEnabled, maxGeofenceCount: maxGeofenceCount)
            }
        }
        return API
    }

    private init(organizationID: String, siteID: String, loggerURL: String, dataSource: String, realTimeURL: String, channel: String, requestTimeoutInSeconds: Int, restURL: String?, encryptedDataSource: String?, targetURL: String?, actionURL: String?, geofenceURL: String?, geofenceEnabled: Bool, maxGeofenceCount: Int) {
        self.organizationID = organizationID
        self.siteID = siteID
        self.loggerURL = loggerURL
        self.dataSource = dataSource
        self.realTimeURL = realTimeURL
        self.channel = channel
        self.requestTimeoutInSeconds = requestTimeoutInSeconds
        self.restURL = restURL
        self.encryptedDataSource = encryptedDataSource
        self.targetURL = targetURL
        self.actionURL = actionURL
        self.geofenceURL = geofenceURL
        self.geofenceEnabled = geofenceEnabled
        self.maxGeofenceCount = maxGeofenceCount
        self.sendQueue = [String]()
        self.isOnline = true //TODO: burada true'ya mı eşitlemek lazım
    }
    
    // MARK: Persistence

    func filePath(forData data: String?) -> String? {
        let filename = "\(data ?? "")"
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last ?? "").appendingPathComponent(filename).absoluteString
    }
    
    func cookieIDFilePath() -> String? {
        return filePath(forData: cookieIDArchiveKey)
    }

    func exVisitorIDFilePath() -> String? {
        return filePath(forData: exVisitorIDArchiveKey)
    }

    func tokenIDFilePath() -> String? {
        return filePath(forData: tokenIDArchiveKey)
    }

    func appIDFilePath() -> String? {
        return filePath(forData: appIDArchiveKey)
    }

    func userAgentFilePath() -> String? {
        return filePath(forData: userAgentArchiveKey)
    }

    func propertiesFilePath() -> String? {
        return filePath(forData: propertiesArchiveKey)
    }
    
    
    /* TODO:
    
    func dispatch_once_on_main_thread(predicate: UnsafeMutableRawPointer?, block: () -> ()) {
        if Thread.isMainThread {
            block
        } else {
            if DISPATCH_EXPECT(IntegerLiteralConvertible(predicate ?? 0) == 0, false) {
                DispatchQueue.main.sync(execute: {
                    block
                })
            }
        }
    }

    func computeWebViewUserAgent() {
        webView = WKWebView(frame: CGRect.zero)
        webView?.loadHTMLString("<html></html>", baseURL: nil)
        weak var weakSelf = self
        dispatch_once_on_main_thread(&computeWebViewUserAgentOnceToken, {
            let strongSelf = weakSelf
            strongSelf.webView?.evaluateJavaScript("navigator.userAgent", completionHandler: { userAgent, error in
                strongSelf.userAgent = userAgent
                strongSelf.webView = nil
                if !NSKeyedArchiver.archiveRootObject(strongSelf.userAgent, toFile: strongSelf.userAgentFilePath()) {
                    DLog("Visilabs: WARNING - Unable to archive userAgent!!!")
                }
            })
        })
    }
    */
    
    //TODO: BUNU DENE
    func computeWebViewUserAgent2() {
        DispatchQueue.main.async {
            var webView : WKWebView? = WKWebView(frame: CGRect.zero)
            webView?.loadHTMLString("<html></html>", baseURL: nil)
            webView?.evaluateJavaScript("navigator.userAgent", completionHandler: { userAgent, error in
                if let uA = userAgent{
                    if type(of: uA) == String.self{
                        self.userAgent = String(describing: uA)
                        if !NSKeyedArchiver.archiveRootObject(self.userAgent
                            //, toFile: self.userAgentFilePath()
                            , toFile: ""
                            ) {
                            print("Visilabs: WARNING - Unable to archive userAgent!!!")
                        }
                    }
                }
            })
        }
        
    }
    
    // MARK: In-App Notification

    //TODO:
    private func trackNotificationClick(visilabsNotification: VisilabsNotification){
    }
    
    //TODO:
    private func checkForNotificationsResponse(withCompletion completion: @escaping (_ notifications: [AnyHashable]?) -> Void, pageName: String?, properties: inout [AnyHashable : Any]) {
    }
    
    //TODO: class func vs static farkı nedir?
    private class func topPresentedViewController() -> UIViewController?{
        return nil
    }
    
    //TODO: viewController is UIAlertController ne için gerekli bak
    private class func canPresentFromViewController(viewController: UIViewController) -> Bool{
        // This fixes the NSInternalInconsistencyException caused when we try present a
        // survey on a viewcontroller that is itself being presented.
        if viewController.isBeingPresented || viewController.isBeingDismissed || viewController is UIAlertController {
            return false
        }
        return true
    }
    
    //TODO:
    private func showNotification(pageName: String?) {
    }
    
    //TODO:
    private func showNotification(_ pageName: String?, properties: [AnyHashable : Any]?) {
    }

    //TODO:
    private func showNotification(withObject notification: VisilabsNotification?) {
    }

    //TODO:
    private func showMiniNotification(withObject notification: VisilabsNotification?) -> Bool {
        return false
    }

    //TODO:
    private func showFullNotification(withObject notification: VisilabsNotification?) -> Bool {
        return false
    }

    //TODO:
    private func notificationController(controller: VisilabsNotificationViewController?, wasDismissedWithStatus status: Bool) {
    }
    
    
    //TODO:
    private func setupLifeCycyleListeners(){
        //applicationWillTerminate
        //applicationWillEnterForeground
        //applicationDidBecomeActive
        //applicationDidEnterBackground
    }
    
    
    //TODO:persistence metodlar
    /*
     filePathForData
     cookieIDFilePath
     exVisitorIDFilePath
     tokenIDFilePath
     appIDFilePath
     userAgentFilePath
     propertiesFilePath
     archive
     archiveProperties
     unarchive
     unarchiveFromFile
     unarchiveProperties
     */
    
    private func getIDFA() -> String? {
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            let IDFA = ASIdentifierManager.shared().advertisingIdentifier
            return IDFA.uuidString
        }
        return ""
    }
    
    //TODO: description'a gerek yok.
    
    // MARK: Public Methods
    
    //TODO:bunu kontrol et: objective-c'de pointer'lı bir şeyler kullanıyorduk
    public func urlEncode(_ prior: String) -> String {
        return prior.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
    
    //TODO
    func buildTargetRequest(zoneID: String, productCode: String, properties: [String : Any] = [:], filters: [VisilabsTargetFilter] = []) -> VisilabsTargetRequest? {
        if Visilabs.API == nil {
            //TODO: ne yapacağına karar ver.
            //Error is not handled because the enclosing function is not declared 'throws'
            //throw (NSException(name: NSExceptionName("Visilabs Not Ready"), reason: "Visilabs failed to initialize", userInfo: [:]) as! Error)
            return nil
        }
        return VisilabsTargetRequest(zoneID: zoneID, productCode: productCode, properties: properties, filters: filters)
    }

    //TODO
    func buildGeofenceRequest(action: String, actionID: String, latitude: Double, longitude: Double, geofenceID: String, isDwell: Bool, isEnter: Bool) -> VisilabsGeofenceRequest? {
        if Visilabs.API == nil {
            //TODO: ne yapacağına karar ver.
            //Error is not handled because the enclosing function is not declared 'throws'
            //throw (NSException(name: NSExceptionName("Visilabs Not Ready"), reason: "Visilabs failed to initialize", userInfo: [:]) as! Error)
            return nil
        }
        return VisilabsGeofenceRequest(action: action, actionID: actionID, lastKnownLatitude: latitude, lastKnownLongitude: longitude, geofenceID: geofenceID, isDwell: isDwell, isEnter: isEnter)
    }
    
    
    //TODO:
    public func customEvent(_ pageName: String, properties: [String:String]){
        
    }
    
    public func login(exVisitorID: String, properties: [String:String] = [String:String]()){
        if exVisitorID.isEmptyOrWhitespace(){
            print("Visilabs: WARNING - attempted to use empty identity. Ignoring.")
            return
        }else {
            if self.exVisitorID != nil && !(self.exVisitorID == exVisitorID) {
                setCookieID()
            }
            var props = properties
            props[VisilabsConfig.EXVISITORID_KEY] = exVisitorID
            props["Login"] = exVisitorID
            props["OM.b_login"] = "Login"
            customEvent("LoginPage", properties: props)
        }
    }
    
    public func signUp(exVisitorID: String, properties: [String:String] = [String:String]()){
        if exVisitorID.isEmptyOrWhitespace(){
            print("Visilabs: WARNING - attempted to use empty identity. Ignoring.")
            return
        }else {
            if self.exVisitorID != nil && !(self.exVisitorID == exVisitorID) {
                setCookieID()
            }
            var props = properties
            props[VisilabsConfig.EXVISITORID_KEY] = exVisitorID
            props["SignUp"] = exVisitorID
            props["OM.b_sgnp"] = "SignUp"
            customEvent("SignUpPage", properties: props)
        }
    }
    
    //TODO:
    public func getPushURL(source: String, campaign: String, medium: String, content: String) -> String?{
        return nil
    }
    
    private func setCookieID() {
        cookieID = UUID().uuidString
        //TODO:
        if !NSKeyedArchiver.archiveRootObject(cookieID, toFile: "") {
            //TODO:
            //DLog("Visilabs: WARNING - Unable to archive identity!!!")
        }
    }

    
    public func setExVisitorIDToNull(){
        self.exVisitorID = nil
    }
}

