//
//  TealiumObservables.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 09/06/23.
//

import Foundation

public extension TealiumObservable {
    static func Callback(callback: @escaping (@escaping Observer) -> Void) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            var cancelled = false
            callback { res in
                if !cancelled {
                    observer(res)
                }
            }
            return TealiumSubscription {
                cancelled = true
            }
        }
    }
    
    static func Just(_ elements: Element...) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            for element in elements {
                observer(element)
            }
            return TealiumSubscription { }
        }
    }
}
