//
//  AlbumListViewController.swift
//  SimpleMusicApp
//
//  Created by Kumho Jeong on 16/05/2020.
//  Copyright © 2020 OpenMindWorld. All rights reserved.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension UIImageView {
    func load(url: URL, size: CGSize) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if var image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        image = image.resized(to: size)
                        self?.image = image
                    }
                }
            }
        }
    }
}

class AlbumListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "CellIdentifer";

    @IBOutlet weak var albumCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        DummyData.albumListViewController = self
    }
    
    @objc func switchToAlbumInfoTabCont(){
        tabBarController!.selectedIndex = 1
    }
    
    func refreshAlbumList() {
        albumCollectionView.reloadData()
    }
    
    //UICollectionViewDelegateFlowLayout methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        
        return 4;
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        
        return 1;
    }
    
    
    //UICollectionViewDatasource methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = self.view.frame.width/2-7
        return CGSize(width: size, height: size)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return DummyData.albumList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumListItemView
        
        let albumInfo = DummyData.albumList[indexPath.item]
        let size = (self.view.frame.width/2-7) * 0.75
        cell.albumImage.load(url: URL(string:albumInfo["albumImage"] as! String)!, size: CGSize(width: size, height: size))
        cell.albumTitle.text = (albumInfo["albumTitle"] as! String)
        cell.artistName.text = (albumInfo["artistName"] as! String)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DummyData.currentSelectedAlbum = indexPath.item
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(switchToAlbumInfoTabCont), userInfo: nil,repeats: false)
    }
}
