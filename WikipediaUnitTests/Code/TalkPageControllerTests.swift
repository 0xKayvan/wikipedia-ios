
import XCTest
@testable import Wikipedia
@testable import WMF

fileprivate class MockTalkPageFetcher: TalkPageFetcher {
    
    static var name = "Username1"
    static var domain = "en.wikipedia.org"
    var fetchCalled = false
    
    override func fetchTalkPage(urlTitle: String, displayTitle: String, host: String, languageCode: String, revisionID: Int64, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        
        fetchCalled = true
        if let networkTalkPage = TalkPageTestHelpers.networkTalkPage(for: "https://\(MockTalkPageFetcher.domain)/api/rest_v1/page/talk/\(urlTitle)", revisionId: MockArticleRevisionFetcher.revisionId) {
            completion(.success(networkTalkPage))
        } else {
            XCTFail("Expected network talk page from helper")
        }
        
    }
}

fileprivate class MockArticleRevisionFetcher: WMFArticleRevisionFetcher {
    
    static var revisionId: Int64 = 894272715
    
    var resultsDictionary: [AnyHashable : Any] {
        return ["batchcomplete": 1,
                "query" : ["pages": [
                    ["ns": 0,
                     "pageid": 2360669,
                     "revisions": [
                        ["minor": 1,
                         "parentid": 894272641,
                         "revid": MockArticleRevisionFetcher.revisionId,
                         "size": 61252]
                        ],
                     "title": "Benty Grange helmet"
                    ]
                    ]
            ]
        ]
    }
    
    override func fetchLatestRevisions(forArticleURL articleURL: URL!, resultLimit numberOfResults: UInt, endingWithRevision revisionId: NSNumber, failure: WMFErrorHandler!, success: WMFSuccessIdHandler!) -> URLSessionTask? {
        do {
            let revisionQueryResults = try WMFLegacySerializer.models(of: WMFRevisionQueryResults.self, fromArrayForKeyPath: "query.pages", inJSONDictionary: resultsDictionary)
            success(revisionQueryResults)
            return nil
        } catch {
            XCTFail("Failure to create WMFRevisionQueryResults")
        }
        
        return nil
    }
}

class TalkPageControllerTests: XCTestCase {

    var tempDataStore: MWKDataStore!
    var talkPageController: TalkPageController!
    fileprivate var talkPageFetcher: MockTalkPageFetcher!
    fileprivate var articleRevisionFetcher: MockArticleRevisionFetcher!

    override func setUp() {
        super.setUp()
        tempDataStore = MWKDataStore.temporary()
        talkPageFetcher = MockTalkPageFetcher(session: Session.shared, configuration: Configuration.current)
        articleRevisionFetcher = MockArticleRevisionFetcher()
        talkPageController = TalkPageController(talkPageFetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, dataStore: tempDataStore, title: "Username1", host: Configuration.Domain.englishWikipedia, languageCode: "en", titleIncludesPrefix: false, type: .user)
        MockArticleRevisionFetcher.revisionId = 894272715
        
    }

    override func tearDown() {
        tempDataStore.removeFolderAtBasePath()
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail()
            return
        }
        
        for talkPage in firstResults {
            tempDataStore.viewContext.delete(talkPage)
        }
        
        do {
            try tempDataStore.save()
        } catch {
            XCTFail()
        }
        
        
        tempDataStore = nil
        super.tearDown()
    }
    
    func testInitialFetchSavesRecordInDB() {
        
        //confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                //fetch from db again, confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
    }

