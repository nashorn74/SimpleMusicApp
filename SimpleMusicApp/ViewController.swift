//
//  ViewController.swift
//  SimpleMusicApp
//
//  Created by Kumho Jeong on 16/05/2020.
//  Copyright © 2020 OpenMindWorld. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import StoreKit

extension String {

    func fileName() -> String {
        return NSURL(fileURLWithPath: self).deletingPathExtension?.lastPathComponent ?? ""
    }

    func fileExtension() -> String {
        return NSURL(fileURLWithPath: self).pathExtension ?? ""
    }
}

class ViewController: UIViewController, AVAudioPlayerDelegate, SKCloudServiceSetupViewControllerDelegate {

    @IBOutlet weak var minimizedPlayPauseButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var minimizedMusicPlayer: UIView!
    @IBOutlet weak var popupMusicPlayer: UIView!
    @IBOutlet weak var minimizedSongTitle: UILabel!
    @IBOutlet weak var minimizedArtistName: UILabel!
    @IBOutlet weak var popupSongTitle: UILabel!
    @IBOutlet weak var popupArtistName: UILabel!
    @IBOutlet weak var progressPlay: UIProgressView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBOutlet weak var minimizedAlbumImage: UIImageView!
    @IBOutlet weak var popupAlbumImage: UIImageView!
    
    var player = AVAudioPlayer()
    let MAX_VOLUME : Float = 10.0
    var progressTimer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DummyData.viewController = self
        DummyData.albumList = []
        
        popupMusicPlayer.isHidden = true
        
        volumeSlider.maximumValue = MAX_VOLUME
        volumeSlider.value = 1.0
        
