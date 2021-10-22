//
//  ViewController.swift
//  tutanota
//
//  Created by Tutao GmbH on 10/18/21.
//  Copyright © 2021 Tutao GmbH. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications

class ViewController : UIViewController, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate {
  private let crypto: TUTCrypto
  private var fileFacade: FileFacade!
  private let contactsSource: ContactsSource
  private let themeManager: ThemeManager
  private let keychainManager: KeychainManager
  private let userPreferences: UserPreferenceFacade
  private let alarmManager: AlarmManager
  
  private var webView: WKWebView!
  
  private var requestId = 0
  private var requests = [String : ((Any?) -> Void)]()
  private var keyboardSize = 0
  private var webviewInitialized = false
  private var requestsBeforeInit = [() -> Void]()
  private var isDarkTheme = false
  
  init(
    crypto: TUTCrypto,
    contactsSource: ContactsSource,
    themeManager: ThemeManager,
    keychainManager: KeychainManager,
    userPreferences: UserPreferenceFacade,
    alarmManager: AlarmManager
    ) {
      self.crypto = crypto
      self.contactsSource = contactsSource
      self.themeManager = themeManager
      self.keychainManager = keychainManager
      self.userPreferences = userPreferences
      self.alarmManager = alarmManager
      self.fileFacade = nil
      
    super.init(nibName: nil, bundle: nil)
    
    self.fileFacade = FileFacade(
        chooser: TUTFileChooser(viewController: self),
        viewer: TUTFileViewer(viewController: self)
    )
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not codeable")
  }
  
