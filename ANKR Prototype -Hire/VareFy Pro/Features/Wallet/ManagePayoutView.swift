import SwiftUI

struct ManagePayoutView: View {
    @Environment(WalletViewModel.self) private var walletVM
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = ""
    @State private var isInstant: Bool = true
    @State private var showConfirmation = false
    @FocusState private var amountFocused: Bool

    private var amount: Double { Double(amountText) ?? 0 }
    private var fee: Double { isInstant ? amount * 0.015 : 0 }
    private var canSubmit: Bool { amount > 0 && amount <= walletVM.balance }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        amountInput
                        methodPicker
                        destinationRow
                        feeDisclosure
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                VStack(spacing: 12) {
                    if canSubmit {
                        SlideToConfirmView(label: "Slide to Confirm Payout") {
                            walletVM.requestPayout(amount: amount, isInstant: isInstant)
                            showConfirmation = true
                        }
                    } else {
                        PrimaryButton(title: "Confirm Payout", isEnabled: false) {}
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, Constants.bottomBarHeight + 24)
                .background(Color.appBackground)
            }
        }
        .navigationTitle("Manage Payout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { amountFocused = false }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.varefyProCyan)
            }
        }
        .popButton()
        .onAppear {
            let floored = floor(walletVM.balance * 100) / 100
            amountText = String(format: "%.2f", floored)
        }
        .alert("Payout Submitted", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("\((amount - fee).formattedAsCurrency()) will be deposited to your account.")
        }
    }

    private var amountInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AMOUNT")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
            }
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack {
                Text("Available: \(walletVM.balance.formattedAsCurrency())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    let floored = floor(walletVM.balance * 100) / 100
                    amountText = String(format: "%.2f", floored)
                    amountFocused = false
                } label: {
                    Text("Use Full Balance")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.varefyProCyan.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var methodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("METHOD")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
            HStack(spacing: 12) {
                methodOption(title: "Instant Pay", subtitle: "1.5% fee", selected: isInstant) {
                    isInstant = true
                }
                methodOption(title: "Bank Transfer", subtitle: "Free", selected: !isInstant) {
                    isInstant = false
                }
            }
        }
    }

    @ViewBuilder
    private func methodOption(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    if title == "Instant Pay" {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selected ? .black : .white)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(selected ? .black.opacity(0.7) : .gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(selected ? Color.varefyProCyan : Color.varefyProCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var destinationRow: some View {
        HStack {
            Image(systemName: "building.columns.fill")
                .foregroundStyle(Color.varefyProCyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Chase ••••4521")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text("Checking account")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Default")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var feeDisclosure: some View {
        VStack(spacing: 8) {
            if isInstant && amount > 0 {
                HStack {
                    Text("Instant fee (1.5%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(fee.formattedAsCurrency())
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            HStack {
                Text("You receive")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Text(amount > 0 ? (amount - fee).formattedAsCurrency() : "--")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.varefyProCyan)
            }
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
