import Foundation
import CoreLocation
import UserNotifications
import UIKit

class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
        @Published var locationStatus: CLAuthorizationStatus = .notDetermined
        @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
        
        private let locationManager = CLLocationManager()
        
        override init() {
                super.init()
                locationManager.delegate = self
                checkNotificationStatus()
            }
        
        // MARK: - Location
        func requestLocationPermission() {
                locationManager.requestWhenInUseAuthorization()
            }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                DispatchQueue.main.async {
                        self.locationStatus = manager.authorizationStatus
                    }
            }
        
        // MARK: - Notifications
        func requestNotificationPermission() {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        DispatchQueue.main.async {
                                self.checkNotificationStatus()
                            }
                    }
            }
        
        func checkNotificationStatus() {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                                self.notificationStatus = settings.authorizationStatus
                            }
                    }
            }
        
        // MARK: - Helpers
        func openSettings() {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
            }
        
        var canProceed: Bool {
                // Must have location (authorized). Notifications can be anything as long as it's been asked (not determined).
                let locationGranted = (locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways)
                let notificationsAsked = (notificationStatus != .notDetermined)
                return locationGranted && notificationsAsked
            }
}


