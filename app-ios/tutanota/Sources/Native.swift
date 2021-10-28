import Foundation

struct TutanotaError : Codable {
  let name: String
  let message: String
}

enum RequestType: String {
  case request = "request"
  case response = "response"
  case requestError = "requestError"
}

struct RawMessage : Codable {
  let id: String
  let type: String
  let value: NSDictionary
  let error: TutanotaError?
}

public struct RequestInfo {
  let request: Any.Type
  let response: Any.Type
  
  public init(_ request: Any.Type, _ response: Any.Type ) {
    self.request = request
    self.response = response
  }
}



class NativeQueue {
  let requestTypes: [String : RequestInfo] = [
    "init": RequestInfo(Void.self, String.self),
    "test": RequestInfo([String].self, Void.self),
  ]
  
  func sendRequest(id: String, args: [Codable]) {
    
  }
  
  func setHandlers() {
    
  }
  
  private func sendMessage() {
    
  }
}
