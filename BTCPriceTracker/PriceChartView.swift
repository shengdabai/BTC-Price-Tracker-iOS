//
//  PriceChartView.swift
//  BTCPriceTracker
//
//  Created by Developer on 2024.
//

import SwiftUI
import Charts

// MARK: - 价格图表视图
struct PriceChartView: View {
    let priceHistory: [BTCPrice]
    @State private var selectedCurrency: Currency = .usd
    
    enum Currency: String, CaseIterable {
        case usd = "USD"
        case cny = "CNY"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart title and currency selector
            HStack {
                Text("价格走势图")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Text(currency.rawValue).tag(currency)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            // Price chart
            if priceHistory.isEmpty {
                // Empty state
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("暂无价格数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                // Chart with data
                Chart(priceHistory) { price in
                    LineMark(
                        x: .value("Time", price.timestamp),
                        y: .value("Price", selectedCurrency == .usd ? price.usdPrice : price.cnyPrice)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Time", price.timestamp),
                        y: .value("Price", selectedCurrency == .usd ? price.usdPrice : price.cnyPrice)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(formatPrice(price))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatTime(date))
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            // Chart statistics
            if !priceHistory.isEmpty {
                chartStatistics
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Chart Statistics View
    private var chartStatistics: some View {
        HStack(spacing: 20) {
            StatisticView(
                title: "最高价",
                value: formatPrice(maxPrice),
                color: .green
            )
            
            StatisticView(
                title: "最低价",
                value: formatPrice(minPrice),
                color: .red
            )
            
            StatisticView(
                title: "平均价",
                value: formatPrice(averagePrice),
                color: .blue
            )
        }
    }
    
    // MARK: - Computed Properties
    private var maxPrice: Double {
        priceHistory.map { selectedCurrency == .usd ? $0.usdPrice : $0.cnyPrice }.max() ?? 0
    }
    
    private var minPrice: Double {
        priceHistory.map { selectedCurrency == .usd ? $0.usdPrice : $0.cnyPrice }.min() ?? 0
    }
    
    private var averagePrice: Double {
        let prices = priceHistory.map { selectedCurrency == .usd ? $0.usdPrice : $0.cnyPrice }
        return prices.isEmpty ? 0 : prices.reduce(0, +) / Double(prices.count)
    }
    
    // MARK: - Helper Methods
    
    /**
     * 格式化价格显示
     * @param price: 价格数值
     * @return: 格式化的价格字符串
     */
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency == .usd ? "USD" : "CNY"
        formatter.maximumFractionDigits = selectedCurrency == .usd ? 0 : 0
        return formatter.string(from: NSNumber(value: price)) ?? "0"
    }
    
    /**
     * 格式化时间显示
     * @param date: 时间戳
     * @return: 格式化的时间字符串
     */
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Statistic View Component
struct StatisticView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
struct PriceChartView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = [
            BTCPrice(usdPrice: 45000, cnyPrice: 320000),
            BTCPrice(usdPrice: 46000, cnyPrice: 327000),
            BTCPrice(usdPrice: 44500, cnyPrice: 316500),
            BTCPrice(usdPrice: 47000, cnyPrice: 334000)
        ]
        
        PriceChartView(priceHistory: sampleData)
            .padding()
    }
}