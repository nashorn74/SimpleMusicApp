//
//  AlbumListViewController.swift
//  SimpleMusicApp
//
//  Created by Kumho Jeong on 16/05/2020.
//  Copyright © 2020 OpenMindWorld. All rights reserved.
//

import UIKit

class AlbumListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onTest(_ sender: Any) {
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(switchToAlbumInfoTabCont), userInfo: nil,repeats: false)
    }
    
    @objc func switchToAlbumInfoTabCont(){
        tabBarController!.selectedIndex = 1
    }
}
