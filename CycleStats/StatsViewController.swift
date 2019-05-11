//
//  ViewController.swift
//  CycleStats
//
//  Created by Daniel Grießhaber on 10.05.19.
//  Copyright © 2019 Daniel Grießhaber. All rights reserved.
//

import UIKit
import HealthKit

class StatsViewController: UIViewController {
    
    @IBOutlet weak var labelThisMonthDistance: UILabel!
    @IBOutlet weak var labelLastMonthDistance: UILabel!
    @IBOutlet weak var labelThisYearDistance: UILabel!
    @IBOutlet weak var labelLastYearDistance: UILabel!
    @IBOutlet weak var labelTotalDistance: UILabel!
    @IBOutlet weak var labelUnit: UILabel!
    @IBOutlet weak var progressMonth: UIProgressView!
    @IBOutlet weak var labelProgressMonth: UILabel!
    @IBOutlet weak var progressYear: UIProgressView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelProgressYear: UILabel!
    
    var distanceFormat = "%.2f %@"
    let progressFormat = "%d%%"
    var healthStore: HKHealthStore?
    var quantity: HKQuantityTypeIdentifier?
    var unitType: HKUnit?
    var unitFactor: Int = 1000
    
    var unit: String = "" {
        didSet {
            labelUnit?.text = unit
        }
    }
    
    var activityTitle: String = "" {
        didSet {
            labelTitle?.text = activityTitle
        }
    }
    
    var thisMonthValue: Double = 0.0 {
        didSet {
            labelThisMonthDistance?.text = String(format:self.distanceFormat, thisMonthValue, unit)
            var progress = Float(thisMonthValue / lastMonthValue)
            if progress == Float.infinity { progress = 0 }
            progressMonth?.progress = progress
            labelProgressMonth?.text = String(format: progressFormat, Int(progress * 100))
        }
    }
    
    var lastMonthValue: Double = 0.0 {
        didSet {
            labelLastMonthDistance?.text = String(format:self.distanceFormat, lastMonthValue, unit)
            var progress = Float(thisMonthValue / lastMonthValue)
            if progress == Float.infinity { progress = 0 }
            progressMonth?.progress = progress
            labelProgressMonth?.text = String(format: progressFormat, Int(progress * 100))
        }
    }
    
    var thisYearValue: Double = 0.0 {
        didSet {
            labelThisYearDistance?.text = String(format:self.distanceFormat, thisYearValue, unit)
            var progress = Float(thisYearValue / lastYearValue)
            if progress == Float.infinity { progress = 0 }
            progressYear?.progress = progress
            labelProgressYear?.text = String(format: progressFormat, Int(progress * 100))
        }
    }
    
    var lastYearValue: Double = 0.0 {
        didSet {
            labelLastYearDistance?.text = String(format:self.distanceFormat, lastYearValue, unit)
            var progress = Float(thisYearValue / lastYearValue)
            if progress == Float.infinity { progress = 0 }
            progressYear?.progress = progress
            labelProgressYear?.text = String(format: progressFormat, Int(progress * 100))
        }
    }
    
    var totalValue: Double = 0.0 {
        didSet {
            labelTotalDistance?.text = String(format:distanceFormat, totalValue, unit)
        }
    }
    
    override func viewDidLoad() {
        labelUnit.text = self.unit
        labelTitle.text = self.activityTitle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateValues()
    }

    func updateValues() {
        let calendar = Calendar.current
        let now = Date()
        let startThisMonthComponents = calendar.dateComponents(Set([.year, .month]), from: now)
        let startThisMonth = calendar.date(from: startThisMonthComponents)!
        let endThisMonth = calendar.date(byAdding: .month, value: 1, to: startThisMonth)!
        let startLastMonth = calendar.date(byAdding: .month, value: -1, to: startThisMonth)!
        
        let startThisYearComponents = calendar.dateComponents(Set([.year]), from: now)
        let startThisYear = calendar.date(from: startThisYearComponents)!
        let startLastYear = calendar.date(byAdding: .year, value: -1, to: startThisYear)!
        
        let begginingOfRecords = Date(timeIntervalSince1970: 0)
        
        let mapping = [
            (startThisMonth, endThisMonth, {res in self.thisMonthValue = res}),
            (startLastMonth, startThisMonth, {res in self.lastMonthValue = res}),
            (startThisYear, endThisMonth, {res in self.thisYearValue = res}),
            (startLastYear, startThisYear, {res in self.lastYearValue = res}),
            (begginingOfRecords, endThisMonth, {res in self.totalValue = res})
        ]
        
        for (startDate, endDate, cb) in mapping {
            queryValues(from: startDate, to: endDate, completion: cb)
        }
    }
    
    func queryValues(from: Date, to: Date, completion: @escaping (_ result: Double)->()){
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: HKObjectType.quantityType(forIdentifier: quantity!)!,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum){ query, result, error in
                DispatchQueue.main.async {
                    completion((result?.sumQuantity()?.doubleValue(for: self.unitType!))! / Double(self.unitFactor))
                }
        }
        
        healthStore!.execute(query)
    }

}

