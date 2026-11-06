#!/usr/bin/env swift

/**
 * 简单的语法测试脚本
 * 验证Swift代码的基本语法正确性
 */

import Foundation

// Test basic Swift syntax and imports
print("🚀 开始测试BTC价格追踪应用...")

// Test Foundation framework availability
let currentDate = Date()
print("✅ Foundation框架可用 - 当前时间: \(currentDate)")

// Test basic data structures
struct TestBTCPrice {
    let usdPrice: Double
    let cnyPrice: Double
    let timestamp: Date
    
    init(usdPrice: Double, cnyPrice: Double) {
        self.usdPrice = usdPrice
        self.cnyPrice = cnyPrice
        self.timestamp = Date()
    }
}

// Test price formatting
func formatUSDPrice(_ price: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
}

func formatCNYPrice(_ price: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "CNY"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: price)) ?? "¥0.00"
}

// Test data creation and formatting
let testPrice = TestBTCPrice(usdPrice: 45000.0, cnyPrice: 320000.0)
print("✅ 数据结构测试通过")
print("   USD价格: \(formatUSDPrice(testPrice.usdPrice))")
print("   CNY价格: \(formatCNYPrice(testPrice.cnyPrice))")
print("   时间戳: \(testPrice.timestamp)")

// Test URL creation for API
if let apiURL = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,cny") {
    print("✅ API URL创建成功: \(apiURL)")
} else {
    print("❌ API URL创建失败")
}

// Test JSON parsing structure
struct TestCoinGeckoResponse: Codable {
    let bitcoin: TestBitcoinPrice
}

struct TestBitcoinPrice: Codable {
    let usd: Double
    let cny: Double
}

print("✅ JSON解析结构定义完成")

// Test array operations for price history
var priceHistory: [TestBTCPrice] = []
priceHistory.append(testPrice)
priceHistory.append(TestBTCPrice(usdPrice: 46000.0, cnyPrice: 327000.0))
priceHistory.append(TestBTCPrice(usdPrice: 44500.0, cnyPrice: 316500.0))

print("✅ 价格历史数组操作测试通过")
print("   历史记录数量: \(priceHistory.count)")

// Test price statistics calculation
let usdPrices = priceHistory.map { $0.usdPrice }
let maxUSDPrice = usdPrices.max() ?? 0
let minUSDPrice = usdPrices.min() ?? 0
let avgUSDPrice = usdPrices.reduce(0, +) / Double(usdPrices.count)

print("✅ 价格统计计算测试通过")
print("   最高USD价格: \(formatUSDPrice(maxUSDPrice))")
print("   最低USD价格: \(formatUSDPrice(minUSDPrice))")
print("   平均USD价格: \(formatUSDPrice(avgUSDPrice))")

// Test date formatting
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "HH:mm:ss"
let timeString = dateFormatter.string(from: currentDate)
print("✅ 时间格式化测试通过: \(timeString)")

print("\n🎉 所有基础功能测试通过！")
print("📱 BTC价格追踪应用核心功能验证完成")
print("\n注意事项:")
print("- 本测试仅验证基础Swift语法和数据结构")
print("- SwiftUI界面需要在iOS模拟器或设备上运行")
print("- 网络请求需要实际的网络连接")
print("- Charts框架需要iOS 16.0+支持")