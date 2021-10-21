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

class UserPreferenceFacade {
  var sseInfo: TUTSseInfo? {
    get {
      let dict = UserDefaults.standard.dictionary(forKey: SSE_INFO_KEY)
      return dict.map { TUTSseInfo(dict: $0) }
    }
  }
  
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
  
  func store(alarms: [EncryptedAlarmNotification]) {
    let jsonData = try! JSONEncoder().encode(alarms)
    UserDefaults.standard.setValue(jsonData, forKey: ALARMS_KEY)
  }
  
  var alarms: [EncryptedAlarmNotification] {
    get {
      let defaults = UserDefaults.standard
      let notificationsJsonData = defaults.object(forKey: ALARMS_KEY)
      if let notificationsJsonData = notificationsJsonData {
        return try! JSONDecoder().decode(Array<EncryptedAlarmNotification>.self, from: notificationsJsonData as! Data)
      } else {
        return []
      }
    }
  }
    
  func removeUser(_ userId: String) {
    guard let sseInfo = self.sseInfo else {
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
  
  var lastProcessedNotificationId: String? {
    get {
      return UserDefaults.standard.object(forKey: LAST_PROCESSED_NOTIFICAION_ID_KEY) as! String?
    }
    set {
      return UserDefaults.standard.setValue(newValue, forKey: LAST_PROCESSED_NOTIFICAION_ID_KEY)
    }
  }
  
  var lastMissedNotificationCheckTime: Date? {
    get {
      return UserDefaults.standard.object(forKey: LAST_MISSED_NOTIFICATION_CHECK_TIME) as! Date?
    }
    set {
      return UserDefaults.standard.setValue(newValue, forKey: LAST_MISSED_NOTIFICATION_CHECK_TIME)
    }
  }
  
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
    UserDefaults.standard.setValue(sseInfo.toDict(), forKey: SSE_INFO_KEY)
  }
}
