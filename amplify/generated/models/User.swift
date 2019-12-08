// swiftlint:disable all
import Amplify
import Foundation

public struct User: Model {
  public let id: String
  public var username: String
  public var firstName: String?
  public var lastName: String?
  public var image: String?
  
  public init(id: String = UUID().uuidString,
      username: String,
      firstName: String? = nil,
      lastName: String? = nil,
      image: String? = nil) {
      self.id = id
      self.username = username
      self.firstName = firstName
      self.lastName = lastName
      self.image = image
  }
}