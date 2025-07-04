import SwiftUI

/// リファクタリング後のContentView使用例
struct ContentViewRefactored: View {
    @StateObject private var viewModel = ViewModelContainer()
    
    var body: some View {
        VStack {
            // ヘルスバー
            HealthBarView(
                currentHealth: viewModel.mapViewModel.health,
                maxHealth: 300
            )
            
            // 接続状態
            ConnectionStatusView(
                status: viewModel.bleViewModel.connectionStatus,
                isConnected: viewModel.bleViewModel.isConnected,
                devicesFound: viewModel.bleViewModel.discoveredDevicesCount
            )
            
            // マップビュー
            UserMapView(viewModel: viewModel.mapViewModel)
            
            // エラー表示
            if let error = viewModel.bleViewModel.errorMessage {
                ErrorBanner(
                    message: error,
                    onRetry: viewModel.bleViewModel.retryConnection
                )
            }
            
            // デバッグログ（開発時のみ）
            #if DEBUG
            BLELogView(logs: viewModel.bleViewModel.logs)
                .frame(height: 100)
            #endif
        }
    }
}

/// ViewModelを管理するコンテナクラス
class ViewModelContainer: ObservableObject {
    let mapViewModel: MapLocationViewModel
    let bleViewModel: BleViewModel
    
    init() {
        let container = ServiceContainer.shared
        self.mapViewModel = MapLocationViewModel()
        self.bleViewModel = container.makeBleViewModel(healthManager: mapViewModel)
    }
}

// MARK: - Subviews
struct HealthBarView: View {
    let currentHealth: Int
    let maxHealth: Int
    
    private var healthPercentage: Double {
        Double(currentHealth) / Double(maxHealth)
    }
    
    private var barColor: Color {
        switch healthPercentage {
        case 0.6...1.0:
            return .green
        case 0.3..<0.6:
            return .yellow
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("HP")
                    .font(.headline)
                Spacer()
                Text("\(currentHealth) / \(maxHealth)")
                    .font(.system(.body, design: .monospaced))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(barColor)
                        .frame(
                            width: geometry.size.width * healthPercentage,
                            height: 20
                        )
                        .cornerRadius(10)
                        .animation(.easeInOut(duration: 0.3), value: healthPercentage)
                }
            }
            .frame(height: 20)
        }
        .padding()
    }
}

struct ConnectionStatusView: View {
    let status: String
    let isConnected: Bool
    let devicesFound: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            Text(status)
                .font(.caption)
            
            Spacer()
            
            if devicesFound > 0 && !isConnected {
                Text("\(devicesFound)台発見")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("再試行") {
                onRetry()
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(4)
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct BLELogView: View {
    let logs: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(logs.suffix(10), id: \.self) { log in
                    Text(log)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}