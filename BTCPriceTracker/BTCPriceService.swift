//
//  BTCPriceService.swift
//  BTCPriceTracker
//
//  Created by Developer on 2024.
//

import Foundation
import Combine

// MARK: - 价格数据模型
struct BTCPrice: Codable, Identifiable {
    let id = UUID()
    let usdPrice: Double
    let cnyPrice: Double
    let timestamp: Date
    
    init(usdPrice: Double, cnyPrice: Double, timestamp: Date = Date()) {
        self.usdPrice = usdPrice
        self.cnyPrice = cnyPrice
        self.timestamp = timestamp
    }
}

// MARK: - API响应模型
struct CoinGeckoResponse: Codable {
    let bitcoin: BitcoinPrice
}

struct BitcoinPrice: Codable {
    let usd: Double
    let cny: Double
}

// MARK: - BTC价格服务类
class BTCPriceService: ObservableObject {
    @Published var currentPrice: BTCPrice?
    @Published var priceHistory: [BTCPrice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    private let baseURL = "https://api.coingecko.com/api/v3/simple/price"
    
    init() {
        startPriceUpdates()
    }
    
    deinit {
        stopPriceUpdates()
    }
    
    /**
     * 开始定时更新价格
     * 每30秒获取一次最新价格
     */
    func startPriceUpdates() {
        guard timer == nil else { return }
        // Fetch initial price
        fetchCurrentPrice()
        
        // Set up timer for regular updates
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentPrice()
        }
    }
    
    /**
     * 停止价格更新
     */
    func stopPriceUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    /**
     * 获取当前BTC价格
     * 同时获取USD和CNY价格
     */
    func fetchCurrentPrice() {
        guard let url = URL(string: "\(baseURL)?ids=bitcoin&vs_currencies=usd,cny") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: CoinGeckoResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch price: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    let newPrice = BTCPrice(
                        usdPrice: response.bitcoin.usd,
                        cnyPrice: response.bitcoin.cny
                    )
                    self?.currentPrice = newPrice
                    self?.addToHistory(newPrice)
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 添加价格到历史记录
     * 保持最近100个价格点用于图表显示
     * @param price: 新的价格数据
     */
    private func addToHistory(_ price: BTCPrice) {
        priceHistory.append(price)
        
        // Keep only last 100 price points for chart
        if priceHistory.count > 100 {
            priceHistory.removeFirst()
        }
    }
    
    /**
     * 手动刷新价格
     */
    func refreshPrice() {
        fetchCurrentPrice()
    }
    
    /**
     * 格式化USD价格显示
     * @param price: 价格数值
     * @return: 格式化的价格字符串
     */
    func formatUSDPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
    
    /**
     * 格式化CNY价格显示
     * @param price: 价格数值
     * @return: 格式化的价格字符串
     */
    func formatCNYPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "¥0.00"
    }
}
