import UIKit
import XCTest
import Nocilla

class WMFImageControllerTests: XCTestCase {
    var imageController: ImageController!
    
    override func setUp() {
        super.setUp()
        imageController = ImageController.temporaryController()
        imageController.deleteTemporaryCache()
    }
    
    override func tearDown() {
        super.tearDown()
        // might have been set to nil in one of the tests. delcared as implicitly unwrapped for convenience
        imageController?.deleteTemporaryCache()
        LSNocilla.sharedInstance().stop()
    }
    
    // MARK: - Simple fetching
    
    func testReceivingDataResponseResolves() {
        let testURL = URL(string: "https://upload.wikimedia.org/foo@\(Int(UIScreen.main.scale))x.png")!
        let testImage = #imageLiteral(resourceName: "wikipedia-wordmark")
        let stubbedData = UIImagePNGRepresentation(testImage)
        
        LSNocilla.sharedInstance().start()
        _ = stubRequest("GET", testURL.absoluteString as LSMatcheable!).andReturnRawResponse(stubbedData)
        
        let expectation = self.expectation(description: "wait for image download")
        
        let failure = { (error: Error) in
            XCTFail()
            expectation.fulfill()
        }
        
        let success = { (imgDownload: ImageDownload) in
            XCTAssertNotNil(imgDownload.image);
            expectation.fulfill()
        }
        
        self.imageController.fetchImage(withURL: testURL, failure:failure, success: success)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }
    
    
    func testReceivingErrorResponseRejects() {
        let testURL = URL(string: "https://upload.wikimedia.org/foo")!
        let stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        
        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString as LSMatcheable!).andFailWithError(stubbedError)
        
        let expectation = self.expectation(description: "wait for image download");
        
        let failure = { (error: Error) in
            let error = error as NSError
            // ErrorType <-> NSError conversions lose userInfo? https://forums.developer.apple.com/thread/4809
            // let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as! NSURL
            // XCTAssertEqual(failingURL, testURL)
            XCTAssertEqual(error.code, stubbedError.code)
            XCTAssertEqual(error.domain, stubbedError.domain)
            expectation.fulfill()
        }
        
        let success = { (imgDownload: ImageDownload) in
            XCTFail()
            expectation.fulfill()
        }
        
        self.imageController.fetchImage(withURL:testURL, failure:failure, success: success)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }
    
    func testCancellationDoesNotAffectRetry() {
        let testImage = #imageLiteral(resourceName: "wikipedia-wordmark")
        let stubbedData = UIImagePNGRepresentation(testImage)!
        let scale = Int(UIScreen.main.scale)
        let testURLString = "https://example.com/foo@\(scale)x.png"
        guard let testURL = URL(string:testURLString) else {
            return
        }
        
        
        URLProtocol.registerClass(WMFHTTPHangingProtocol.self)
        
        
        let failure = { (error: Error) in
        }
        
        let success = { (imgDownload: ImageDownload) in
        }
        
        imageController.fetchImage(withURL: testURL, failure:failure, success: success)
        
        imageController.cancelFetch(withURL: testURL)

        URLProtocol.unregisterClass(WMFHTTPHangingProtocol.self)
        LSNocilla.sharedInstance().start()
        defer {
            LSNocilla.sharedInstance().stop()
        }
        
        _ = stubRequest("GET", testURLString as LSMatcheable!).andReturnRawResponse(stubbedData)
        
        let secondExpectation = self.expectation(description: "wait for image download");
        
        let secondFailure = { (error: Error) in
            XCTFail()
            secondExpectation.fulfill()
        }
        
        let secondsuccess = { (imgDownload: ImageDownload) in
            XCTAssertNotNil(imgDownload.image);
            secondExpectation.fulfill()
        }
        
        imageController.fetchImage(withURL: testURL, failure:secondFailure, success: secondsuccess)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }
}
