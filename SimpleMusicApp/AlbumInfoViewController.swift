//
//  AlbumInfoViewController.swift
//  SimpleMusicApp
//
//  Created by Kumho Jeong on 16/05/2020.
//  Copyright © 2020 OpenMindWorld. All rights reserved.
//

import UIKit

class AlbumInfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onBack(_ sender: Any) {
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(switchToAlbumListTabCont), userInfo: nil,repeats: false)
    }
    
    @objc func switchToAlbumListTabCont(){
        tabBarController!.selectedIndex = 0
    }
}
