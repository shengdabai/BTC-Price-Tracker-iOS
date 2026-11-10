import Foundation

// Intercept every URLSession request before creating the actual production service.
// This executable never contacts CoinGecko or reads application credentials.
final class FixtureProtocol: URLProtocol {
    static let lock = NSLock()
    static var requests = 0
    static var statusCode = 200
    static var body = #"{"bitcoin":{"usd":60000,"cny":420000}}"#
    static var delay: TimeInterval = 0
    static var transportError: URLError?
    private var pending: DispatchWorkItem?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.requests += 1
        let status = Self.statusCode
        let data = Data(Self.body.utf8)
        let delay = Self.delay
        let error = Self.transportError
        Self.lock.unlock()
        let delivery = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            let response = HTTPURLResponse(url: self.request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
        pending = delivery
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: delivery)
    }
    override func stopLoading() { pending?.cancel() }
    static func fixture(status: Int = 200,
                        body: String = #"{"bitcoin":{"usd":60000,"cny":420000}}"#,
                        delay: TimeInterval = 0, error: URLError? = nil) {
        lock.lock()
        defer { lock.unlock() }
        statusCode = status
        Self.body = body
        Self.delay = delay
        transportError = error
    }
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
service?.stopPriceUpdates()

for status in [401, 429, 500] {
    FixtureProtocol.fixture(status: status)
    let historyCount = service!.priceHistory.count
    let previousID = service!.currentPrice!.id
    service?.refreshPrice()
    check(waitFor { service?.isLoading == false }, "HTTP \(status) finishes loading")
    check(service?.errorMessage != nil && service?.currentPrice?.id == previousID
          && service?.priceHistory.count == historyCount,
          "HTTP \(status) rejects even a valid price body and preserves last price")
}

for body in [
    #"{"bitcoin":{"usd":-1,"cny":420000}}"#,
    #"{"bitcoin":{"usd":60000,"cny":0}}"#,
    #"{"bitcoin":{"usd":"60000","cny":420000}}"#,
    #"{"bitcoin":{"usd":1e400,"cny":420000}}"#,
    #"{"bitcoin":{"usd":60000}}"#,
    "not JSON", ""
] {
    FixtureProtocol.fixture(body: body)
    let historyCount = service!.priceHistory.count
    let previousID = service!.currentPrice!.id
    service?.refreshPrice()
    check(waitFor { service?.isLoading == false }, "invalid price finishes loading")
    check(service?.errorMessage != nil && service?.currentPrice?.id == previousID
          && service?.priceHistory.count == historyCount,
          "invalid price rejects and preserves last price: \(body)")
}

FixtureProtocol.fixture(error: URLError(.notConnectedToInternet))
let previousID = service!.currentPrice!.id
service?.refreshPrice()
check(waitFor { service?.isLoading == false }, "transport failure finishes loading")
check(service?.errorMessage != nil && service?.currentPrice?.id == previousID,
      "transport failure preserves last price")

FixtureProtocol.fixture(delay: 0.1)
let historyCount = service!.priceHistory.count
let requestCount = FixtureProtocol.requestCount
service?.refreshPrice()
for _ in 0..<10 { service?.refreshPrice() }
check(waitFor { service?.isLoading == false }, "delayed refresh completes")
check(FixtureProtocol.requestCount == requestCount + 1
      && service?.priceHistory.count == historyCount + 1,
      "overlapping refreshes share one request and one history point")
check(service?.errorMessage == nil, "successful refresh clears previous error")

FixtureProtocol.fixture()
for _ in 0..<105 {
    service?.refreshPrice()
    check(waitFor { service?.isLoading == false }, "sequential refresh completes")
}
check(service?.priceHistory.count == 100, "history stays bounded after repeated requests")
service?.startPriceUpdates()
check(waitFor { service?.isLoading == false }, "final active timer request finishes")
weak var releasedService = service
service = nil
check(releasedService == nil, "active timer does not retain the service")
exit(failures == 0 ? 0 : 1)
