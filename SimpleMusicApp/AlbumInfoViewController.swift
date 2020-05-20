//
//  AlbumInfoViewController.swift
//  SimpleMusicApp
//
//  Created by Kumho Jeong on 16/05/2020.
//  Copyright © 2020 OpenMindWorld. All rights reserved.
//

import UIKit

class AlbumInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let identifier = "RowIdentifer";
    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let size:Int = (DummyData.albumList[
        DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]]).count
        return size
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! SongListItemView
        
            let albumInfo = DummyData.albumList[DummyData.currentSelectedAlbum]
            let songInfo = (albumInfo["songList"] as! [[String:Any]])[indexPath.item]
            cell.numberLabel.text = "\(indexPath.item+1)"
            cell.songNameLabel.text = (songInfo["songName"] as! String)
            
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard DummyData.viewController != nil else {
            return
        }
        
        DummyData.albumList[DummyData.currentSelectedAlbum]["suffledSongList"] = []
        DummyData.currentSelectedSong = indexPath.item
        (DummyData.viewController as! ViewController).setUpPlayer()
        (DummyData.viewController as! ViewController).setupNowPlaying()
        (DummyData.viewController as! ViewController).onStart(self)
    }
    
    @IBAction func onStart(_ sender: Any) {
        guard DummyData.viewController != nil else {
            return
        }
        
        DummyData.albumList[DummyData.currentSelectedAlbum]["suffledSongList"] = []
        DummyData.currentSelectedSong = 0
        (DummyData.viewController as! ViewController).setUpPlayer()
        (DummyData.viewController as! ViewController).setupNowPlaying()
        (DummyData.viewController as! ViewController).onStart(self)
    }
    
    @IBAction func onShuffle(_ sender: Any) {
        guard DummyData.viewController != nil else {
            return
        }
        
        let size:Int = (DummyData.albumList[
        DummyData.currentSelectedAlbum]["songList"] as! [[String:Any]]).count
        var shuffledList:[Int] = []
        var count:Int = 0
        while true {
            let number = Int.random(in: 0 ..< size)
            var isExist = false
            for songNumber in shuffledList {
                if songNumber == number {
                    isExist = true
                    break
                }
            }
            if isExist == false {
                shuffledList.append(number)
                count = count + 1
            }
            if (count >= size) { break }
        }
        print(shuffledList)
        
        DummyData.currentSelectedSong = shuffledList[0]
        DummyData.albumList[DummyData.currentSelectedAlbum]["suffledSongList"] = shuffledList
        (DummyData.viewController as! ViewController).setUpPlayer()
        (DummyData.viewController as! ViewController).setupNowPlaying()
        (DummyData.viewController as! ViewController).onStart(self)
    }
    
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let albumInfo = DummyData.albumList[DummyData.currentSelectedAlbum]
        albumTitleLabel.text = albumInfo["albumTitle"] as? String
        artistNameLabel.text = albumInfo["artistName"] as? String
        tableView.reloadData()
    }
    
    @IBAction func onBack(_ sender: Any) {
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(switchToAlbumListTabCont), userInfo: nil,repeats: false)
    }
    
    @objc func switchToAlbumListTabCont(){
        tabBarController!.selectedIndex = 0
    }
}
