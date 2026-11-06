#!/usr/bin/env swift

/**
 * API连接测试脚本
 * 验证CoinGecko API的可用性和数据格式
 */

import Foundation

print("🌐 开始测试BTC价格API连接...")

// API响应数据结构
struct CoinGeckoResponse: Codable {
    let bitcoin: BitcoinPrice
}

struct BitcoinPrice: Codable {
    let usd: Double
    let cny: Double
}

// 创建API URL
guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,cny") else {
    print("❌ API URL创建失败")
    exit(1)
}

print("✅ API URL: \(url)")

// 创建信号量用于同步异步操作
let semaphore = DispatchSemaphore(value: 0)
var apiSuccess = false

// 发起网络请求
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    defer { semaphore.signal() }
    
    if let error = error {
        print("❌ 网络请求失败: \(error.localizedDescription)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ 无效的HTTP响应")
        return
    }
    
    print("📡 HTTP状态码: \(httpResponse.statusCode)")
    
    guard httpResponse.statusCode == 200 else {
        print("❌ HTTP请求失败，状态码: \(httpResponse.statusCode)")
        return
    }
    
    guard let data = data else {
        print("❌ 没有接收到数据")
        return
    }
    
    print("📦 接收到数据大小: \(data.count) bytes")
    
    // 打印原始JSON数据
    if let jsonString = String(data: data, encoding: .utf8) {
        print("📄 原始JSON数据: \(jsonString)")
    }
    
    // 解析JSON数据
    do {
        let decoder = JSONDecoder()
        let response = try decoder.decode(CoinGeckoResponse.self, from: data)
        
        print("✅ JSON解析成功")
        print("💰 BTC价格信息:")
        print("   USD: $\(String(format: "%.2f", response.bitcoin.usd))")
        print("   CNY: ¥\(String(format: "%.2f", response.bitcoin.cny))")
        
        // 计算汇率
        let exchangeRate = response.bitcoin.cny / response.bitcoin.usd
        print("   汇率 (CNY/USD): \(String(format: "%.4f", exchangeRate))")
        
        apiSuccess = true
        
    } catch {
        print("❌ JSON解析失败: \(error)")
    }
}

print("🔄 发起API请求...")
task.resume()

// 等待请求完成（最多30秒）
let timeoutResult = semaphore.wait(timeout: .now() + 30)

if timeoutResult == .timedOut {
    print("⏰ 请求超时（30秒）")
    task.cancel()
} else if apiSuccess {
    print("\n🎉 API连接测试成功！")
    print("✅ CoinGecko API可正常访问")
    print("✅ 数据格式正确")
    print("✅ BTC价格获取成功")
} else {
    print("\n❌ API连接测试失败")
}

print("\n📋 测试总结:")
print("- API端点: CoinGecko Simple Price API")
print("- 支持货币: USD, CNY")
print("- 数据格式: JSON")
print("- 更新频率: 实时")
print("- 免费使用: 是（有请求限制）")

if apiSuccess {
    print("\n🚀 应用可以正常获取实时BTC价格数据！")
} else {
    print("\n⚠️  请检查网络连接或API服务状态")
}