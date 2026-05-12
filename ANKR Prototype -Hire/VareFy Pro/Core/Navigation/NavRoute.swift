import Foundation

enum NavRoute: Hashable {
    case messagesList
    case workOrdersList
    case workOrderDetail(UUID)
    case drive(UUID)
    case preWork(UUID)
    case activeBilling(UUID)
    case postWork(UUID)
    case summary(UUID)
    case chat(UUID)
    case wallet
    case managePayout
    case appSettings
    case control
    case myServices
    case serviceCategory(ServiceCategory)
    case serviceGroup(ServiceGroupRoute)
    case localOps
    case hireProfile
    case publicProfile
    case menu
    case account
    case h2h
    case boss
    case publicProfileDetail(PublicHireProfile)
    case termsOfService
    case privacyPolicy
    case learning
    case personalInfo
    case documents
    case vehicle
    case placeholder(String)
}
