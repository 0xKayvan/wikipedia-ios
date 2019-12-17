
import Foundation
import CoreData


extension NewCacheGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewCacheGroup> {
        return NSFetchRequest<NewCacheGroup>(entityName: "NewCacheGroup")
    }

    @NSManaged public var key: String?
    @NSManaged public var cacheItems: NSSet?

}

// MARK: Generated accessors for cacheItems
extension NewCacheGroup {

    @objc(addCacheItemsObject:)
    @NSManaged public func addToCacheItems(_ value: NewCacheItem)

    @objc(removeCacheItemsObject:)
    @NSManaged public func removeFromCacheItems(_ value: NewCacheItem)

    @objc(addCacheItems:)
    @NSManaged public func addToCacheItems(_ values: NSSet)

    @objc(removeCacheItems:)
    @NSManaged public func removeFromCacheItems(_ values: NSSet)

}
