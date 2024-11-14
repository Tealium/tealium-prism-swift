//
//  ViewController.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/2022.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import UIKit

class ViewController: UIViewController {

    var teal: Tealium? {
        TealiumHelper.shared.teal
    }
    var automaticDisposer = AutomaticDisposer()
    let btnStartStop = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        TealiumSignposter.enabled = true
        _ = ConnectivityMonitor.shared
            .connection.asObservable()
            .subscribeOn(TealiumQueue.worker)
            .subscribe { connection in
                print("New Connection: \(connection)")
            }
        // Do any additional setup after loading the view, typically from a nib.
        
        initTeal()
//        teal.track(TealiumDispatch(name: "asd", data: ["some":"data"]))
        
        
        btnStartStop.backgroundColor = .black
        view.addSubview(btnStartStop)
        btnStartStop.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btnStartStop.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        btnStartStop.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btnStartStop.widthAnchor.constraint(equalToConstant: 180).isActive = true
        btnStartStop.translatesAutoresizingMaskIntoConstraints = false
        btnStartStop.addTarget(self, action: #selector(initTeal), for: .touchUpInside)
        
        let btnTrace = UIButton()
        btnTrace.backgroundColor = .purple
        view.addSubview(btnTrace)
        btnTrace.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btnTrace.topAnchor.constraint(equalTo: btnStartStop.bottomAnchor, constant: 20).isActive = true
        btnTrace.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btnTrace.widthAnchor.constraint(equalToConstant: 180).isActive = true
        
        btnTrace.translatesAutoresizingMaskIntoConstraints = false
        btnTrace.setTitle("Join Trace", for: .normal)
        btnTrace.addTarget(self, action: #selector(joinTrace), for: .touchUpInside)
    
        let btnDeepLink = UIButton()
        btnDeepLink.backgroundColor = .green
        view.addSubview(btnDeepLink)
        btnDeepLink.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btnDeepLink.topAnchor.constraint(equalTo: btnTrace.bottomAnchor, constant: 20).isActive = true
        btnDeepLink.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btnDeepLink.widthAnchor.constraint(equalToConstant: 180).isActive = true
        
        btnDeepLink.translatesAutoresizingMaskIntoConstraints = false
        btnDeepLink.setTitle("Deeplink", for: .normal)
        btnDeepLink.addTarget(self, action: #selector(deepLink), for: .touchUpInside)
        
        let btnAddToDataLayer = UIButton()
        btnAddToDataLayer.backgroundColor = .blue
        view.addSubview(btnAddToDataLayer)
        btnAddToDataLayer.translatesAutoresizingMaskIntoConstraints = false
        btnAddToDataLayer.setTitle("Add to datalayer", for: .normal)
        btnAddToDataLayer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btnAddToDataLayer.topAnchor.constraint(equalTo:  btnDeepLink.bottomAnchor, constant: 20).isActive = true
        btnAddToDataLayer.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btnAddToDataLayer.widthAnchor.constraint(equalToConstant: 180).isActive = true
        btnAddToDataLayer.addTarget(self, action: #selector(addToDataLayer), for: .touchUpInside)
    }
    
    @objc func joinTrace() {
        teal?.trace.join(id: "something")
        
        teal?.track("joined!")
    }
    
    @objc func deepLink() {
        teal?.deepLink.handle(link: URL(string: "https://www.tealium.com")!)
        
        teal?.track("DeepLink!") {dispatch,result in
            print("Dispatch: \(dispatch)")
            print("Result: \(result)")
        }
    }
    
    @objc func addToDataLayer() {
        teal?.dataLayer.put(data: ["key1": "value1"])
    }

    @objc func initTeal() {
        guard teal == nil else {
            TealiumHelper.shared.stopTealium()
            automaticDisposer = AutomaticDisposer()
            btnStartStop.setTitle("Reinit Tealium", for: .normal)
            return
        }
        btnStartStop.setTitle("Stop Tealium", for: .normal)
        TealiumHelper.shared.startTealium()
        teal?.onReady { teal in
            teal.dataLayer.onDataUpdated.subscribe { updated in
                print("some data updated: \(updated)")
            }.addTo(self.automaticDisposer)
            teal.dataLayer.onDataRemoved.subscribe { removed in
                print("some data removed: \(removed)")
            }.addTo(self.automaticDisposer)
            teal.dataLayer.put(data: ["1": "1", "2":"2", "3": "3", "nsnumber": NSNumber(67)])
//            teal.dataLayer.add(data: ["4": "4", "5":"5", "6": "6"])
            teal.dataLayer.put(data: ["myTimestamp": Date().timeIntervalSince1970], expiry: .untilRestart)
            teal.dataLayer.remove(keys: ["1", "3", "5"])
            teal.track("something")
            teal.track("something2", data: ["some":"data"])
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

