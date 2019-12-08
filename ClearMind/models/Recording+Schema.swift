// swiftlint:disable all
import Amplify
import Foundation

extension Recording {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let recording = Recording.keys
    
    model.pluralName = "Recordings"
    
    model.fields(
      .id(),
      .field(recording.content, is: .optional, ofType: .string)
    )
    }
}