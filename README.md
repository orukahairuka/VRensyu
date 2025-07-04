# NewVR 🎮

[![Swift](https://img.shields.io/badge/Swift-5.0+-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-000000?style=for-the-badge&logo=ios&logoColor=white)](https://developer.apple.com/ios/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFA000?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Bluetooth](https://img.shields.io/badge/Bluetooth-LE-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)](https://developer.apple.com/bluetooth/)

## 🌟 概要

NewVRは、物理的なESP32デバイスとモバイルアプリケーションを組み合わせた革新的なリアルタイム位置情報ベースのマルチプレイヤーバトルゲームです。プレイヤーは実世界でチームを組み、Bluetooth対応のコントローラーを使って対戦します。

### ✨ 主な特徴

- 🎯 **リアルタイムバトル**: ESP32デバイスのボタンやIRセンサーを使った物理的な攻撃システム
- 🗺️ **位置情報追跡**: すべてのプレイヤーの位置をリアルタイムで地図上に表示
- 👥 **チームプレイ**: グループコードを使用したチーム制バトル
- 💙 **Bluetooth連携**: ESP32デバイスとのシームレスなBLE通信
- 🔥 **Firebase同期**: リアルタイムでのプレイヤーデータ同期
- 🎵 **サウンドエフェクト**: 爆発音や呪いの旋律などの効果音

## 📱 スクリーンショット

<div align="center">
  <img src="docs/images/gameplay.png" width="250" alt="ゲームプレイ画面">
  <img src="docs/images/map-view.png" width="250" alt="マップビュー">
  <img src="docs/images/setup.png" width="250" alt="セットアップ画面">
</div>

## 🎮 ゲームの流れ

1. **セットアップ**: ユーザー名（末尾に1または2が必須）とチームコードを入力
2. **デバイス接続**: 対応するESP32デバイスに自動接続
3. **バトル開始**: マップ上で他のプレイヤーの位置を確認しながら移動
4. **攻撃**: ESP32のボタンを押すと相手にダメージを与える（-10HP）
5. **勝利条件**: 相手のHPを0にすると勝利

## 🛠️ 技術スタック

### iOS アプリケーション
- **言語**: Swift 5.0+
- **UI フレームワーク**: SwiftUI
- **位置情報**: Core Location
- **Bluetooth**: Core Bluetooth (BLE)
- **バックエンド**: Firebase Firestore
- **地図**: MapKit

### ハードウェア
- **マイコン**: ESP32
- **センサー**: IRセンサー / 物理ボタン
- **通信**: Bluetooth Low Energy

## 📋 必要要件

### iOS アプリ
- iOS 14.0以降
- iPhone 6s以降推奨
- 位置情報サービスの許可
- Bluetoothの許可

### ハードウェア
- ESP32開発ボード × 2
- IRセンサーまたは物理ボタン
- Arduino IDE（ESP32ファームウェア書き込み用）

## 🚀 セットアップ

### 1. リポジトリのクローン
```bash
git clone https://github.com/yourusername/NewVR.git
cd NewVR
```

### 2. Firebase設定
1. [Firebase Console](https://console.firebase.google.com)で新しいプロジェクトを作成
2. iOSアプリを追加し、`GoogleService-Info.plist`をダウンロード
3. ダウンロードしたファイルをXcodeプロジェクトに追加

### 3. ESP32ファームウェアの書き込み
```cpp
// Arduino/ESP32_Code内のコードをESP32に書き込み
// 各プレイヤー用に異なるデバイス名を設定
// - "ESP32 IR Button 1" (プレイヤー1用)
// - "ESP32 IR Button 2" (プレイヤー2用)
```

### 4. Xcodeでのビルド
```bash
open NewVR.xcodeproj
# Command + R でビルド & 実行
```

## 🎯 使い方

### プレイヤーセットアップ
1. アプリを起動
2. ユーザー名を入力（必ず末尾に1または2を付ける）
   - 例: `player1`, `sakura2`
3. チームコードを入力（同じチームのプレイヤーと共有）
4. 「ゲーム開始」をタップ

### ゲームプレイ
- **移動**: 実際に歩いて移動（GPSで追跡）
- **攻撃**: ESP32のボタンを押す
- **体力確認**: 画面上部のHPバーで確認
- **復活**: HP0になったら「もう一度」ボタンで復活

## 🏗️ アーキテクチャ

### ViewModels
```
├── BleButtonListenerViewModel.swift  # Bluetooth通信管理
└── MapLocationViewModel.swift        # 位置情報とFirebase同期
```

### Views
```
├── ContentView.swift            # メインゲーム画面
├── UsernameInputView.swift      # 初期設定画面
├── UserMapView.swift            # リアルタイムマップ
└── BleButtonListenerView.swift  # BLEテスト画面
```

### データフロー
```
ESP32 Button Press
    ↓ (BLE)
iOS App (BleButtonListenerViewModel)
    ↓ (Damage Event)
MapLocationViewModel
    ↓ (Firebase)
All Connected Players
```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

### コーディング規約
- SwiftLintのルールに従う
- MVVMパターンを維持
- 新機能には適切なドキュメントを追加

## 🐛 既知の問題

- ESP32との接続が不安定になることがある → アプリ再起動で解決
- バックグラウンドでの位置情報更新に制限がある
- 同時接続可能なプレイヤー数に上限あり（Firebaseの制限に依存）

## 📝 今後の機能追加予定

- [ ] 3人以上のマルチプレイヤー対応
- [ ] 武器の種類追加（ダメージ量の変更）
- [ ] ゲームモードの追加（チームデスマッチ、キャプチャーザフラッグ等）
- [ ] リプレイ機能
- [ ] ランキングシステム
- [ ] カスタマイズ可能なアバター

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 👥 開発者

- **メイン開発者**: [@orukahairuka](https://github.com/orukahairuka)

## 🙏 謝辞

- ESP32コミュニティの皆様
- Firebaseドキュメントとサンプルコード
- SwiftUIチュートリアルとリソース

---

<div align="center">
  <p>Made with ❤️ by NewVR Team</p>
  <p>
    <a href="https://github.com/orukahairuka/NewVR/issues">Issues</a> •
    <a href="https://github.com/orukahairuka/NewVR/pulls">Pull Requests</a> •
    <a href="https://github.com/orukahairuka/NewVR/wiki">Wiki</a>
  </p>
</div>