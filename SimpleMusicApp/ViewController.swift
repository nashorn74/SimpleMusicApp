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

class ViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var minimizedPlayPauseButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var minimizedMusicPlayer: UIView!
    @IBOutlet weak var popupMusicPlayer: UIView!
    
    var player = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupMusicPlayer.isHidden = true
      
        setUpPlayer()
        setupRemoteTransportControls()
        setupNowPlaying()
        setupNotifications()
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
    }
        
    @IBAction func onOpen(_ sender: Any) {
        popupMusicPlayer.isHidden = false
        minimizedMusicPlayer.isHidden = true
    }
    
    @IBAction func onClose(_ sender: Any) {
        popupMusicPlayer.isHidden = true
        minimizedMusicPlayer.isHidden = false
    }
    
    // MARK: Setups
    func setUpPlayer() {
        do {
            let url = Bundle.main.url(forResource: "song", withExtension: "mp3")
            player = try AVAudioPlayer(contentsOf: url!)
            player.delegate = self
            player.prepareToPlay()
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
    }
    
    func setupNowPlaying() {
      // Define Now Playing Info
      var nowPlayingInfo = [String : Any]()
      nowPlayingInfo[MPMediaItemPropertyTitle] = "Unstoppable"
      
      if let image = UIImage(named: "artist") {
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
      if (flag) {
        updateNowPlaying(isPause: true)
        minimizedPlayPauseButton.setTitle("Play", for: UIControl.State.normal)
        playPauseButton.setTitle("Play", for: UIControl.State.normal)
      }
    }
}
