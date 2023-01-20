//
//  ViewController.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/05/2022.
//  Copyright (c) 2022 Tyler Rister. All rights reserved.
//

import tealium_swift
import UIKit

class ViewController: UIViewController {

    var teal: Tealium!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        initTeal()
        teal.track(TealiumDispatch(name: "asd", data: ["some":"data"]))
        print("nothing")
        
        let btn = UIButton()
        btn.backgroundColor = .black
        view.addSubview(btn)
        btn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btn.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btn.widthAnchor.constraint(equalToConstant: 180).isActive = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Reinit Tealium", for: .normal)
        btn.addTarget(self, action: #selector(initTeal), for: .touchUpInside)
        
        let btnTrace = UIButton()
        btnTrace.backgroundColor = .purple
        view.addSubview(btnTrace)
        btnTrace.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btnTrace.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: -20).isActive = true
        btnTrace.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btnTrace.widthAnchor.constraint(equalToConstant: 180).isActive = true
        
        btnTrace.translatesAutoresizingMaskIntoConstraints = false
        btnTrace.setTitle("Join Trace", for: .normal)
        btnTrace.addTarget(self, action: #selector(joinTrace), for: .touchUpInside)
    
        let btnDeepLink = UIButton()
        btnDeepLink.backgroundColor = .purple
        view.addSubview(btnDeepLink)
        btnDeepLink.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        btnDeepLink.topAnchor.constraint(equalTo: btnTrace.bottomAnchor, constant: -20).isActive = true
        btnDeepLink.heightAnchor.constraint(equalToConstant: 80).isActive = true
        btnDeepLink.widthAnchor.constraint(equalToConstant: 180).isActive = true
        
        btnDeepLink.translatesAutoresizingMaskIntoConstraints = false
        btnDeepLink.setTitle("Deeplink", for: .normal)
        btnDeepLink.addTarget(self, action: #selector(deepLink), for: .touchUpInside)
        
    }
    
    @objc func joinTrace() {
        teal.trace.join(id: "something")
        
        teal.track(TealiumDispatch(name: "joined!", data: nil))
    }
    
    @objc func deepLink() {
        teal.deepLink.handle(link: URL(string: "https://www.tealium.com")!)
        
        teal.track(TealiumDispatch(name: "DeepLink!", data: nil))
    }

    @objc func initTeal() {
        let modules: [TealiumModule.Type] = [
            TealiumCollect.self,
            AppDataCollector.self
        ]
        let config = TealiumConfig(modules: modules,
                                   configFile: "TealiumConfig",
                                   configUrl: nil)
        let teal = Tealium(config)
        self.teal = teal
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

