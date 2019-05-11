//
//  StatsViewController.swift
//  CycleStats
//
//  Created by Daniel Grießhaber on 11.05.19.
//  Copyright © 2019 Daniel Grießhaber. All rights reserved.
//

import UIKit
import HealthKit

class PageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    
    lazy var orderedViewControllers: [UIViewController] = {
        return [self.newController(unit: "km", title: "Cycling Distance", quantity: .distanceCycling, unitType: HKUnit.meter()),
                self.newController(unit: "km", title: "Walking Distance", quantity: .distanceWalkingRunning, unitType: HKUnit.meter()),
                self.newController(unit: "kcal", title: "Active Energy Burned", quantity: .activeEnergyBurned, unitType: HKUnit.kilocalorie())]
    }()
    
    let healthStore = HKHealthStore()
    let pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50,width: UIScreen.main.bounds.width,height: 50))
    var currentStatsViewController: StatsViewController?
    
    override func viewDidLoad() {
        self.dataSource = self
        
        // This sets up the first view that will show up on our page control
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        
        self.delegate = self
        configurePageControl()
        
        if !HKHealthStore.isHealthDataAvailable() {
            exit(0)
        }
        
        let allTypes = Set([HKObjectType.workoutType(),
                            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
                            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!])
        
        healthStore.requestAuthorization(toShare: nil, read: allTypes) { (success, error) in
            if !success {
                exit(0)
            }
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.currentStatsViewController?.updateValues()
    }

    func configurePageControl() {
        self.pageControl.numberOfPages = orderedViewControllers.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.darkGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.lightGray
        self.view.addSubview(pageControl)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0] as! StatsViewController
        self.pageControl.currentPage = orderedViewControllers.firstIndex(of: pageContentViewController)!
        
        self.currentStatsViewController = pageContentViewController
        self.currentStatsViewController!.updateValues()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count

        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func newController(unit: String, title: String, quantity: HKQuantityTypeIdentifier, unitType: HKUnit) -> UIViewController {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StatsViewController") as! StatsViewController
        
        controller.healthStore = self.healthStore
        
        controller.unit = unit
        controller.activityTitle = title
        controller.quantity = quantity
        controller.unitType = unitType
        if unitType == HKUnit.meter() {
            controller.unitFactor = 1000
            controller.distanceFormat = "%.2f %@"
        }else{
            controller.unitFactor = 1
            controller.distanceFormat = "%.0f %@"
        }
        return controller
    }
}
