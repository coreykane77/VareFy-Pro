import SwiftUI

struct PersonalInfoView: View {
    @Environment(ProfileViewModel.self) private var profileVM

    var body: some View {
        @Bindable var vm = profileVM
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    formSection("IDENTITY") {
                        fieldRow(label: "First Name", text: $vm.profile.firstName)
                        divider
                        fieldRow(label: "Last Name", text: $vm.profile.lastName)
                        divider
                        fieldRow(label: "Business Name", text: $vm.profile.businessName)
                    }

                    formSection("CONTACT") {
                        fieldRow(label: "Email", text: $vm.profile.email, keyboard: .emailAddress)
                        divider
                        fieldRow(label: "Mobile", text: $vm.profile.phone, keyboard: .phonePad)
                    }

                    formSection("LEGAL ADDRESS") {
                        fieldRow(label: "Street Address", text: $vm.profile.legalAddress)
                        divider
                        fieldRow(label: "City", text: $vm.profile.city)
                        divider
                        fieldRow(label: "State", text: $vm.profile.state)
                        divider
                        fieldRow(label: "ZIP", text: $vm.profile.zip, keyboard: .numbersAndPunctuation)
                        divider
                        fieldRow(label: "Country", text: $vm.profile.country)
                    }

                    formSection("PUBLIC PROFILE") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About / Bio — visible to clients on your profile")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $vm.profile.bio)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(16)
                    }

                    formSection("CLOSING MESSAGE") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sent to clients upon job completion")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $vm.profile.closingMessage)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .doneKeyboardToolbar()
        .popButton()
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider()
            .background(Color.white.opacity(0.08))
            .padding(.leading, 16)
    }

    @ViewBuilder
    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func fieldRow(label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            TextField("", text: text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