        SKCloudServiceController.requestAuthorization({
        (status: SKCloudServiceAuthorizationStatus) in
            switch(status)
            {
            case .notDetermined:
                print("Access cannot be determined.")
                break
            case .denied:
                print("Access denied or restricted.")
                break
            case .restricted:
                print("Access denied or restricted.")
                break
            case .authorized:
                print("Access granted.")
                self.initAppleMusic()
                break
            @unknown default:
                print("default")
            }
        })
    }
    
    let developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ik1ZNFAzVDcyR1YifQ.eyJpYXQiOjE1OTAwNjM4NzgsImV4cCI6MTYwNTYxNTg3OCwiaXNzIjoiWUFEVFRYS1c5OCJ9.75jQ7ELVNhNC5PzgDl83pQSLlT9pxPm5EiZ2iI57-4gfyJHG3JirXQfoZvViKI5Npu3ZmMTzwrakH2CpVcVtgQ"
    
    func initAppleMusic() {
        
        let controller = SKCloudServiceController()
        
        controller.requestCapabilities { capabilities, error in
            if capabilities.contains(.musicCatalogPlayback) {
                // User has Apple Music account
                print("User has Apple Music account")
                
                controller.requestUserToken(forDeveloperToken: self.developerToken) { userToken, error in
                    // Use this value for recommendation requests.
                    print(userToken!)
                    self.loadSongList(userToken: userToken!)
                }
            } else if capabilities.contains(.musicCatalogSubscriptionEligible) {
                // User can sign up to Apple Music
                print("User can sign up to Apple Music")
                self.showAppleMusicSignup()
            }
        }
    }
    
    /*
    {
        attributes =     {
            canEdit = 1;
            dateAdded = "2020-05-16T17:51:59Z";
            hasCatalog = 1;
            name = "The Beatles";
            playParams =         {
                globalId = "pl.u-d2b05dXtMr02M2";
                id = "p.qQXL6x5tAJBYAY";
                isLibrary = 1;
                kind = playlist;
            };
        };
        href = "/v1/me/library/playlists/p.qQXL6x5tAJBYAY";
        id = "p.qQXL6x5tAJBYAY";
        type = "library-playlists";
    }*/
    
    func loadSongList(userToken:String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.music.apple.com"
        components.path   = "/v1/me/library/songs"
        components.queryItems = [
            URLQueryItem(name: "limit", value: "50"),
        ]
        let url = components.url
        var request = URLRequest(url: url!)
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        request.setValue("Bearer \(self.developerToken)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in

            guard let data = data else {
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                /*{
                    attributes =     {
                        albumName = "1 (2015 Version)";
                        artistName = "The Beatles";
                        artwork =         {
                            height = 1200;
                            url = "https://is5-ssl.mzstatic.com/image/thumb/Music118/v4/52/54/0d/52540d65-3476-bb86-832f-16277137e44b/00602547657725.rgb.jpg/{w}x{h}bb.jpeg";
                            width = 1200;
                        };
                        durationInMillis = 152920;
                        genreNames =         (
                            Rock
                        );
                        name = "A Hard Day's Night (2015 Stereo Mix)";
                        playParams =         {
                            catalogId = 1440833544;
                            id = "i.zpZVNL1tm713m3";
                            isLibrary = 1;
                            kind = song;
                            reporting = 1;
                        };
                        releaseDate = "1964-07-10";
                        trackNumber = 6;
                    };
                    href = "/v1/me/library/songs/i.zpZVNL1tm713m3";
                    id = "i.zpZVNL1tm713m3";
                    type = "library-songs";
                },*/
                DispatchQueue.main.async {
                    DummyData.albumList.removeAll()
                    var tempAlbumList:[[String:Any]] = []
                    var tempSongList:[[String:Any]] = []
                    if let songList:[[String:Any]] = json!["data"] as? [[String:Any]] {
                        print("\(songList.count)")
                        for song in songList {
                            let songObject:[String:Any] = song["attributes"] as! [String:Any]
                            let albumName:String = songObject["albumName"] as! String
                            let artistName:String = songObject["artistName"] as! String
                            let name:String = songObject["name"] as! String
                            let artwork:[String:Any] = songObject["artwork"] as! [String:Any]
                            var url:String = artwork["url"] as! String
                            url = url.replacingOccurrences(of: "{w}", with: "1200")
                            url = url.replacingOccurrences(of: "{h}", with: "1200")
                            //print("\(albumName) \(artistName) \(name)")
                            //print("\(url)")
                            
                            let songInfo:[String:Any] = [
                                "albumTitle": albumName,
                                "songName": name,
                                "songFile": "g01.mp3"
                            ]
                            tempSongList.append(songInfo)

                            //check album
                            var isExist:Bool = false
                            for album in tempAlbumList {
                                if album["albumTitle"] as! String == albumName {
                                    isExist = true
                                    break;
                                }
                            }
                            if isExist == false {
                                tempAlbumList.append([
                                    "albumTitle": albumName,
                                    "albumImage": url,
                                    "artistName": artistName,
                                    "songList": [songInfo],
                                    "suffledSongList": []
                                ])
                            }
                        }
                        
                        // Convert data to DummyData
                        for album in tempAlbumList {
                            var songList:[[String:Any]] = []
                            for song in tempSongList {
                                if album["albumTitle"] as! String == song["albumTitle"] as! String {
                                    songList.append([
                                        "songName": song["songName"] as! String,
                                        "songFile": song["songFile"] as! String
                                    ])
                                }
                            }
                            DummyData.albumList.append([
                                "albumTitle": album["albumTitle"] as! String,
                                "albumImage": album["albumImage"] as! String,
                                "artistName": album["artistName"] as! String,
                                "songList": songList,
                                "suffledSongList": []
                            ])
                        }
                        
                        if DummyData.albumListViewController != nil {
                            (DummyData.albumListViewController as! AlbumListViewController).refreshAlbumList()
                        }
                        self.setUpPlayer()
                        self.setupRemoteTransportControls()
                        self.setupNowPlaying()
                        self.setupNotifications()
                    }
                }
            }
            catch {
            }
        }
        task.resume()
    }
    
    let affiliateToken:String = ""
    func showAppleMusicSignup() {
        let vc = SKCloudServiceSetupViewController()
        vc.delegate = self

        let options: [SKCloudServiceSetupOptionsKey: Any] = [
            .action: SKCloudServiceSetupAction.subscribe,
            .affiliateToken: affiliateToken,
            .messageIdentifier: SKCloudServiceSetupMessageIdentifier.playMusic
        ]
            
        vc.load(options: options) { success, error in
            if success {
                self.present(vc, animated: true)
            }
        }

    }
    
    func convertNSTimeInterval2String(_ time:TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d",min,sec)
        return strTime
    }
    
    @objc func updatePlayTime() -> Void {
        currentTimeLabel.text = convertNSTimeInterval2String(player.currentTime)
        progressPlay.progress = Float(player.currentTime/player.duration)
    }

    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime)
    @IBAction func changeVolume(_ sender: Any) {
        player.volume = volumeSlider.value
    }
    
    @IBAction func onStart(_ sender: Any) {
        //MusicPlayer.shared.startBackgroundMusic()
        if (player.isPlaying) {
            pause()
        }
        else {
            play()
        }
    }
    
    @IBAction func onStop(_ sender: Any) {
        //MusicPlayer.shared.stopBackgroundMusic()
        player.stop()
        player.currentTime = 0
        minimizedPlayPauseButton.setTitle("Play", for: UIControl.State.normal)
        playPauseButton.setTitle("Play", for: UIControl.State.normal)
        progressTimer.invalidate()
    }
        
    @IBAction func onOpen(_ sender: Any) {
        popupMusicPlayer.isHidden = false
        minimizedMusicPlayer.isHidden = true
    }
    
    @IBAction func onClose(_ sender: Any) {
        popupMusicPlayer.isHidden = true
        minimizedMusicPlayer.isHidden = false
    }
    @IBAction func onPrev(_ sender: Any) {
        if (startPrevSong()) {
            print("prev")
        }
    }
    @IBAction func onNext(_ sender: Any) {
        if (startNextSong()) {
            print("next")
        }
    }
    
    // MARK: Setups
    func setUpPlayer() {
        let file = (DummyData.albumList[
        DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]]) [DummyData.currentSelectedSong]["songFile"] as! String
        let fileNameWithoutExtension = file.fileName()
        let fileExtension = file.fileExtension()
        
        do {
            let url = Bundle.main.url(forResource: fileNameWithoutExtension, withExtension: fileExtension)
            player = try AVAudioPlayer(contentsOf: url!)
            player.delegate = self
            player.prepareToPlay()
            player.volume = volumeSlider.value
            endTimeLabel.text = convertNSTimeInterval2String(player.duration)
        } catch let error as NSError {
            print("Failed to init audio player: \(error)")
        }
    }
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            print("Play command - is playing: \(self.player.isPlaying)")
            if !self.player.isPlaying {
              self.play()
              return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            print("Pause command - is playing: \(self.player.isPlaying)")
            if self.player.isPlaying {
              self.pause()
              return .success
            }
            return .commandFailed
        }
        
        let skipBackwardCommand = commandCenter.skipBackwardCommand
        //skipBackwardCommand.isEnabled = true
        skipBackwardCommand.addTarget(handler: skipBackward)
        //skipBackwardCommand.preferredIntervals = [42]

        let skipForwardCommand = commandCenter.skipForwardCommand
        //skipForwardCommand.isEnabled = true
        skipForwardCommand.addTarget(handler: skipForward)
        //skipForwardCommand.preferredIntervals = [42]
    }
    
    func setupNowPlaying() {
        let songList = (DummyData.albumList[
        DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]])
      // Define Now Playing Info
      var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] =  songList[DummyData.currentSelectedSong]["songName"] as! String
      
        let artistName = (DummyData.albumList[
        DummyData.currentSelectedAlbum]["artistName"] as! String)
        let albumName = (DummyData.albumList[
        DummyData.currentSelectedAlbum]["albumTitle"] as! String)
        minimizedSongTitle.text = songList[DummyData.currentSelectedSong]["songName"] as? String
        minimizedArtistName.text = "\(artistName) - \(albumName)"
        popupSongTitle.text = songList[DummyData.currentSelectedSong]["songName"] as? String
        popupArtistName.text = "\(artistName) - \(albumName)"
        minimizedAlbumImage.load(url: URL(string:(DummyData.albumList[DummyData.currentSelectedAlbum]["albumImage"] as! String))!, size: CGSize(width: 50, height: 50))
        popupAlbumImage.load(url: URL(string:(DummyData.albumList[DummyData.currentSelectedAlbum]["albumImage"] as! String))!, size: CGSize(width: 300, height: 300))
        
        if let data = try? Data(contentsOf: URL(string:(DummyData.albumList[
            DummyData.currentSelectedAlbum]["albumImage"] as! String))!) {
            if var image = UIImage(data: data) {
                DispatchQueue.main.async {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                      return image
                    }
                    // Set the metadata
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
        }
        
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
      
      // Set the metadata
      //MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlaying(isPause: Bool) {
      // Define Now Playing Info
      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!
      
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
      
      // Set the metadata
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setupNotifications() {
      let notificationCenter = NotificationCenter.default
      notificationCenter.addObserver(self,
                                     selector: #selector(handleInterruption),
                                     name: AVAudioSession.interruptionNotification,
                                     object: nil)
      notificationCenter.addObserver(self,
                                     selector: #selector(handleRouteChange),
                                     name: AVAudioSession.routeChangeNotification,
                                     object: nil)
    }
    
    func startPrevSong() -> Bool {
        let shuffledList:[Int] = DummyData.albumList[DummyData.currentSelectedAlbum]["suffledSongList"] as! [Int]
        if shuffledList.count > 0 {
            var found:Bool = false
            for index in shuffledList.reversed() {
                if found {
                    DummyData.currentSelectedSong = index
                    
                    setUpPlayer()
                    setupNowPlaying()
                    play()
                    
                    return true
                }
                if index == DummyData.currentSelectedSong {
                    found = true
                }
            }
        } else {
            if (DummyData.currentSelectedSong > 0) {
                DummyData.currentSelectedSong = DummyData.currentSelectedSong - 1
                
                setUpPlayer()
                setupNowPlaying()
                play()
                
                return true
            }
        }
        return false
    }
    
    func startNextSong() -> Bool {
        let size:Int = (DummyData.albumList[
            DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]]).count
        let shuffledList:[Int] = DummyData.albumList[DummyData.currentSelectedAlbum]["suffledSongList"] as! [Int]
        if shuffledList.count > 0 {
            var found:Bool = false
            for index in shuffledList {
                if found {
                    DummyData.currentSelectedSong = index
                    
                    setUpPlayer()
                    setupNowPlaying()
                    play()
                    
                    return true
                }
                if index == DummyData.currentSelectedSong {
                    found = true
                }
            }
        } else {
            if (DummyData.currentSelectedSong < size - 1) {
                DummyData.currentSelectedSong = DummyData.currentSelectedSong + 1
                
                setUpPlayer()
                setupNowPlaying()
                play()
                
                return true
            }
        }
        return false
    }
    
    func skipBackward(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if (startPrevSong()) {
            print("prev")
        }

        /*guard let command = event.command as? MPSkipIntervalCommand else {
            return .noSuchContent
        }
        let interval = command.preferredIntervals[0]
        print(interval) //Output: 42*/

        return .success
    }

    func skipForward(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if (startNextSong()) {
            print("next")
        }

        /*guard let command = event.command as? MPSkipIntervalCommand else {
            return .noSuchContent
        }
        let interval = command.preferredIntervals[0]
        print(interval) //Output: 42*/

        return .success
    }
    
    // MARK: Handle Notifications
    @objc func handleRouteChange(notification: Notification) {
      guard let userInfo = notification.userInfo,
        let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
        let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
          return
      }
      switch reason {
      case .newDeviceAvailable:
        let session = AVAudioSession.sharedInstance()
        for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
          print("headphones connected")
          DispatchQueue.main.sync {
            self.play()
          }
          break
        }
      case .oldDeviceUnavailable:
        if let previousRoute =
          userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
          for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
            print("headphones disconnected")
            DispatchQueue.main.sync {
              self.pause()
            }
            break
          }
        }
      default: ()
      }
    }
    
    @objc func handleInterruption(notification: Notification) {
      guard let userInfo = notification.userInfo,
        let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
          return
      }
      
      if type == .began {
        print("Interruption began")
        // Interruption began, take appropriate actions
      }
      else if type == .ended {
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
          let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
          if options.contains(.shouldResume) {
            // Interruption Ended - playback should resume
            print("Interruption Ended - playback should resume")
            play()
          } else {
            // Interruption Ended - playback should NOT resume
            print("Interruption Ended - playback should NOT resume")
          }
        }
      }
    }
    
    // MARK: Actions
    func play() {
        player.play()
        minimizedPlayPauseButton.setTitle("Pause", for: UIControl.State.normal)
        playPauseButton.setTitle("Pause", for: UIControl.State.normal)
        updateNowPlaying(isPause: false)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
        print("Play - current time: \(player.currentTime) - is playing: \(player.isPlaying)")
    }
    
    func pause() {
        player.pause()
        minimizedPlayPauseButton.setTitle("Play", for: UIControl.State.normal)
        playPauseButton.setTitle("Play", for: UIControl.State.normal)
        updateNowPlaying(isPause: true)
        print("Pause - current time: \(player.currentTime) - is playing: \(player.isPlaying)")
    }
        
    // MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      print("Audio player did finish playing: \(flag)")
        progressTimer.invalidate()
      if (flag) {
        if (!startNextSong()) {
            updateNowPlaying(isPause: true)
            minimizedPlayPauseButton.setTitle("Play", for: UIControl.State.normal)
            playPauseButton.setTitle("Play", for: UIControl.State.normal)
        }
      }
    }
}
