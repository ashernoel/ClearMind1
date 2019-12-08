// swiftlint:disable all
import Amplify
import Foundation

public struct Recording: Model {
  public let id: String
  public var content: String?
  
  public init(id: String = UUID().uuidString,
      content: String? = nil) {
      self.id = id
      self.content = content
  }
}