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

extension String {

    func fileName() -> String {
        return NSURL(fileURLWithPath: self).deletingPathExtension?.lastPathComponent ?? ""
    }

    func fileExtension() -> String {
        return NSURL(fileURLWithPath: self).pathExtension ?? ""
    }
}

class ViewController: UIViewController, AVAudioPlayerDelegate {

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
    
    var player = AVAudioPlayer()
    let MAX_VOLUME : Float = 10.0
    var progressTimer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DummyData.viewController = self
        
        popupMusicPlayer.isHidden = true
        
        volumeSlider.maximumValue = MAX_VOLUME
        volumeSlider.value = 1.0

        setUpPlayer()
        setupRemoteTransportControls()
        setupNowPlaying()
        setupNotifications()
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
        
      if let image = UIImage(named: (DummyData.albumList[
        DummyData.currentSelectedAlbum]["albumImage"] as! String)) {
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
          return image
        }
      }
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
      
      // Set the metadata
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