/* //todo: this fails when run consecutively
    func testFetchSameUserTwiceDoesNotAddMultipleTalkPageRecords() {
        
        //confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                //confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
        
        //same fetch again
        let nextFetchCallback = expectation(description: "Waiting for next fetch callback")
        talkPageController.fetchTalkPage { (result) in
            nextFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                //fetch from db again, confirm count is still 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [nextFetchCallback], timeout: 5)
    }
 */
    
    func testFetchSameUserDifferentLanguageAddsMultipleTalkPageRecords() {
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                //fetch from db again, confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                XCTAssertEqual(results.first, dbTalkPage)
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
        
        //fetch again for ES language
        MockTalkPageFetcher.domain = "es.wikipedia.org"
        talkPageController = TalkPageController(talkPageFetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, dataStore: tempDataStore, title: "Username1", host:"es.wikipedia.org", languageCode: "en", titleIncludesPrefix: false, type: .user)
        
        let nextFetchCallback = expectation(description: "Waiting for next fetch callback")
        talkPageController.fetchTalkPage { (result) in
            nextFetchCallback.fulfill()
            
            switch result {
            case .success:
                
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 2, "Expected two talk pages in DB")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [nextFetchCallback], timeout: 5)
    }
    
    func testFetchDifferentUserSameLanguageAddsMultipleTalkPageRecords() {
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success:
                
                //fetch from db again, confirm count is 1 and matches returned talk page
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 1, "Expected one talk page in DB")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [initialFetchCallback], timeout: 5)
        
        //fetch again for ES language
        MockTalkPageFetcher.name = "Username2"
        talkPageController = TalkPageController(talkPageFetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, dataStore: tempDataStore, title: "Username2", host:Configuration.Domain.englishWikipedia, languageCode: "en", titleIncludesPrefix: false, type: .user)
        
        let nextFetchCallback = expectation(description: "Waiting for next fetch callback")
        talkPageController.fetchTalkPage { (result) in
            nextFetchCallback.fulfill()
            
            switch result {
            case .success:
                
                let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
                
                guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                    XCTFail("Failure fetching initial talk pages")
                    return
                }
                
                XCTAssertEqual(results.count, 2, "Expected two talk pages in DB")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        
        wait(for: [nextFetchCallback], timeout: 5)
    }
    
    func testFetchSameRevisionIdDoesNotCallFetcher() {
        //confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //initial fetch to populate DB
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        var firstDBTalkPage: TalkPage?
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                firstDBTalkPage = dbTalkPage
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                XCTAssertTrue(self.talkPageFetcher.fetchCalled, "Expected fetcher to be called for initial fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
         wait(for: [initialFetchCallback], timeout: 5)
        
        //reset fetchCalled
        talkPageFetcher.fetchCalled = false
        
        //make same fetch again, same revision ID. Confirm fetcher was never called and same talk page is returned
        let secondFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        talkPageController.fetchTalkPage { (result) in
            secondFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                XCTAssertEqual(firstDBTalkPage, dbTalkPage)
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                XCTAssertFalse(self.talkPageFetcher.fetchCalled, "Expected fetcher to not be called for second fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        wait(for: [secondFetchCallback], timeout: 5)
    }
    
/* //todo: this fails when run consecutively
    func testIncrementedRevisionDoesCallFetcher() {
        
        //confirm no talk pages in DB at first
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //initial fetch to populate DB
        let initialFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        var firstDBTalkPage: TalkPage?
        talkPageController.fetchTalkPage { (result) in
            initialFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                firstDBTalkPage = dbTalkPage
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                XCTAssertTrue(self.talkPageFetcher.fetchCalled, "Expected fetcher to be called for initial fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        wait(for: [initialFetchCallback], timeout: 5)
        
        //reset fetchCalled
        talkPageFetcher.fetchCalled = false
        
        MockArticleRevisionFetcher.revisionId += 1
        
        //make same fetch again, same revision ID. Confirm fetcher was never called and same talk page is returned
        let secondFetchCallback = expectation(description: "Waiting for initial fetch callback")
        
        talkPageController.fetchTalkPage { (result) in
            secondFetchCallback.fulfill()
            
            switch result {
            case .success(let dbTalkPage):
                
                XCTAssertEqual(firstDBTalkPage, dbTalkPage)
                XCTAssertEqual(dbTalkPage.revisionId, MockArticleRevisionFetcher.revisionId)
                XCTAssertTrue(self.talkPageFetcher.fetchCalled, "Expected fetcher to be called for second fetch")
                
            case .failure:
                XCTFail("TalkPageController fetchTalkPage failure")
            }
        }
        wait(for: [secondFetchCallback], timeout: 5)
    }
 */
}
