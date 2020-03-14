 //
 //  ViewController.swift
 //  WeatherTheStorms
 //
 //  Created by Michael Kucinski on 3/12/20.
 //  Copyright © 2020 Michael Kucinski. All rights reserved.
 //
 
 /*
  
  My plan :
  
  Get the devices current latitude and longtitude to get the current location.  Then query the Weather site using latitude and longitude for the appropriate data.
  
  I consider each grouping of the forecast weather data in the UITextView as rows for this solution.  Use of a UITextView enables easy scrolling and viewing of the data.  And it allows you to show each items data with larger text.  Trying to display all the text and the image on one line would make the font harder to read.
  
  I interpret the instuctions as indicating we should show either the current temperature, or the 5 day forecast.
  
  I'll figure out how I want to show the current temp when I see what the data format looks like.  Update :  Now that I've seen it, I thought it would be nice to add some useful information to the temperature display so that the temperature doesn't look lonely all by itself.
  
  Note that I left some notes and I commented out print statements in the delivered code.  I learned some things in getting this app to work.   Being able to review my notes and print statements later if I need to will be beneficial to me.
  
  I found a beautifier for raw json data : https://jsonformatter.curiousconcept.com
  
  Note that I chose a background color of green because all of the icons downloaded stood out well against the green backdrop.  Other colors I tried made it more difficult to see the icons.
  
  I used a toolbar up top as a way to choose between the desired data.
  
  I used an extension to spin the fetching data message.  See the Extension file.
  
  I included test objects/folders when I created the project, but I didn't populate them with any code.
  
  There is one build warning.  I create a 60 cycle timer.  The timer never needs to be read once it is created. The warning just informs you that the timer never gets read.
  
  Finally, I implemented the anyControlsBreakpoint breakpoint in this app.  I described this Pedro when I talked with him on the phone a few days ago.  It is at the very end of the file.  If you set a breakpoint insidee of anyControlsBreakpoint, then it will get hit when the toolbar is touched on the left or the right.
  */
 
 import UIKit
 import CoreLocation
 
 class ViewController: UIViewController, UITextViewDelegate, CLLocationManagerDelegate {
    
    var toolbar1:UIToolbar?
    var totalFramesSinceStarting = 0
    var lastFrameWhenAUserTouchOccurred = 0
    var countOfURLRequest = 0 // Just want to count them is all, may help debug
    
    var locationHasBeenUpdatedAtLeastOnce = false
    var newTemperatureDataIsReadyForDisplay = false
    var getIconsDesiredNow = false
    
    var latitudeString = ""
    var longitudeString = ""
    var contentStringForOurTextView = "''"
    
    var ourTextView = UITextView()
    var fetchingDataView = UITextView()
    
    var screenCenterPoint : CGPoint = CGPoint(x:-1,y:-1) // Init later
    
    let imageView = UIImageView()
    
    var forecastTimeArray = [NSAttributedString]()
    var forecastTempArray = [NSAttributedString]()
    var forecastIconIndicatorArray = [String]()
    
    var numberOfItemsToDisplayAsInt : Int = 0
    
    var attributFont = UIFont.systemFont(ofSize: 28)
    
    //let shadow = NSShadow() // this may be useful on next project
    
    var desiredAttributes: [NSAttributedString.Key: Any] = [:]
    
    let locationManager = CLLocationManager() // create Location Manager object
    var latitude : Double?
    var longitude : Double?
    
    var deviceScaleFactor : CGFloat = 1.0
    var fullScreenY_AsFloat : CGFloat = 0;
    var fullScreenX_AsFloat : CGFloat = 0;
    
    let screenRect = UIScreen.main.bounds
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        ourTextView.frame = self.view.bounds
        ourTextView.layer.masksToBounds = true
        
        fullScreenX_AsFloat = CGFloat(Int(screenRect.size.width))
        fullScreenY_AsFloat = CGFloat(Int(screenRect.size.height))
        
        screenCenterPoint =  CGPoint(x:fullScreenX_AsFloat/2,y:fullScreenY_AsFloat/2)
        
        deviceScaleFactor = fullScreenY_AsFloat / 1024.0
        
        ourTextView.textAlignment = NSTextAlignment.justified
        ourTextView.backgroundColor = UIColor.green
        ourTextView.textColor = UIColor.blue
        ourTextView.layer.borderColor = UIColor.cyan.cgColor
        ourTextView.layer.borderWidth = 33
        ourTextView.isEditable = false
        ourTextView.text = ""
        ourTextView.alpha = 1
        ourTextView.font = UIFont.systemFont(ofSize: 24 * deviceScaleFactor)
        let insetValue : CGFloat = 40.0
        ourTextView.textContainerInset = UIEdgeInsets(top: insetValue, left: insetValue, bottom: insetValue, right: insetValue)
        self.view.addSubview(ourTextView)
        
        fetchingDataView.frame = CGRect(x:0, y:0, width:250  * deviceScaleFactor, height:50  * deviceScaleFactor)
        fetchingDataView.layer.masksToBounds = true
        fetchingDataView.textAlignment = NSTextAlignment.justified
        fetchingDataView.backgroundColor = UIColor.yellow
        fetchingDataView.textColor = UIColor.blue
        fetchingDataView.isEditable = false
        fetchingDataView.layer.cornerRadius = 25 * deviceScaleFactor
        fetchingDataView.clipsToBounds = true
        fetchingDataView.textAlignment = .center
        fetchingDataView.text = "Fetching data"
        fetchingDataView.font = UIFont.systemFont(ofSize: 26 * deviceScaleFactor)
        fetchingDataView.center = screenCenterPoint
        fetchingDataView.startRotating(duration: 5, clockwise: true)
        self.view.addSubview(fetchingDataView)
        
        let yValueForToolbarThatIsBelowTheNotch : CGFloat = 32
        
        // Createtoolbar1:
        let frame = CGRect(x: 0, y: yValueForToolbarThatIsBelowTheNotch, width: UIScreen.main.bounds.size.width, height: 54)
        toolbar1 = UIToolbar(frame: frame)
        self.view.addSubview(toolbar1!)
        self.toolbar1?.isTranslucent = false
        
        toolbar1?.tintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        toolbar1?.barTintColor = .blue
        
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem:.flexibleSpace , target: self, action: nil)
        let button_1 = UIBarButtonItem(image: UIImage(named: ""), style: .plain, target: self, action:#selector(get5DayForecastData))
        let button_2 = UIBarButtonItem(image: UIImage(named: ""), style: .plain, target: self, action:#selector(getCurrentTemperature))
        
        button_1.title = "5 Day Temperatures"
        button_2.title = "Current Temperature"
        
        var items = [UIBarButtonItem]()
        items.append(button_2)
        items.append(flexibleSpacer)
        items.append(button_1)
        
        toolbar1?.items = items
        toolbar1?.isHidden = false
        
        // 60 cycle timer
        var timer = Timer(timeInterval: 1.0/60.0, repeats: true) { _ in print("Done!") }
        
        // start the timer
        timer = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(handleTimerEvent), userInfo: nil, repeats: true)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // Also update the .plist file to request the authorization
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // Save for next project maybe ...
        //shadow.shadowColor = UIColor.red
        //shadow.shadowBlurRadius = 5
        
        attributFont = UIFont.systemFont(ofSize: 24 * deviceScaleFactor)
        
        desiredAttributes = [
            .font: attributFont,
            .foregroundColor: UIColor.blue,
            //.shadow: shadow
        ]
        
    } // ends viewDidLoad
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        // set the value of lat and long
        latitude = location.latitude
        longitude = location.longitude
        
        //print("totalFramesSinceStarting = \(totalFramesSinceStarting) ")
        //print("latitude = \(String(describing: latitude)) ")
        //print("longitude = \(String(describing: longitude)) ")
        
        latitudeString = "\(latitude ?? 0)"
        longitudeString = "\(longitude ?? 0)"
        
        //print(latitudeString)
        //print(longitudeString)
        
        locationHasBeenUpdatedAtLeastOnce = true
    }
    
    @objc func handleTimerEvent() {
                
        totalFramesSinceStarting += 1 // Keep a running count of total frames
        
        // Check for things to do

        if locationHasBeenUpdatedAtLeastOnce && countOfURLRequest == 0
        {
            getCurrentTemperature()
            
            fetchingDataView.alpha = 0
        }
        
        if newTemperatureDataIsReadyForDisplay
        {
            newTemperatureDataIsReadyForDisplay.toggle()
            
            ourTextView.text = contentStringForOurTextView
            ourTextView.font = UIFont.systemFont(ofSize: 24 * deviceScaleFactor)
            
            // Hide the spinning fetching message
            fetchingDataView.alpha = 0
        }
        
        if getIconsDesiredNow
        {
            getIconsDesiredNow.toggle()
            
            let fullString = NSMutableAttributedString(string: "\n\n\n\n", attributes: desiredAttributes)
            
            for thisTimePeriod in 0...(numberOfItemsToDisplayAsInt - 1)
            {
                if thisTimePeriod < forecastTimeArray.count {
                    fullString.append(forecastTimeArray[thisTimePeriod])
                }
                
                var appendItem = NSMutableAttributedString(string: "\nForecast Temperature   ", attributes: desiredAttributes)
                
                fullString.append(appendItem)
                
                if thisTimePeriod < forecastTempArray.count {
                    fullString.append(forecastTempArray[thisTimePeriod])
                }
                
                appendItem = NSMutableAttributedString(string: " °F\n", attributes: desiredAttributes)
                
                fullString.append(appendItem)
                
                // Build URL string to get the correct icon
                
                var iconURL = "https://openweathermap.org/img/wn/"
                var iconString = " "
                if thisTimePeriod < forecastIconIndicatorArray.count {
                    iconString = forecastIconIndicatorArray[thisTimePeriod]
                }
                iconURL += iconString
                iconURL += "@2x.png"
                
                let url = URL(string: iconURL)
                let data = try? Data(contentsOf: url!)
                imageView.image = UIImage(data: data!)
                
                // create our NSTextAttachment
                let image1Attachment = NSTextAttachment()
                image1Attachment.image = imageView.image
                
                // wrap the attachment in its own attributed string so we can append it
                let image1String = NSAttributedString(attachment: image1Attachment)
                
                // add the NSTextAttachment wrapper to our full string, then add some more text.
                fullString.append(image1String)
                
                // Add some spacing between rows
                appendItem = NSMutableAttributedString(string: "\n\n", attributes: desiredAttributes)
                
                fullString.append(appendItem)
            }
            
            ourTextView.attributedText = fullString
            
            // Hide the spinning fetching message
            fetchingDataView.alpha = 0
        }
        
    } // ends handleTimerEvent
    
    @objc func get5DayForecastData()
    {
        /*
         get5DayForecastData will normally be called due to a toolbar touch.
         
         A toolbar touch is a screen input.  First, call the simple breakpoint routine so that if we desire we can break here.  On breakpoint, we can then bubble up the call tree to find the handler.  That makes maintenance more easy.  Note that anyControlsBreakpoint gets called once when the location data is first updated.  No harm in having the breakpoint available for that case.
         */
        
        anyControlsBreakpoint()
        
        // Show the spinning fetching message
        fetchingDataView.alpha = 1
        
        // Clear the screen
        ourTextView.text = ""
        
        if locationHasBeenUpdatedAtLeastOnce
        {
            countOfURLRequest += 1
            
            var buildStringForURL = "https://api.openweathermap.org/data/2.5/forecast?"
            buildStringForURL += "lat="
            buildStringForURL += latitudeString
            buildStringForURL += "&lon="
            buildStringForURL += longitudeString
            buildStringForURL += "&APPID=3af89fd995e671dfb872b5662afa558a"
            buildStringForURL += "&units=imperial" // Specify Fahrenheit
            
            if let objurl = URL(string: buildStringForURL)
            {
                print(objurl)
                
                let task = URLSession.shared.dataTask(with: objurl) { (data, response, error) in
                    if let error = error {
                        // We got some kind of error while trying to get data from the server.
                        print("Error:\n\(error)")
                    }
                    else
                    {
                        // We got a response from the server!
                        do {
                            // Try to convert that data into a Swift dictionary
                            let forecast = try JSONSerialization.jsonObject(
                                with: data!,
                                options: .mutableContainers) as! [String: AnyObject]
                            
                            //print(forecast)
                            
                            // If we made it to this point, we've successfully converted the JSON-formatted weather data into a Swift dictionary.
                            
                            print("Count: \(forecast["cnt"]!)")
                            
                            let numberOfItemsToDisplay = forecast["cnt"]!
                            
                            self.numberOfItemsToDisplayAsInt = numberOfItemsToDisplay as! Int
                            
                            print(numberOfItemsToDisplay)
                            
                            //var thisList = forecast["list"]!
                            //print(thisList)
                            
                            // Get past the notch (for iPhone)
                            self.contentStringForOurTextView = "\n\n\n\n"
                            
                            for thisTimePeriod in 0...(self.numberOfItemsToDisplayAsInt - 1)
                            {
                                let thisListElement = forecast["list"]?.object(at: thisTimePeriod)
                                
                                //  print(thisListElement!)
                                //  print(thisListElement)
                                
                                guard let elementItems = thisListElement as? [String:Any] else { return }
                                
                                let timeText = elementItems["dt_txt"]  as! String
                                
                                let timeAttributedString = NSMutableAttributedString(string: timeText, attributes: self.desiredAttributes)
                                
                                self.forecastTimeArray.append(timeAttributedString)
                                
                                //print(timeText)
                                
                                self.contentStringForOurTextView += timeText
                                self.contentStringForOurTextView += "\n"
                                
                                let mainText = elementItems["main"]  as Any
                                
                                //print(mainText)
                                
                                guard let mainItems = mainText as? [String:Any] else { return }
                                
                                let temperatureText = mainItems["temp"]  as! Float64
                                
                                //print(temperatureText)
                                
                                let temperatureTextAsString = NSString(format: "%.2f", temperatureText)
                                
                                let newString : String = temperatureTextAsString as String
                                
                                let temperatureAttributedString = NSMutableAttributedString(string: newString, attributes: self.desiredAttributes)
                                self.forecastTempArray.append(temperatureAttributedString)
                                
                                self.contentStringForOurTextView += "Forecast Temperature   "
                                
                                self.contentStringForOurTextView += temperatureTextAsString as String
                                
                                self.contentStringForOurTextView += " °F\n"
                                
                                let weatherText = elementItems["weather"]  as! NSArray
                                
                                print(weatherText)
                                
                                let thisWeatherElement = weatherText[0]
                                
                                print(thisWeatherElement)
                                
                                guard let weatherItems = thisWeatherElement as? [String:Any] else
                                {
                                    return
                                }
                                
                                let iconText = weatherItems["icon"]  as! String
                                
                                print(iconText)
                                
                                self.forecastIconIndicatorArray.append(iconText)
                                
                                self.forecastIconIndicatorArray.append(iconText as String)
                                
                                self.contentStringForOurTextView += "Forecast Icon  :   "
                                
                                self.contentStringForOurTextView += iconText
                                
                                self.contentStringForOurTextView += "  \n\n"
                            }
                            
                            // Note we can't write the UITextView.text from here, it has to be done on the main thread.  Just set this flag now :
                            
                            self.getIconsDesiredNow = true
                        }
                        catch let jsonError as NSError {
                            // An error occurred while trying to convert the data into a Swift dictionary.
                            print("JSON error description: \(jsonError.description)")
                        }
                    }
                }
                task.resume()
                
            } // ends if let objurl = URL(string: buildStringForURL)
        }
    } // ends get5DayForecastData
    
    @objc func getCurrentTemperature()
    {
        /*
         getCurrentTemperature will normally be called due to a toolbar touch.
         
         However, I set it up to get called when the first location data comes in so the app can immediately display the temperature at the current location.
         
         A toolbar touch is a screen input.  First, call the simple breakpoint routine so that if we desire we can break here.  On breakpoint, we can then bubble up the call tree to find the handler.  That makes maintenance more easy.  Note that anyControlsBreakpoint gets called once when the location data is first updated.  No harm in having the breakpoint available for that case.
         */
        
        anyControlsBreakpoint()
        
        // Show the spinning fetching message
        fetchingDataView.alpha = 1
        
        // Clear the screen
        ourTextView.text = ""
        
        countOfURLRequest += 1
        
        var buildStringForURL = "https://api.openweathermap.org/data/2.5/weather?"
        buildStringForURL += "lat="
        buildStringForURL += latitudeString
        buildStringForURL += "&lon="
        buildStringForURL += longitudeString
        buildStringForURL += "&APPID=3af89fd995e671dfb872b5662afa558a"
        buildStringForURL += "&units=imperial" // Specify Fahrenheit
        
        if let objurl = URL(string: buildStringForURL)
        {
            print(objurl)
            
            let task = URLSession.shared.dataTask(with: objurl) { (data, response, error) in
                if let error = error {
                    // We got some kind of error while trying to get data from the server.
                    print("Error:\n\(error)")
                }
                else
                {
                    // We got a response from the server!
                    do {
                        // Try to convert that data into a Swift dictionary
                        let weather = try JSONSerialization.jsonObject(
                            with: data!,
                            options: .mutableContainers) as! [String: AnyObject]
                        
                        // If we made it to this point, we've successfully converted the JSON-formatted weather data into a Swift dictionary.
                        
                        // Let's print some of its contents to the debug console.
                        print("Date and time: \(weather["dt"]!)")
                        print("City: \(weather["name"]!)")
                        
                        print("Longitude: \(weather["coord"]!["lon"]!!)")
                        print("Latitude: \(weather["coord"]!["lat"]!!)")
                        
                        print("Temperature: \(weather["main"]!["temp"]!!)")
                        print("Humidity: \(weather["main"]!["humidity"]!!)")
                        print("Pressure: \(weather["main"]!["pressure"]!!)")
                        
                        print("Cloud cover: \(weather["clouds"]!["all"]!!)")
                        
                        print("Wind direction: \(weather["wind"]!["deg"]!!) degrees")
                        print("Wind speed: \(weather["wind"]!["speed"]!!)")
                        
                        print("Country: \(weather["sys"]!["country"]!!)")
                        print("Sunrise: \(weather["sys"]!["sunrise"]!!)")
                        print("Sunset: \(weather["sys"]!["sunset"]!!)")
                        
                        // Now lets build the temperature and other data for display
                        // Note we can't write the UITextView.text from here, it has to be done on the main thread.  So store it's contents now.
                        self.contentStringForOurTextView = "\n\n\n\nTemperature : \(weather["main"]!["temp"]!!)"
                        self.contentStringForOurTextView += "  °F\n\n"
                        self.contentStringForOurTextView += "City : \(weather["name"]!)"
                        self.contentStringForOurTextView += "\n\n"
                        self.contentStringForOurTextView += "Humidity : \(weather["main"]!["humidity"]!!)"
                        self.contentStringForOurTextView += "  percent\n\n"
                        self.contentStringForOurTextView += "Pressure : \(weather["main"]!["pressure"]!!)"
                        self.contentStringForOurTextView += "  millibars\n\n"
                        
                        // I noticed sometimes the wind speed was displaying a lot of digits after the decimal point.  So I clipped it to no digits after the decimal and no decimal point.  No one ever cares about tenths or hundredsth, when concerning the wind anyway.
                        let tempWindSpeed = weather["wind"]!["speed"]!! as! CGFloat
                        let tempWindSpeedString = NSString(format: "%.0f", tempWindSpeed)
                        
                        self.contentStringForOurTextView += "Wind speed : "
                        self.contentStringForOurTextView += tempWindSpeedString as String
                        
                        self.contentStringForOurTextView += "  mph\n\n"
                        
                        self.newTemperatureDataIsReadyForDisplay = true
                    }
                    catch let jsonError as NSError {
                        // An error occurred while trying to convert the data into a Swift dictionary.
                        print("JSON error description: \(jsonError.description)")
                    }
                }
            }
            task.resume()
            
        } // ends if let objurl = URL(string: buildStringForURL)
        
    } // ends getCurrentTemperature
    
    // Keep this breakpoint routine at the end of the file so it is easy to find.
    @objc func anyControlsBreakpoint()
    {
        lastFrameWhenAUserTouchOccurred = totalFramesSinceStarting
        
    } // ends anyControlsBreakpoint
    
 }
 
