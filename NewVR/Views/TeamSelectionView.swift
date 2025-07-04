import SwiftUI
import MapKit
import CoreLocation

/// チーム選択画面（10人対応）
struct TeamSelectionView: View {
    @StateObject private var teamManager = TeamManager()
    @Binding var selectedTeam: TeamManager.Team?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("チームを選択してください")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("各チーム最大\(GameConfiguration.shared.maxPlayersPerTeam)人まで")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(teamManager.teams) { team in
                        TeamCardView(
                            team: team,
                            isSelected: selectedTeam?.id == team.id,
                            onSelect: {
                                selectedTeam = team
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
                
                Button("参加する") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTeam == nil)
            }
            .navigationTitle("チーム選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

/// チームカードUI
struct TeamCardView: View {
    let team: TeamManager.Team
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // チームアイコン
            Circle()
                .fill(Color(team.color.uiColor))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            // チーム名
            Text(team.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            // プレイヤー数
            Text("\(team.players.count)/\(GameConfiguration.shared.maxPlayersPerTeam)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 空き状況
            HStack {
                Image(systemName: team.isFull ? "lock.fill" : "checkmark.circle.fill")
                    .foregroundColor(team.isFull ? .red : .green)
                
                Text(team.isFull ? "満員" : "参加可能")
                    .font(.caption2)
                    .foregroundColor(team.isFull ? .red : .green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color(team.color.uiColor).opacity(0.2) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color(team.color.uiColor) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .onTapGesture {
            if !team.isFull {
                onSelect()
            }
        }
        .disabled(team.isFull)
    }
}

/// スケーラブルなマップビュー（10人対応）
struct ScalableMapView: View {
    @StateObject private var viewModel = ScalableMapLocationViewModel()
    @State private var showTeamSelection = false
    
    var body: some View {
        VStack {
            // ヘッダー
            headerView
            
            // 統計情報
            statisticsView
            
            // マップ
            if let region = viewModel.region {
                Map(coordinateRegion: .constant(region), annotationItems: viewModel.userLocations) { location in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                        ScalablePlayerMarkerView(location: location)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    radarOverlay,
                    alignment: .center
                )
            } else {
                ProgressView("位置取得中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showTeamSelection) {
            TeamSelectionView(
                selectedTeam: $viewModel.selectedTeam,
                isPresented: $showTeamSelection
            )
        }
        .onAppear {
            if viewModel.selectedTeam == nil {
                showTeamSelection = true
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // チーム情報
            if let team = viewModel.selectedTeam {
                Button(action: { showTeamSelection = true }) {
                    HStack {
                        Circle()
                            .fill(Color(team.color.uiColor))
                            .frame(width: 20, height: 20)
                        
                        Text(team.name)
                            .font(.headline)
                    }
                }
            }
            
            Spacer()
            
            // 表示モード切り替え
            Picker("表示モード", selection: $viewModel.displayMode) {
                ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.description).tag(mode)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding()
    }
    
    private var statisticsView: some View {
        HStack {
            let teammates = viewModel.userLocations.filter { $0.isTeammate }
            let enemies = viewModel.userLocations.filter { !$0.isTeammate }
            
            // 味方数
            Label("\(teammates.count)", systemImage: "person.fill")
                .foregroundColor(.blue)
            
            Spacer()
            
            // 敵数（表示モードによって）
            if viewModel.displayMode != .teammateOnly {
                Label("\(enemies.count)", systemImage: "person.fill")
                    .foregroundColor(.red)
                
                if viewModel.displayMode == .teammateWithDelayed {
                    Text("(遅延)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // レーダー情報
            if viewModel.displayMode == .teammateWithRadar {
                Text("📡 \(Int(GameConfiguration.shared.radarRange))m")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .font(.caption)
    }
    
    @ViewBuilder
    private var radarOverlay: some View {
        if viewModel.displayMode == .teammateWithRadar {
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .frame(width: 200, height: 200)
                .allowsHitTesting(false)
        }
    }
}

/// スケーラブルなプレイヤーマーカー
struct ScalablePlayerMarkerView: View {
    let location: EnhancedLocationData
    
    private var markerColor: Color {
        if location.isTeammate {
            return .blue
        } else if location.isDelayed {
            return .orange
        } else {
            return .red
        }
    }
    
    private var markerSize: CGFloat {
        location.isTeammate ? 35 : 25
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: location.isDelayed ? "mappin.circle" : "mappin.circle.fill")
                .resizable()
                .frame(width: markerSize, height: markerSize)
                .foregroundColor(markerColor)
                .opacity(location.isDelayed ? 0.6 : 1.0)
            
            Text(location.username.prefix(6))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.black)
                .background(Color.white.opacity(0.8))
                .cornerRadius(2)
            
            Text("HP:\(location.hp)")
                .font(.system(size: 8))
                .foregroundColor(.gray)
            
            if location.isDelayed {
                Text("🕐")
                    .font(.system(size: 8))
            }
        }
        .scaleEffect(location.isTeammate ? 1.0 : 0.8)
    }
}

#Preview {
    ScalableMapView()
}