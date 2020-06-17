//
//  Model.swift
//  findWeather
//
//  Created by Kein-chronicle on 2020/04/22.
//  Copyright © 2020 kimjinwan. All rights reserved.
//

import Foundation
import Alamofire

extension ViewController {
    func requestWather(location:String, date:String) {
        AF.request("https://www.metaweather.com/api/location/\(location)/\(date)/", method: .get).responseJSON { response in
            guard let getData = response.value as? Array<Any> else {
                return
            }
            self.targetLocations[location]?.updateValue(getData[0], forKey: date)
            
            NotificationCenter.default.post(name: NSNotification.Name("getWeatherData"), object: nil)
        }
    }
}
