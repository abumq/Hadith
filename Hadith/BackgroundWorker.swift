//
//  BackgroundWorker.swift
//  Hadith
//
//  Created by Majid Khan on 22/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class BackgroundWorker {
    let queue : dispatch_queue_t!

    required init() {
        queue =  dispatch_queue_create("background-worker", DISPATCH_QUEUE_SERIAL)
    }
    
    func startInMainQueue(task: (() -> ())?) {
        dispatch_async(dispatch_get_main_queue(), { task?() })
    }
    
    func start(task: () -> (), completion: () -> ()) {
        self.startAfter(task: task, completion: completion)
    }
    
    func startAfter(delayInMs: Double = 0.0, task: () -> (), completion: () -> ()) {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInMs * Double(NSEC_PER_SEC)))
        dispatch_after(delay, self.queue) {
            task()
            dispatch_async(dispatch_get_main_queue(), completion)
        }
    }
    
    // MARK: Singleton
    struct Static {
        static var instance:BackgroundWorker? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> BackgroundWorker! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }
    
}

infix operator ~> {}

func ~> (task: () -> (), completion: () -> ()) {
    BackgroundWorker.sharedInstance().start(task, completion: completion)
}