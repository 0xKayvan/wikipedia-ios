import Foundation

extension ReadingList {
    func update(with remoteList: APIReadingList) {
        self.readingListID = NSNumber(value: remoteList.id)
        self.name = remoteList.name == CommonStrings.readingListsDefaultListTitle ? "\(remoteList.name)_[user created]" : remoteList.name
        self.readingListDescription = remoteList.description
        if let createdDate = DateFormatter.wmf_iso8601().date(from: remoteList.created) {
            self.createdDate = createdDate as NSDate
        }
        if let updatedDate = DateFormatter.wmf_iso8601().date(from: remoteList.updated) {
            self.updatedDate = updatedDate as NSDate
        }
        if remoteList.isDefault && !isDefault {
            isDefault = true
        }
        errorCode = nil
        isUpdatedLocally = false
    }
}
