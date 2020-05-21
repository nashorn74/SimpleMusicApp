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

//Update system volume
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
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
    
    let MAX_VOLUME : Float = 1.0
    var progressTimer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DummyData.viewController = self
        DummyData.albumList = []
        
        popupMusicPlayer.isHidden = true
        
        volumeSlider.maximumValue = MAX_VOLUME
        //volumeSlider.value = 0.1
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlayingInfo), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
            
    @objc func updatePlayTime() -> Void {
        let nowPlaying = MPMusicPlayerController.applicationQueuePlayer.nowPlayingItem
        if
            let playbackDuration:TimeInterval = (nowPlaying?.playbackDuration),
            let playbackTime:TimeInterval = (MPMusicPlayerController.applicationQueuePlayer.currentPlaybackTime) {
            currentTimeLabel.text = convertNSTimeInterval2String(playbackTime)
            progressPlay.progress = Float(playbackTime/playbackDuration)
        }
    }
    
    @objc func updateNowPlayingInfo(){
        let nowPlaying = MPMusicPlayerController.applicationQueuePlayer.nowPlayingItem
        if let albumArtist:String = (nowPlaying?.albumArtist),
            let albumTitle:String = (nowPlaying?.albumTitle),
            let songName:String = (nowPlaying?.title),
            let playbackDuration:TimeInterval = (nowPlaying?.playbackDuration) {
            print("Currently Playing: \(albumArtist) \(albumTitle)")
            print("\(playbackDuration)")
            endTimeLabel.text = convertNSTimeInterval2String(playbackDuration)
            
            minimizedSongTitle.text = songName
            minimizedArtistName.text = "\(albumArtist) - \(albumTitle)"
            popupSongTitle.text = songName
            popupArtistName.text = "\(albumArtist) - \(albumTitle)"
        }
        
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
                            let playParams:[String:Any] = songObject["playParams"] as! [String:Any]
                            var songFile:String = ""
                            if let catalogId:String = playParams["catalogId"] as? String {
                                songFile = catalogId
                            }
                            if let purchasedId:String = playParams["purchasedId"] as? String {
                                songFile = purchasedId
                            }
                            url = url.replacingOccurrences(of: "{w}", with: "1200")
                            url = url.replacingOccurrences(of: "{h}", with: "1200")
                            //print("\(albumName) \(artistName) \(name)")
                            //print("\(url)")
                            
                            let songInfo:[String:Any] = [
                                "albumTitle": albumName,
                                "songName": name,
                                "songFile": songFile
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
                        self.prepareToPlay()
                        self.setupNowPlaying()
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

    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime)
    @IBAction func changeVolume(_ sender: Any) {
        //player.volume = volumeSlider.value
        MPVolumeView.setVolume(volumeSlider.value)
    }
    
    @IBAction func onStart(_ sender: Any) {
        let player = MPMusicPlayerController.applicationQueuePlayer
        if (player.playbackState == MPMusicPlaybackState.playing) {
            pause()
        }
        else {
            play()
        }
    }
    
    @IBAction func onStop(_ sender: Any) {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.stop()
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
    func prepareToPlay() {
        let player = MPMusicPlayerController.applicationQueuePlayer
        var storeIds: [String] = []
        let shuffledList:[Int] = DummyData.albumList[DummyData.currentSelectedAlbum]["suffledSongList"] as! [Int]
        if shuffledList.count > 0 {
            for songNumber in shuffledList {
                let songList:[[String:Any]] = DummyData.albumList[DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]]
                let songInfo:[String:Any] = songList[songNumber]
                storeIds.append(songInfo["songFile"] as! String)
            }
        } else {
            for songInfo in DummyData.albumList[DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]] {
                storeIds.append(songInfo["songFile"] as! String)
            }
        }
        
        let queue  = MPMusicPlayerStoreQueueDescriptor(storeIDs: storeIds)
        player.setQueue(with: queue)
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
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                      return image
                    }
                    // Set the metadata
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
        }
    }
    
    func updateNowPlaying(isPause: Bool) {
      // Define Now Playing Info
      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!
      
        let playbackTime:TimeInterval = (MPMusicPlayerController.applicationQueuePlayer.currentPlaybackTime)
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackTime
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
      
      // Set the metadata
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
        
    func startPrevSong() -> Bool {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.skipToPreviousItem()
        return true
    }
    
    func startNextSong() -> Bool {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.skipToNextItem()
        return true
    }
    
    // MARK: Actions
    func play() {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.play()
        
        minimizedPlayPauseButton.setTitle("Pause", for: UIControl.State.normal)
        playPauseButton.setTitle("Pause", for: UIControl.State.normal)
        updateNowPlaying(isPause: false)
    }
    
    func pause() {
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.pause()
        minimizedPlayPauseButton.setTitle("Play", for: UIControl.State.normal)
        playPauseButton.setTitle("Play", for: UIControl.State.normal)
        updateNowPlaying(isPause: true)
    }
}
