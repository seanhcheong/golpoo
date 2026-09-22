import SwiftUI
import GolfSwingCore

struct SwingSetupView: View {
    @StateObject private var viewModel = SwingSetupViewModel()
    let onContinue: (ClubCategory, CameraAngle, UserProfile) -> Void

    var body: some View {
        Form {
            Section("Club Category") {
                Text(viewModel.clubCategory.rawValue)
                    .foregroundStyle(.secondary)
            }

            Section("Camera Angle") {
                Picker("Camera Angle", selection: $viewModel.cameraAngle) {
                    ForEach(CameraAngle.allCases, id: \.self) { angle in
                        Text(angle.rawValue).tag(angle)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Height") {
                HStack {
                    Picker("Feet", selection: $viewModel.heightFeet) {
                        ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                    }
                    .pickerStyle(.wheel)

                    Picker("Inches", selection: $viewModel.heightInches) {
                        ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 120)
            }

            Section {
                Button("Start Recording") {
                    let profile = viewModel.confirmProfile()
                    onContinue(viewModel.clubCategory, viewModel.cameraAngle, profile)
                }
            }
        }
        .navigationTitle("New Swing")
    }
}
