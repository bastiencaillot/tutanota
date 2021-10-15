//
//  UserPreferenceFacade.swift
//  tutanota
//
//  Created by Tutao GmbH on 10/15/21.
//  Copyright © 2021 Tutao GmbH. All rights reserved.
//

import Foundation

fileprivate let SSE_INFO_KEY = "sseInfo"
fileprivate let ALARMS_KEY = "repeatingAlarmNotification"
fileprivate let LAST_PROCESSED_NOTIFICAION_ID_KEY = "lastProcessedNotificationId"
fileprivate let LAST_MISSED_NOTIFICATION_CHECK_TIME = "lastMissedNotificationCheckTime"

@objc
class UserPreferenceFacade : NSObject {
  override init() {
  }
  
  @objc
  var sseInfo: TUTSseInfo? {
    get {
      let dict = UserDefaults.standard.dictionary(forKey: SSE_INFO_KEY)
      return dict.map { TUTSseInfo(dict: $0) }
    }
  }
  
  @objc
  func store(pushIdentifier: String, userId: String, sseOrigin: String) {
    if let sseInfo = self.sseInfo {
        sseInfo.pushIdentifier = pushIdentifier
        sseInfo.sseOrigin = sseOrigin
        var userIds = sseInfo.userIds
        if !userId.contains(userId) {
          userIds.append(userId)
        }
        sseInfo.userIds = userIds
      self.put(sseInfo: sseInfo)
    } else {
      let sseInfo = TUTSseInfo()
      sseInfo.pushIdentifier = pushIdentifier
      sseInfo.userIds = [userId]
      sseInfo.sseOrigin = sseOrigin
      self.put(sseInfo: sseInfo)
    }
  }
  
  @objc
  func store(alarms: [TUTAlarmNotification]) {
    let notificationsJson = alarms.map { $0.jsonDict }
    let jsonData = try! JSONSerialization.data(withJSONObject: notificationsJson, options: [])
    UserDefaults.standard.setValue(jsonData, forKey: ALARMS_KEY)
  }
  
  @objc
  var alarms: [TUTAlarmNotification] {
    get {
      let defaults = UserDefaults.standard
      let notificationsJsonData = defaults.object(forKey: ALARMS_KEY)
      if let notificationsJsonData = notificationsJsonData {
        let notificationJsonArray = try! JSONSerialization.jsonObject(with: notificationsJsonData as! Data, options: []) as! Array<Dictionary<String, Any>>
        return notificationJsonArray.map { TUTAlarmNotification.fromJSON($0) }
      } else {
        return []
      }
    }
  }
  
  @objc
  func removeUser(_ userId: String) {
    let sseInfo = self.sseInfo;
    guard let sseInfo = sseInfo else {
      TUTSLog("Removing userId but there's no SSEInfo stored")
      return
    }
    var userIds = sseInfo.userIds
    if let index = userIds.firstIndex(of: userId) {
      userIds.remove(at: index)
    }
    sseInfo.userIds = userIds
    self.put(sseInfo: sseInfo)
  }
  
  @objc
  var lastProcessedNotificationId: String? {
    get {
      return UserDefaults.standard.object(forKey: LAST_PROCESSED_NOTIFICAION_ID_KEY) as! String?
    }
    set {
      return UserDefaults.standard.setValue(newValue, forKey: LAST_PROCESSED_NOTIFICAION_ID_KEY)
    }
  }
  
  @objc
  var lastMissedNotificationCheckTime: Date? {
    get {
      return UserDefaults.standard.object(forKey: LAST_MISSED_NOTIFICATION_CHECK_TIME) as! Date?
    }
    set {
      return UserDefaults.standard.setValue(newValue, forKey: LAST_MISSED_NOTIFICATION_CHECK_TIME)
    }
  }
  
  @objc
  func clear() {
    TUTSLog("UserPreference clear")
    let sseInfo = self.sseInfo
    if let sseInfo = sseInfo {
      sseInfo.userIds = []
      self.put(sseInfo: sseInfo)
      self.lastMissedNotificationCheckTime = nil
      self.store(alarms: [])
    }
  }
  
  private func put(sseInfo: TUTSseInfo) {
    UserDefaults.standard.setValue(sseInfo.toDict, forKey: SSE_INFO_KEY)
  }
}
