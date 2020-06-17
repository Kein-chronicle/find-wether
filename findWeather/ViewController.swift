//
//  ViewController.swift
//  findWeather
//
//  Created by Kein-chronicle on 2020/04/22.
//  Copyright © 2020 kimjinwan. All rights reserved.
//

import UIKit
import SnapKit
import FLAnimatedImage
import Nuke

class ViewController: UIViewController {

    // datas
    var targetLocations:Dictionary<String, Dictionary<String,Any>> = [
        "1132599" : [:], // Seoul
        "44418" : [:], // London
        "2379574" : [:] // Chicago
    ]
    
    let targetNameLocations:Array<String> = [
        "Seoul",
        "London",
        "Chicago"
    ]
    
    var targetDates:Array<String> = []
    
    var targetDateCounts = 7
    
    // tables
    var _tableView = UITableView()
    let tableViewCellId = "weatherTableViewCellId"
    private var refreshControl = UIRefreshControl()
    
    // strunct
    struct wether {
        let name : String
        let img : String
        let max : Double
        let min : Double
        init(data : [String:Any]) {
            name = data["weather_state_name"] as? String ?? "Now loading"
            img = data["weather_state_abbr"] as? String ?? "Now loading"
            max = data["max_temp"] as? Double ?? 0
            min = data["min_temp"] as? Double ?? 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 7일치 날짜 만들기
        targetDateSet(targetDateCounts)
        
        // 테이블뷰 기본 셋팅
        setTable()
        
        // 데이터 콜 시작
        weatherDataCall()
        
        NotificationCenter.default.addObserver(self, selector: #selector(getWeatherData), name: NSNotification.Name("getWeatherData"), object: nil)
        
    }
    
    @objc func weatherDataCall() {
        for (targetLocation, _) in targetLocations {
            for targetDate in targetDates {
                requestWather(location: targetLocation, date: targetDate)
            }
        }
    }
    
    @objc func getWeatherData() {
        var checkCount = 0
        for (_, arr) in targetLocations {
            checkCount += arr.count
        }
        
        self.reloadTable()
        self.refreshControl.endRefreshing()
    }

    

}

// setting parts
extension ViewController {
    // 날짜들 배열로 만들기
    func targetDateSet(_ max : Int) {
        for i in 0 ..< max {
            let dataString = fomatChanger(Date() + Double(24 * 60 * 60 * i))
            targetDates.append(dataString)
            for (targetLocation, _) in targetLocations {
                self.targetLocations[targetLocation]?.updateValue([:], forKey: dataString)
            }
        }
    }
    
    // fomatter 1
    func fomatChanger(_ date: Date) -> String {
        let fomatter = DateFormatter()
        fomatter.locale = Locale(identifier: "ko_kr")
        fomatter.timeZone = TimeZone(abbreviation: "KST")
        fomatter.dateFormat = "yyyy/MM/dd"
        let strDate = fomatter.string(from: date)
        
        return strDate
    }
    
    func setTable() {
        _tableView = UITableView()
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.separatorStyle = .none
        refreshControl.addTarget(self, action: #selector(weatherDataCall), for: .valueChanged)
        _tableView.refreshControl = refreshControl
        _tableView.allowsMultipleSelection = true
        _tableView.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCellId)
        _tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalTo(view.safeAreaLayoutGuide)
            make.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
}


// table parts
extension ViewController:UITableViewDelegate, UITableViewDataSource {
    
    func reloadTable() {
        DispatchQueue.main.async {
            self._tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return targetNameLocations.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var checkCount = 0
        var i = 0
        for (_, arr) in targetLocations {
            if section == i {
                checkCount += arr.count
            }
            i += 1
        }
        return checkCount
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = targetNameLocations[section]
        let wrap = UIView()
        wrap.backgroundColor = .white
        wrap.frame = CGRect(x: 10, y: 0, width: view.frame.width - 100, height: 50)
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 23)
        label.text = title
        label.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(wrap)
            make.left.equalTo(wrap).offset(10)
            make.width.equalTo(wrap)
            make.height.equalTo(wrap)
        }
        if section != 0 {
            let gap = UIView()
            gap.backgroundColor = .black
            gap.translatesAutoresizingMaskIntoConstraints = false
            wrap.addSubview(gap)
            gap.snp.makeConstraints { (make) in
                make.top.equalTo(wrap)
                make.left.equalTo(wrap)
                make.right.equalTo(wrap)
                make.height.equalTo(2)
            }
        }
        
