//// Copyright 2018 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

protocol AppContainerFocusDelegate: AnyObject {
    
    func controllerBecomingFocus()
}

class AppContainerViewController: UIViewController {
    
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var secondRightBarButton: UIBarButtonItem!
    
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var mainMapView: UIView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView! 
    
    @IBOutlet weak var outsideDrawerTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var drawerLeadingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var drawerTrailingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var drawerDesiredWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var drawerAccessibleWidthLayoutConstraint: NSLayoutConstraint!
    
    private let changeHandler = AppContextChangeHandler()
    
    weak var drawerViewController: DrawerViewController?
    weak var mapViewController: MapViewController?
    weak var jobStatusViewController: JobStatusViewController?
    
    var drawerShowing: Bool = false {
        didSet {
            adjustForDrawerShowing()
            adjustNavigationBarButtons()
            informChildViewControllersOfFocus()
        }
    }
    
    var showProfileBarButton: Bool = true {
        didSet {
            adjustNavigationBarButtons()
        }
    }
    
    var showAddFeatureBarButton: Bool = true {
        didSet {
            adjustNavigationBarButtons()
        }
    }
    
    var showZoomToLocationBarButton: Bool = true {
        didSet {
            adjustNavigationBarButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustNavigationBarButtons()
        adjustForDrawerShowing(isAnimated: false)
        subscribeToContentSizeCategoryChanges()
        adjustForContentSize()
    }
    
    @IBAction func userTapsOutsideOfDrawer(_ sender: Any) {
        drawerShowing = false
    }
    
    @IBAction func userRequestsToggleDrawer(_ sender: Any) {
        drawerShowing.toggle()
    }
    
    private func subscribeToContentSizeCategoryChanges() {
        
        let contentSizeChange: AppContextChange = .contentSize { [weak self] (category) in
            self?.adjustForContentSize(category: category)
        }
        
        changeHandler.subscribe(toChange: contentSizeChange)
    }
    
    private func adjustForContentSize(category: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory) {
        
        if category.isAccessibilityCategory {
            drawerDesiredWidthLayoutConstraint.isActive = false
            drawerAccessibleWidthLayoutConstraint.isActive = true
        }
        else {
            drawerDesiredWidthLayoutConstraint.isActive = true
            drawerAccessibleWidthLayoutConstraint.isActive = false
        }
        
        view.layoutIfNeeded()
    }
    
    private func informChildViewControllersOfFocus() {
        if drawerShowing {
            drawerViewController?.controllerBecomingFocus()
        }
        else {
            mapViewController?.controllerBecomingFocus()
        }
    }
    
    @IBAction func userTapsSecondRightButton(_ sender: Any) {
        mapViewController?.userRequestsZoomOnUserLocation()
    }
    
    @IBAction func userTapsRightButton(_ sender: Any) {
        mapViewController?.userRequestsAddNewFeature()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let destination = segue.destination as? MapViewController {
            destination.delegate = self
            mapViewController = destination
        }
        else if let destination = segue.destination as? DrawerViewController {
            destination.delegate = self
            drawerViewController = destination
        }
        else if let destination = segue.destination as? JobStatusViewController {
            destination.jobConstruct = EphemeralCache.get(objectForKey: OfflineMapJobConstruct.EphemeralCacheKeys.offlineMapJob) as? OfflineMapJobConstruct
            destination.delegate = self
            jobStatusViewController = destination
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (_) in
            self.adjustForDrawerShowing(isAnimated: false)
        }, completion: nil)
    }
    
    func adjustForDrawerShowing(isAnimated animated: Bool = true) {
        
        let animationDuration = animated ? 0.2 : 0.0
        
        drawerLeadingLayoutConstraint.isActive = drawerShowing
        drawerViewController?.view.isUserInteractionEnabled = drawerShowing
        visualEffectView.isUserInteractionEnabled = drawerShowing
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            self?.adjustVisualEffectViewBlurEffect()
        })
    }
    
    private func adjustVisualEffectViewBlurEffect() {
        self.visualEffectView.effect = self.drawerShowing ? UIBlurEffect(style: .light) : nil
    }
    
    private func adjustVisualEffectViewIsUserInteractionEnabled() {
        self.visualEffectView.isUserInteractionEnabled = self.drawerShowing
    }
    
    func adjustNavigationBarButtons() {
        
        rightBarButton?.isEnabled = !drawerShowing && showAddFeatureBarButton
        secondRightBarButton?.isEnabled = !drawerShowing && showZoomToLocationBarButton
        leftBarButton?.isEnabled = showProfileBarButton
    }
}
