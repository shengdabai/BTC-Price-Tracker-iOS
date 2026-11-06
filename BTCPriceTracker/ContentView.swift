//
//  ContentView.swift
//  BTCPriceTracker
//
//  Created by Developer on 2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var priceService = BTCPriceService()
    @State private var showingRefreshAnimation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Bitcoin logo and title
                    headerView
                    
                    // Current price display
                    currentPriceView
                    
                    // Price chart
                    PriceChartView(priceHistory: priceService.priceHistory)
                    
                    // Last update info
                    lastUpdateView
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("BTC价格追踪")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showingRefreshAnimation = true
                        }
                        priceService.refreshPrice()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingRefreshAnimation = false
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(showingRefreshAnimation ? 360 : 0))
                            .animation(.easeInOut(duration: 0.5), value: showingRefreshAnimation)
                    }
                }
            }
            .refreshable {
                priceService.refreshPrice()
            }
        }
        .alert("错误", isPresented: .constant(priceService.errorMessage != nil)) {
            Button("确定") {
                priceService.errorMessage = nil
            }
        } message: {
            Text(priceService.errorMessage ?? "")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Bitcoin icon
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 50, height: 50)
                
                Text("₿")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading) {
                Text("Bitcoin")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("BTC")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Loading indicator
            if priceService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Current Price View
    private var currentPriceView: some View {
        VStack(spacing: 16) {
            if let currentPrice = priceService.currentPrice {
                // USD Price
                PriceCardView(
                    title: "美元价格",
                    price: priceService.formatUSDPrice(currentPrice.usdPrice),
                    currency: "USD",
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )
                
                // CNY Price
                PriceCardView(
                    title: "人民币价格",
                    price: priceService.formatCNYPrice(currentPrice.cnyPrice),
                    currency: "CNY",
                    color: .red,
                    icon: "yensign.circle.fill"
                )
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在获取价格数据...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(height: 120)
            }
        }
    }
    
    // MARK: - Last Update View
    private var lastUpdateView: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            
            Text("最后更新: \(formatLastUpdateTime())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    /**
     * 格式化最后更新时间
     * @return: 格式化的时间字符串
     */
    private func formatLastUpdateTime() -> String {
        guard let lastUpdate = priceService.currentPrice?.timestamp else {
            return "未知"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: lastUpdate)
    }
}

// MARK: - Price Card View Component
struct PriceCardView: View {
    let title: String
    let price: String
    let currency: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(price)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack {
                Text(currency)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}