        let gap2 = UIView()
        gap2.backgroundColor = .black
        gap2.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(gap2)
        gap2.snp.makeConstraints { (make) in
            make.bottom.equalTo(wrap)
            make.left.equalTo(wrap)
            make.right.equalTo(wrap)
            make.height.equalTo(2)
        }
        
        return wrap
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellId, for: indexPath) as UITableViewCell
        
        for view in cell.contentView.subviews {
            view.removeFromSuperview()
        }
        
        let content = cell.contentView
        
        let cellData = Array(targetLocations)[indexPath.section].value
        let cellDate = targetDates[indexPath.row]
        guard let dic = cellData[cellDate] as? [String:Any] else {
            return cell
        }
        let data = wether(data: dic)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from:cellDate)!
        
        let calendar = Calendar.current
        let monthNumber = calendar.component(.month, from: date)
        let weekDay = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        
        let monthName = DateFormatter().monthSymbols[monthNumber - 1]
        let weekDayName = DateFormatter().weekdaySymbols[weekDay - 1]

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        if indexPath.row < 2 {
            if indexPath.row == 0 {
                dateLabel.text = "Today"
            } else {
                dateLabel.text = "Tomorrow"
            }
        } else {
            dateLabel.text = "\(weekDayName) \(day) \(monthName)"
        }
        dateLabel.font = UIFont.systemFont(ofSize: 20)
        content.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(content).offset(10)
            make.left.equalTo(content).offset(10)
            make.width.equalTo(content).multipliedBy(0.5)
            make.height.equalTo(40)
        }
        
        let weImg = FLAnimatedImageView()
        weImg.translatesAutoresizingMaskIntoConstraints = false
        if data.img != "Now loading" {
            let weImgUrl = "https://www.metaweather.com/static/img/weather/png/64/\(data.img).png"
            Nuke.loadImage(with: URL(string: weImgUrl)!, into: weImg)
        }
        content.addSubview(weImg)
        weImg.snp.makeConstraints { (make) in
            make.bottom.equalTo(content).offset(-10)
            make.left.equalTo(content).offset(10)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        let weLabel = UILabel()
        weLabel.translatesAutoresizingMaskIntoConstraints = false
        weLabel.text = "\(data.name)"
        weLabel.font = UIFont.systemFont(ofSize: 15)
        content.addSubview(weLabel)
        weLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(content).offset(-10)
            make.left.equalTo(weImg.snp.right).offset(10)
            make.width.equalTo(content).multipliedBy(0.5)
            make.height.equalTo(20)
        }
        
        
        let tempLabel = UILabel()
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        if data.name != "Now loading" {
            tempLabel.text = "Max : \(Int(data.max))°C   Min : \(Int(data.min))°C"
        } else {
            tempLabel.text = "Max : -°C   Min : -°C"
        }
        tempLabel.textAlignment = .right
        tempLabel.font = UIFont.systemFont(ofSize: 20)
        content.addSubview(tempLabel)
        tempLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(content).offset(-10)
            make.right.equalTo(content).offset(-10)
            make.width.equalTo(content).multipliedBy(0.5)
            make.height.equalTo(40)
        }
        
        let gap = UIView()
        gap.backgroundColor = .gray
        gap.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(gap)
        gap.snp.makeConstraints { (make) in
            make.bottom.equalTo(content)
            make.left.equalTo(content)
            make.right.equalTo(content)
            make.height.equalTo(1)
        }
        
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}
