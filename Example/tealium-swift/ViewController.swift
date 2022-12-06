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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let teal = Tealium(CoreConfig(modules: [TealiumCollect.self], coreDictionary: [:]))
        
        teal.track(TealiumDispatch(name: "asd", data: ["some":"data"]))
        print("nothing")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

