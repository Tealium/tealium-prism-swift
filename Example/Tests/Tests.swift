import XCTest
@testable import tealium_swift

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testFlatMap() {
            let pub = TealiumPublishSubject<Int>()
            let obs = pub.asObservable()
            _ = obs.flatMap { integer in
                TealiumObservableCreate<String> { observer in
                    observer("start")
                    observer("finish")
                    return TealiumSubscription { }
                }
            }.subscribe { stuff in
                print(stuff)
            }
            
            pub.publish(1)
            pub.publish(2)
        let expect = expectation(description: "completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            pub.publish(3)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5)
            // We should get twice start-finish
    }
    
    
}
