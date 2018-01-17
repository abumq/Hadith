//
//  DatabaseUpdateManager.swift
//  Hadith
//
//  Created by Majid Khan on 3/06/2016.
//  Copyright © 2016 Muflihun.com. All rights reserved.
//

import Foundation

class DatabaseUpdateManager : NSObject {
    
    private static let databaseUpdateSessionIdentifier = "com.muflihun.Hadith.DatabaseUpdateManager.Update"
    
    private static let metaInfoFileFormat = "meta.v%@.json"
    private static let urlBase = "http://rc.muflihun-contents.com/data/hadith.app/"
    private static let metaInfoVersionFilename = "version"
    static let badgeUpdateFreq = 15.0
    static let updateRemoteDatabaseMetaInfoInterval = 300.0
    
    var backgroundUpdateCompletedHandler : (() -> Void)?
    weak var delegate : DatabaseUpdateManagerDelegate?
    
    private lazy var session : NSURLSession = {
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(databaseUpdateSessionIdentifier)
        config.allowsCellularAccess = true
        return NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }()
    
    var databaseManager = DatabaseManager.sharedInstance()
    
    var metaInfoUrl : String {
        get {
            return String(DatabaseUpdateManager.urlBase + String(format: DatabaseUpdateManager.metaInfoFileFormat, Utils.appVersion))
        }
    }
    var metaInfoVersionUrl : String {
        get {
            return String(DatabaseUpdateManager.urlBase + DatabaseUpdateManager.metaInfoVersionFilename)
        }
    }
    private var queue : [String:DatabaseUpdateTask] = [:]
    private var failedList : [String:String] = [:]
    private var _updateLastChecked : UpdateLastCheckedSetting
    private var remoteDatabaseMetaInfoVersion : Int = 0
    private var localDatabaseMetaInfoVersion : Int = 0
    private var _remoteDatabaseMetaInfo : [String:DatabaseMetaInfo] = [:]
    private var remoteCheckTimer : NSTimer?
    private var remoteDatabaseMetaInfoDownloadTask : NSURLSessionDataTask? = nil
    private var autoUpdateDisabledTemporarily = false
    private lazy var remoteDatabaseMetaInfoDownloadSession : NSURLSession = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.allowsCellularAccess = true
        return NSURLSession(configuration: config, delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
    }()
    
    private lazy var thumbnailDownloadSession : NSURLSession = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.allowsCellularAccess = true
        return NSURLSession(configuration: config, delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
    }()
    var updateLastChecked : UpdateLastCheckedSetting {
        get {
            return self._updateLastChecked
        }
    }
    var remoteDatabaseMetaInfo : [String:DatabaseMetaInfo] {
        get {
            return self._remoteDatabaseMetaInfo
        }
    }
    
    struct Static {
        static var instance:DatabaseUpdateManager? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> DatabaseUpdateManager! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }
    
