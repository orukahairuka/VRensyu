//
//  UsernameInputView.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/06/14.
//

import SwiftUI

struct UsernameInputView: View {
    @Binding var username: String
    @Binding var groupCode: String

    @State private var tempName = ""
    @State private var tempGroup = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("プレイヤー情報を入力")
                .font(.title2)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text("ユーザー名（末尾に 1 or 2 を付けてください）")
                TextField("例: erika1", text: $tempName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("チーム名（英数字）")
                TextField("例: TEAM123", text: $tempGroup)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            Button("決定") {
                username = tempName
                groupCode = tempGroup
                UserDefaults.standard.set(tempName, forKey: "username")
                UserDefaults.standard.set(tempGroup, forKey: "groupCode")
            }
            .disabled(tempName.isEmpty || tempGroup.isEmpty || !["1", "2"].contains(tempName.suffix(1)))
            .padding()
            .background(Color.blue.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }
}