  override func loadView() {
    super.loadView()
    WebviewHacks.hideAccessoryBar()
    WebviewHacks.keyboardDisplayDoesNotRequireUserAction()
    
    let webViewConfig = WKWebViewConfiguration()
    self.webView = WKWebView(frame: CGRect.zero, configuration: webViewConfig)
    webViewConfig.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    webView.navigationDelegate = self
    webView.scrollView.bounces = false
    webView.scrollView.isScrollEnabled = false
    webView.scrollView.delegate = self
    webView.isOpaque = false
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    
    
    webViewConfig.userContentController.add(self, name: "nativeApp")
    
    NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardSizeChange), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
  }
  
  @objc
  private func onKeyboardDidShow(note: Notification) {
    let rect = note.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
    self.onAnyKeyboardSizeChange(newHeight: rect.size.height)
    
  }
  
  @objc
  private func onKeyboardWillHide() {
    self.onAnyKeyboardSizeChange(newHeight: 0)
  }
  
  @objc
  private func onKeyboardSizeChange(note: Notification) {
    let rect = note.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
    let newHeight = rect.size.height
    if self.keyboardSize != 0 && self.keyboardSize != Int(newHeight) {
      self.onAnyKeyboardSizeChange(newHeight: newHeight)
    }
  }
  
  private func sendRequest(method: String, args: [Any], completion: ((Any?) -> Void)?) {
    if !self.webviewInitialized {
      let callback = { self.sendRequest(method: method, args: args, completion: completion) }
      self.requestsBeforeInit.append(callback)
      return
    }
    
    self.requestId = self.requestId + 1
    let requestId = "app\(self.requestId)"
    if let completion = completion {
      self.requests[requestId] = completion
    }
    let json: [String : Any] = [
      "id": requestId,
      "type": method,
      "args": args
    ]
    self.postMessage(message: json)
  }
  
  private func onAnyKeyboardSizeChange(newHeight: CGFloat) {
    self.keyboardSize = Int(newHeight)
    self.sendRequest(method: "keyboardSizeChanged", args: [self.keyboardSize], completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(webView)
    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
    webView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    
    let theme = self.themeManager.currentThemeWithFallback
    self.applyTheme(theme)
    
    if self.alarmManager.hasNotificationTTLExpired() {
      self.alarmManager.resetStoredState()
    } else {
      self.alarmManager.fetchMissedNotifications { err in
        if let err = err {
          TUTSLog("Failed to fetch/process missed notification \(err)")
        } else {
          TUTSLog("Successfully processed missed notification")
        }
      }
      self.alarmManager.rescheduleAlarms()
    }
    
    self.loadMainPage(params: [:])
  }
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    let jsonString = message.body as! String
    let json = try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as! [String : Any]
    let type = json["type"] as! String
    let requestId = json["id"] as! String
    
    switch type {
    case "response":
      let value = json["value"]
      self.handleResponse(id: requestId, value: value)
    case "errorResponse":
      TUTSLog("Request failed: \(type) \(requestId)")
      // We don't "reject" requests right now
      self.requests.removeValue(forKey: requestId)
    default:
      let arguments = json["args"] as! [Any]
      self.handleRequest(type: type, requestId: requestId, args: arguments)
    }
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    // We need to implement this bridging from native because we don't know if we are an iOS app
    // before the init event.
    // From JS we expect window.nativeApp.invoke to be there
    let js =
      """
      window.nativeApp = {
        invoke: (message) => window.webkit.messageHandlers.nativeApp.postMessage(message)
      }
      """
    self.webView.evaluateJavaScript(js, completionHandler: nil)
  }
  
  private func handleRequest(type: String, requestId: String, args: [Any]) {
    func sendResponseBlock(value: Any?, error: Error?) {
      if let error = error {
        self.sendErrorResponse(requestId: requestId, err: error)
      } else {
        sendResponse(requestId: requestId, value: value!)
      }
    }
    
    func sendEncodableResponseBlock<T: Encodable>(value: T?, error: Error?) {
      let json = value.map { v in self.encodeToDict(value: v) }
      sendResponseBlock(value: json, error: error)
    }
    
    switch type {
    case "init":
      self.webviewInitialized = true
      sendResponseBlock(value: "ios", error: nil)
      for callback in requestsBeforeInit {
        callback()
      }
      requestsBeforeInit.removeAll()
      if let sseInfo = userPreferences.sseInfo, sseInfo.userIds.isEmpty {
        TUTSLog("Sending alarm invalidation")
        self.sendRequest(method: "invalidateAlarms", args: [], completion: nil)
      }
    case "rsaEncrypt":
      self.crypto.rsaEncrypt(
        withPublicKey: args[0] as! NSObject,
        base64Data: args[1] as! String,
        base64Seed: args[2] as! String,
        completion: sendResponseBlock
      )
    case "rsaDecrypt":
      self.crypto.rsaDecrypt(
        withPrivateKey: args[0] as! NSObject,
        base64Data: args[1] as! String,
        completion: sendResponseBlock
      )
    case "reload":
      self.webviewInitialized = false
      DispatchQueue.main.async {
        self.loadMainPage(params: args[0] as! [String : String])
      }
    case "generateRsakey":
      self.crypto.generateRsaKey(withSeed: args[0] as! String, completion: sendResponseBlock)
    case "openFileChooser":
      let rectDict = args[0] as! [String : Int]
      let rect = CGRect(
        x: rectDict["x"]!,
        y: rectDict["y"]!,
        width: rectDict["width"]!,
        height: rectDict["height"]!
      )
      self.fileFacade.openFileChooser(anchor: rect, completion: sendResponseBlock)
    case "getName":
      self.fileFacade.getName(path: args[0] as! String, completion: sendResponseBlock)
    case "changeLanguage":
      sendResponseBlock(value: NSNull(), error: nil)
    case "getSize":
      self.fileFacade.getSize(path: args[0] as! String, completion: sendResponseBlock)
    case "getMimeType":
      self.fileFacade.getMimeType(path: args[0] as! String, completion: sendResponseBlock)
    case "aesEncryptFile":
      self.crypto.aesEncryptFile(withKey: args[0] as! String, atPath: args[1] as! String, completion: sendResponseBlock)
    case "aesDecryptFile":
      self.crypto.aesDecryptFile(withKey: args[0] as! String, atPath: args[1] as! String, completion: sendResponseBlock)
    case "upload":
      self.fileFacade.uploadFile(
        atPath: args[0] as! String,
        toUrl: args[1] as! String,
        withHeaders: args[2] as! [String : String],
        completion: sendEncodableResponseBlock
      )
    case "deleteFile":
      self.fileFacade.deleteFile(path: args[0] as! String) { _ in
        sendResponseBlock(value: NSNull(), error: nil)
      }
    case "clearFileData":
      self.fileFacade.clearFileData { error in
        if let error = error {
          sendResponseBlock(value: nil, error: error)
        } else {
          sendResponseBlock(value: NSNull(), error: nil)
        }
      }
    case "download":
      self.fileFacade.downloadFile(
        fromUrl: args[0] as! String,
        forName: args[1] as! String,
        withHeaders: args[2] as! [String : String],
        completion: sendEncodableResponseBlock
      )
    case "open":
      self.fileFacade.openFile(path: args[0] as! String) { error in
        if let error = error {
          self.sendErrorResponse(requestId: requestId, err: error)
        } else {
          self.sendResponse(requestId: requestId, value: NSNull())
        }
      }
    case "getPushIdentifier":
      self.appDelegate.registerForPushNotifications(callback: sendResponseBlock)
    case "storePushIdentifierLocally":
      self.userPreferences.store(
        pushIdentifier: args[0] as! String,
        userId: args[1] as! String,
        sseOrigin: args[2] as! String
      )
      let keyData = Data(base64Encoded: args[4] as! String)!
      do {
        try self.keychainManager.storeKey(keyData, withId: args[3] as! String)
        self.sendResponse(requestId: requestId, value: NSNull())
      } catch {
        self.sendErrorResponse(requestId: requestId, err: error)
      }
    case "findSuggestions":
      self.contactsSource.search(
        query: args[0] as! String,
        completion: sendEncodableResponseBlock
      )
    case "closePushNotifications":
      UIApplication.shared.applicationIconBadgeNumber = 0
      sendResponseBlock(value: NSNull(), error: nil)
    case "openLink":
      UIApplication.shared.open(
        URL(string: args[0] as! String)!,
        options: [:]) { success in
        sendResponseBlock(value: success, error: nil)
      }
    case "saveBlob":
      let fileDataB64 = args[1] as! String
      let fileData = Data(base64Encoded: fileDataB64)!
      self.fileFacade.openFile(name: args[0] as! String, data: fileData) { err in
        if let error = err {
          self.sendErrorResponse(requestId: requestId, err: error)
        } else {
          self.sendResponse(requestId: requestId, value: NSNull())
        }
      }
    case "getDeviceLog":
      do {
        let logfilepath = try self.getLogfile()
        sendResponseBlock(value: logfilepath, error: nil)
      } catch {
        sendResponseBlock(value: nil, error: error)
        return
      }
    case "scheduleAlarms":
      let alarmsJson = args[0] as! [[String : Any]]
      let alarmsData = try! JSONSerialization.data(withJSONObject: alarmsJson, options: [])
      let alarms = try! JSONDecoder().decode(Array<EncryptedAlarmNotification>.self, from: alarmsData)
      self.alarmManager.processNewAlarms(alarms) { error in
        if let error = error {
          sendResponseBlock(value: nil, error: error)
        } else {
          sendResponseBlock(value: NSNull(), error: nil)
        }
      }
    case "getSelectedTheme":
      sendResponseBlock(value: self.themeManager.selectedThemeId, error: nil)
    case "setSelectedTheme":
      let themeId = args[0] as! String
      self.themeManager.selectedThemeId = themeId
      self.applyTheme(self.themeManager.currentThemeWithFallback)
      sendResponseBlock(value: NSNull(), error: nil)
    case "getThemes":
      sendResponseBlock(value: self.themeManager.themes, error: nil)
    case "setThemes":
      let themes = args[0] as! [Theme]
      self.themeManager.themes = themes
      self.applyTheme(self.themeManager.currentThemeWithFallback)
      sendResponseBlock(value: NSNull(), error: nil)
    default:
      let message = "Unknown comand: \(type)"
      TUTSLog(message)
      let error = NSError(domain: "tutanota", code: 5, userInfo: ["message": message])
      sendResponseBlock(value: nil, error: error)
    }
  }
  
  /// - Returns path to the generated logfile
  private func getLogfile() throws -> String {
    let entries = TUTLogger.sharedInstance().entries()
    let directory = try TUTFileUtil.getDecryptedFolder()
    let directoryUrl = URL(fileURLWithPath: directory)
    let fileName = "\(Date().timeIntervalSince1970)_device_tutanota_log"
    let fileUrl = directoryUrl.appendingPathComponent(fileName, isDirectory: false)
    let stringContent = entries.joined(separator: "\n")
    let bytes = stringContent.data(using: .utf8)!
    try bytes.write(to: fileUrl, options: .atomic)
    return fileUrl.path
  }
  
  private func sendResponse(requestId: String, value: Any) {
    let response = [
      "id": requestId,
      "type": "response",
      "value": value
    ]
    self.postMessage(message: response)
  }
  
  private func sendErrorResponse(requestId: String, err: Error) {
    let nsError = err as NSError
    let userInfo = nsError.userInfo
    var newDict = [String : String]()
    for (key, value) in userInfo {
      newDict[key] = String(describing: value)
    }
    let message = self.dictToJson(dictionary: newDict)
    
    let errorDict = [
      "name": nsError.domain,
      "message": "code \(nsError.code) message: \(message)"
    ]
    self.postMessage(message: [
      "id": requestId,
      "type": "requestError",
      "error": errorDict
    ])
  }
  
  private func postMessage(message: [String : Any]) {
    let jsonData = try! JSONSerialization.data(withJSONObject: message, options: [])
    DispatchQueue.main.async {
      let base64 = jsonData.base64EncodedString()
      let js = "tutao.nativeApp.handleMessageFromNative('\(base64)')"
      self.webView.evaluateJavaScript(js, completionHandler: nil)
    }
  }
  
  private func handleResponse(id: String, value: Any?) {
    if let request = self.requests[id] {
      self.requests.removeValue(forKey: id)
      request(value)
    }
  }
  
  private func loadMainPage(params: [String:String]) {
    let fileUrl = self.appUrl()
    let folderUrl = (fileUrl as NSURL).deletingLastPathComponent!
    
    var mutableParams = params
    if let theme = self.themeManager.currentTheme {
      let encodedTheme = self.dictToJson(dictionary: theme)
      mutableParams["theme"] = encodedTheme
    }
    let queryParams = NSURLQueryItem.from(dict: mutableParams)
    var components = URLComponents.init(url: fileUrl, resolvingAgainstBaseURL: false)!
    components.queryItems = queryParams
    
    let url = components.url!
    webView.loadFileURL(url, allowingReadAccessTo: folderUrl)
  }
  
  private func dictToJson(dictionary: [String : Any]) -> String {
    let data = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
    return String(data: data, encoding: .utf8)!
  }
  
  private func appUrl() -> URL {
    let env = ProcessInfo.processInfo.environment
    
    let pagePath: String
    if let envPath = env["TUT_PAGE_PATH"] {
      pagePath = envPath
    } else {
      pagePath = Bundle.main.infoDictionary!["TutanotaApplicationPath"] as! String
    }
    let path = Bundle.main.path(forResource: pagePath + "index-app", ofType: "html")
    if path == nil {
      return Bundle.main.resourceURL!
    } else {
      return NSURL.fileURL(withPath: path!)
    }
  }
  
  private func applyTheme(_ theme: [String : String]) {
    let contentBgString = theme["content_bg"]!
    let contentBg = UIColor(hex: contentBgString)!
    self.isDarkTheme = !contentBg.isLight()
    self.view.backgroundColor = contentBg
    self.setNeedsStatusBarAppearanceUpdate()
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // disable scrolling of the web view to avoid that the keyboard moves the body out of the screen
    scrollView.contentOffset = CGPoint.zero
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    if self.isDarkTheme {
      return .lightContent
    } else {
      if #available(iOS 13, *) {
        return .darkContent
      } else {
        return .default
      }
    }
  }
  
  private var appDelegate: AppDelegate {
    get {
      UIApplication.shared.delegate as! AppDelegate
    }
  }
  
  private func encodeToDict<T: Encodable>(value: T) -> Any {
    // This is not very efficient but hopefully we only need it temporarily
    let data = try! JSONEncoder().encode(value)
    return try! JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }
}
