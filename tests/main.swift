import Foundation

// Intercept every URLSession request before creating the actual production service.
// This executable never contacts CoinGecko or reads application credentials.
final class FixtureProtocol: URLProtocol {
    static let lock = NSLock()
    static var requests = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.requests += 1
        Self.lock.unlock()
        let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"bitcoin":{"usd":60000,"cny":420000}}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }
}

func waitFor(_ condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(3)
    while !condition() && Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    return condition()
}

precondition(URLProtocol.registerClass(FixtureProtocol.self))
defer { URLProtocol.unregisterClass(FixtureProtocol.self) }
var failures = 0
func check(_ condition: Bool, _ name: String) {
    print("\(condition ? "PASS" : "FAIL"): \(name)")
    if !condition { failures += 1 }
}

var service: BTCPriceService? = BTCPriceService()
check(waitFor { service?.currentPrice != nil && service?.isLoading == false }, "fixture loads in production service")
check(service?.currentPrice?.usdPrice == 60000 && service?.priceHistory.count == 1,
      "decoded fixture updates current price and history")
let before = FixtureProtocol.requestCount
service?.startPriceUpdates()
service?.startPriceUpdates()
RunLoop.current.run(until: Date().addingTimeInterval(0.1))
check(FixtureProtocol.requestCount == before, "repeated start is idempotent")
check(waitFor { service?.isLoading == false }, "requests finish")
service?.stopPriceUpdates()
service?.startPriceUpdates()
check(waitFor { FixtureProtocol.requestCount > before && service?.isLoading == false },
      "stopped updates can restart")
weak var releasedService = service
service = nil
check(releasedService == nil, "active timer does not retain the service")
exit(failures == 0 ? 0 : 1)
