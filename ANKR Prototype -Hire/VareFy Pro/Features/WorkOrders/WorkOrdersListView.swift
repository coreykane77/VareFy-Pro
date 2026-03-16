import SwiftUI

struct WorkOrdersListView: View {
    @Environment(WorkOrderViewModel.self) private var workOrderVM

    private var sorted: [WorkOrder] {
        workOrderVM.workOrders.sorted {
            let p0 = $0.status.sortPriority
            let p1 = $1.status.sortPriority
            if p0 != p1 { return p0 < p1 }
            return $0.scheduledTime < $1.scheduledTime
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sorted) { order in
                        NavigationLink(value: NavRoute.workOrderDetail(order.id)) {
                            WorkOrderCardView(order: order)
                        }
                        .buttonStyle(.highlightRow)
                        .simultaneousGesture(TapGesture().onEnded { Haptics.light() })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Work Orders")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .closeButton()
    }
}