    override required init() {
        assert(Static.instance == nil, "DataUpdateManager already initialized!")
        self._updateLastChecked = UpdateLastCheckedSetting.load()
        super.init()
        // init lazy session
        _ = self.session
        self.remoteCheckTimer = NSTimer.scheduledTimerWithTimeInterval(DatabaseUpdateManager.updateRemoteDatabaseMetaInfoInterval, target: self, selector: #selector(DatabaseUpdateManager.updateRemoteDatabaseMetaInfo), userInfo: nil, repeats: true)
        self.remoteCheckTimer?.fire()
    }
    
    
    @objc private func updateRemoteDatabaseMetaInfo() {
        if self.remoteDatabaseMetaInfoDownloadTask != nil {
            return
        }
        let request = NSURLRequest(URL: NSURL(string: self.metaInfoVersionUrl)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
        self.remoteDatabaseMetaInfoDownloadTask = remoteDatabaseMetaInfoDownloadSession.dataTaskWithRequest(request, completionHandler: { data, response, err -> Void in
            if data != nil {
                let stringVersion = String(data: data!, encoding:NSUTF8StringEncoding)!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
                self.remoteDatabaseMetaInfoVersion = Int(stringVersion)!
                Log.write("Checked update [\(self.remoteDatabaseMetaInfoVersion)]")
                if (self.remoteDatabaseMetaInfoVersion > self.localDatabaseMetaInfoVersion) {
                    
                    let request = NSURLRequest(URL: NSURL(string: self.metaInfoUrl)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
                    self.remoteDatabaseMetaInfoDownloadTask = self.remoteDatabaseMetaInfoDownloadSession.dataTaskWithRequest(request, completionHandler: { data, response, err -> Void in
                        if data != nil {
                            Log.write("Remote JSON update")
                            
                            self._remoteDatabaseMetaInfo = [:]
                            for databaseMetaInfo in DatabaseMetaInfo.fromJsonArray(String(data: data!, encoding:NSUTF8StringEncoding)!) {
                                self._remoteDatabaseMetaInfo[databaseMetaInfo.id] = databaseMetaInfo
                            }
                            self._updateLastChecked.value = NSDate()
                            self._updateLastChecked.save()
                            self.localDatabaseMetaInfoVersion = self.remoteDatabaseMetaInfoVersion
                            self.remoteDatabaseMetaInfoDownloadTask = nil
                            
                            // We have new updates, we try to start auto update
                            self.startAutoUpdateIfPossible()
                        } // else no internet or some other issue? ignore!
                    })
                    self.remoteDatabaseMetaInfoDownloadTask?.resume()
                }
            } // else no internet so ignore

            self.remoteDatabaseMetaInfoDownloadTask = nil
        })
        self.remoteDatabaseMetaInfoDownloadTask?.resume()
    }
    
    
    private func processQueue() {
        for url in queue.keys {
            if let updateTask = queue[url] {
                if (updateTask.state == .NotUpdating) {
                    switch (updateTask.databaseMetaInfo!.updateType) {
                    case .Retired, .Remove:
                        removeVersion(updateTask)
                    case .Pending, .Available:
                        self.downloadVersion(updateTask)
                    case .Failed:
                        // Check for version and if updated, mark it as available
                        // and download
                        if (self.remoteDatabaseMetaInfoVersion == self.localDatabaseMetaInfoVersion) {
                            Log.write("Ignoring [\(updateTask.databaseMetaInfo!.id)] in update. It had previously failed and still no new version available")
                            self.queue[url] = nil
                        } else {
                            updateTask.databaseMetaInfo!.updateType = .Available
                            processQueue()
                        }
                    default: break
                    }
                }
            }
        }
    }
    
    func findStateById(id:String) -> DatabaseUpdateState? {
        if let metaInfo = findTaskById(id) {
            return metaInfo.state
        }
        return nil
    }
    
    func findTaskById(id:String) -> DatabaseUpdateTask? {
        for metaInfo in queue.values {
            if metaInfo.databaseMetaInfo?.id == id {
                return metaInfo
            }
        }
        return nil
    }

    
    
    func downloadThumbnail(databaseMetaInfo: DatabaseMetaInfo) {
        
        let fs = NSFileManager.defaultManager()
        if (databaseMetaInfo.thumbUrl != "" && !fs.fileExistsAtPath(databaseMetaInfo.thumbnailFile!)) {
            
            let request = NSURLRequest(URL: NSURL(string: databaseMetaInfo.thumbUrl)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
            let thumbnailDownloadTask = self.thumbnailDownloadSession.dataTaskWithRequest(request, completionHandler: { data, response, err -> Void in
                if (data != nil) {
                    Log.write("Downloaded thumbnail [\(databaseMetaInfo.thumbUrl)]")
                    data?.writeToFile(databaseMetaInfo.thumbnailFile!, atomically: true)
                    Log.write("Saved thumbnail [\(databaseMetaInfo.thumbUrl)] to [\(databaseMetaInfo.thumbnailFile!)]")
                    self.delegate?.thumbnailUpdated?(databaseMetaInfo)
                } else {
                    Log.write("Unable to download [\(databaseMetaInfo.thumbUrl)]")
                    Log.write(err)
                }
            })
            thumbnailDownloadTask.resume()
        }
    }
    
    func removeThumbnail(databaseMetaInfo: DatabaseMetaInfo) {
        let fs = NSFileManager.defaultManager()
        if (databaseMetaInfo.thumbnailFile != nil && fs.fileExistsAtPath(databaseMetaInfo.thumbnailFile!)) {
            do {
                try fs.removeItemAtPath(databaseMetaInfo.thumbnailFile!)
            } catch {
                Log.write(error)
            }
        }
    }
    
    private func removeVersion(updateTask : DatabaseUpdateTask) {
        delegate?.started?(updateTask)
        updateTask.state = .Updating
        let fullFilename = updateTask.databaseMetaInfo!.databaseFile
        let fs = NSFileManager.defaultManager()
        if (fs.fileExistsAtPath(fullFilename)) {
            do {
                try fs.removeItemAtPath(fullFilename)
            } catch {
                Log.write(error)
            }
        }
        self.removeThumbnail(updateTask.databaseMetaInfo!)
        // remove it from local version
        self.databaseManager.removeDatabaseMetaInfo(updateTask.databaseMetaInfo!.id)
        self.databaseManager.rewriteDatabaseMetaInfo()
        updateTask.state = .NotUpdating
        self.delegate?.completed?(updateTask)
        self.queue[updateTask.databaseMetaInfo!.url] = nil
    }
    
    private func downloadVersion(updateTask : DatabaseUpdateTask) {
        if (updateTask.state == .NotUpdating) {
            let request = NSURLRequest(URL: NSURL(string: updateTask.databaseMetaInfo!.url)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 1500)
            updateTask.task = self.session.downloadTaskWithRequest(request)
            updateTask.state = .Updating
            updateTask.task?.resume()
            delegate?.started?(updateTask)
        }
    }
    
    func detectPausedDownloads() {
        for url in queue.keys {
            if let updateTask = self.queue[url] {
                if (updateTask.state == .Paused) {
                    delegate?.pausedDetected?(updateTask)
                }
            }
        }
    }
    
    func start(databaseMetaInfo : DatabaseMetaInfo) {
        let newTask = DatabaseUpdateTask(databaseMetaInfo: databaseMetaInfo)
        if (self.queue[databaseMetaInfo.url] == nil) {
            self.queue[databaseMetaInfo.url] = newTask
            processQueue()
        }
    }
    
    func isPaused(databaseMetaInfo : DatabaseMetaInfo) -> Bool {
        if let updateTask = self.queue[databaseMetaInfo.url] {
            return updateTask.state == .Paused
        }
        return false
    }
    
    func pause(databaseMetaInfo : DatabaseMetaInfo) {
        if let updateTask = self.queue[databaseMetaInfo.url] {
            if (updateTask.state == .Updating) {
                updateTask.task?.cancelByProducingResumeData({ (data) in
                    if (data != nil) {
                        updateTask.resumeData = data
                        Log.write("Paused [%@] at %.1f%% [%d bytes]", updateTask.databaseMetaInfo!.id, updateTask.progress, updateTask.resumeData!.length)
                    }
                })
                
                updateTask.state = .Paused
                self.delegate?.paused?(updateTask)
            }
        }
        
    }
    
    func resume(databaseMetaInfo : DatabaseMetaInfo) {
        if let updateTask = self.queue[databaseMetaInfo.url] {
            if (updateTask.resumeData != nil) {
                Log.write("Resuming [%@] from %.1f%% [%d bytes]", updateTask.databaseMetaInfo!.id, updateTask.progress, updateTask.resumeData!.length)
                updateTask.task = self.session.downloadTaskWithResumeData(updateTask.resumeData!)
            } else {
                let request = NSURLRequest(URL: NSURL(string: updateTask.databaseMetaInfo!.url)!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 1500)
                updateTask.task = self.session.downloadTaskWithRequest(request)
                Log.write("Resuming [%@] from start", updateTask.databaseMetaInfo!.id)
            }
            updateTask.state = .Updating
            updateTask.task?.resume()
            self.delegate?.resumed?(updateTask)
        }
    }
    
    func cancel(databaseMetaInfo : DatabaseMetaInfo) {
        if let updateTask = self.queue[databaseMetaInfo.url] {
            updateTask.task?.cancel()
            self.queue[databaseMetaInfo.url] = nil
            self.delegate?.cancelled?(updateTask)
        }
    }
    
    func checkForUpdates() -> [DatabaseMetaInfo] {
        var list : [DatabaseMetaInfo] = []
        // Pending & Updated (also checks for failed)
        for infoId in databaseManager.databaseMetaInfo.keys {
            let info = databaseManager.databaseMetaInfo[infoId]!
            for rinfoId in self.remoteDatabaseMetaInfo.keys {
                let rInfo = self.remoteDatabaseMetaInfo[rinfoId]!
                if infoId == rinfoId && info.version != rInfo.version {
                    rInfo.updateType = .Pending
                    list.append(rInfo)
                } else if infoId == rinfoId && (info.updateType == .NoUpdate || info.updateType == .Failed) {
                    // Check if it failed
                    let localFilename = info.databaseFile
                    
                    let fm = NSFileManager.defaultManager()
                    if (!fm.fileExistsAtPath(localFilename)) {
                        info.updateType = .Failed
                        list.append(info)
                    }
                }
            }
        }
        
        // Available
        for rinfoId in self.remoteDatabaseMetaInfo.keys {
            let rInfo = self.remoteDatabaseMetaInfo[rinfoId]!
            var present : Bool = false
            for infoId in databaseManager.databaseMetaInfo.keys {
                if (infoId == rinfoId) {
                    present = true
                    break
                }
            }
            if (!present) {
                rInfo.updateType = .Available
                list.append(rInfo)
            }
        }
        // Retired
        if (!self.remoteDatabaseMetaInfo.isEmpty) { // remote versions will be empty if json wasn't returned (no internet connection etc)
            for infoId in databaseManager.databaseMetaInfo.keys {
                let info = databaseManager.databaseMetaInfo[infoId]
                var present : Bool = false
                for rInfoId in self.remoteDatabaseMetaInfo.keys {
                    if (infoId == rInfoId) {
                        present = true
                        break
                    }
                }
                if (!present && info?.id != databaseManager.masterDatabase?.id) {
                    info?.updateType = .Retired
                    list.append(info!)
                }
            }
        }
        return list
    }
    
    func checkForUpdateCounts() -> Int {
        return self.checkForUpdates().count
    }
    
    func isInitialSetupComplete() -> Bool {
        return !CollectionManager.sharedInstance().collections.isEmpty
    }
    
    func initialSetup() {
        autoUpdateDisabledTemporarily = true
        for databaseMetaInfoMap in self.remoteDatabaseMetaInfo {
            let databaseMetaInfo = databaseMetaInfoMap.1
            if (databaseMetaInfo.requiredAppVersion >= Double(Utils.appVersion)) {
                databaseMetaInfo.updateType = .Pending
                self.start(databaseMetaInfo)
            }
        }
        
    }
    
    func startAutoUpdateIfPossible() {
        if autoUpdateDisabledTemporarily {
            Log.write("Auto-update temporarily disabled!")
            return
        }
        let setting = AutoUpdateSetting.load()
        var canAutoUpdate = false
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            Log.write("Unable to create Reachability")
            return
        }
        switch setting {
        case .WiFi:
            canAutoUpdate = reachability.isReachableViaWiFi()
        case .WiFiCellular:
            canAutoUpdate = reachability.isReachableViaWiFi() || reachability.isReachableViaWWAN()
        case .Never:
            canAutoUpdate = false
        }
        if (canAutoUpdate) {
            Log.write("Running Auto-update")
            let list = self.checkForUpdates()
            for databaseMetaInfo in list {
                if (databaseMetaInfo.updateType != .Available) { // don't download all the databases
                    if (databaseMetaInfo.updateType != .Retired && Double(Utils.appVersion) < databaseMetaInfo.requiredAppVersion) {
                        Log.write("Ignoring [\(databaseMetaInfo.id)] in auto-update. Needs app to be updated")
                    } else {
                        Log.write("Update available [\(databaseMetaInfo.id)]. Updating...")
                        self.start(databaseMetaInfo)
                    }
                }
            }
        }
    }
}

extension DatabaseUpdateManager : NSURLSessionDownloadDelegate {
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let handler = backgroundUpdateCompletedHandler {
            backgroundUpdateCompletedHandler = nil
            // You can do many things here, notify user to let them know
            BackgroundWorker.sharedInstance().startInMainQueue(handler)
        }
    }
        
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let originalURL = downloadTask.originalRequest?.URL?.absoluteString, let updateTask = self.queue[originalURL] {
            updateTask.progress = (Float(totalBytesWritten) / Float(updateTask.databaseMetaInfo!.size)) * 100
            self.delegate?.progressed?(updateTask)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let originalURL = downloadTask.originalRequest?.URL?.absoluteString, let updateTask = self.queue[originalURL] {
            
            let databaseMetaInfo = updateTask.databaseMetaInfo!
            
            let fileSize = Utils.getFileSize(location.path!)
            if (fileSize == databaseMetaInfo.size) {
                let destURL = NSURL(fileURLWithPath: databaseMetaInfo.databaseFile)
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(destURL)
                } catch {
                    // Non-fatal: file probably doesn't exist
                }
                do {
                    try fileManager.copyItemAtURL(location, toURL: destURL)
                    databaseMetaInfo.updateType = .NoUpdate
                    databaseManager.addOrUpdateDatabaseMetaInfo(databaseMetaInfo)
                    databaseManager.rewriteDatabaseMetaInfo()
                    Log.write("Downloaded [%@]", databaseMetaInfo.url)
                    // Remove and download thumbnail to update
                    removeThumbnail(databaseMetaInfo)
                    downloadThumbnail(databaseMetaInfo)
                    self.delegate?.completed?(updateTask)
                } catch let error as NSError {
                    Log.write("Could not copy file to disk: \(error.localizedDescription)")
                }
            } else {
                // Update local as failed
                databaseMetaInfo.updateType = .Failed
                databaseManager.addOrUpdateDatabaseMetaInfo(databaseMetaInfo)
                databaseManager.rewriteDatabaseMetaInfo()
                let failReason = String(format: "Failed [%@]. Expected %.0f bytes, downloaded %.0f bytes", databaseMetaInfo.id, databaseMetaInfo.size, fileSize)
                failedList[databaseMetaInfo.id] = failReason
                Log.write(failReason)
                self.delegate?.failed?(updateTask)
            }
            updateTask.state = .NotUpdating
            updateTask.task = nil
            self.queue[originalURL] = nil
        }
    }
}