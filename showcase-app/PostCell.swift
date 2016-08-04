//
//  PostCell.swift
//  showcase-app
//
//  Created by Tihomir Videnov on 7/14/16.
//  Copyright © 2016 Tihomir Videnov. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var showcaseImage: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var profileName: UILabel!
    

    var post: Post!
    var request: Request?
    var likeRef: FIRDatabaseReference!
    var profileRef: FIRDatabaseReference!
    var profileImageRef: FIRDatabaseReference!
    var profileimageUrl = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(PostCell.likeTapped(_:)))
        tap.numberOfTapsRequired = 1
        likeImg.addGestureRecognizer(tap)
        likeImg.userInteractionEnabled = true
        
    }
    
    override func drawRect(rect: CGRect) {
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        
        showcaseImage.clipsToBounds = true
    }

    func configureCell(post: Post, img: UIImage?) {
        self.post = post
    
        self.descriptionText.text = post.postDescription
        self.likesLbl.text = "\(post.likes)"
        
        likeRef = DataService.ds.REF_USER_CURRENT.child("likes").child(post.postKey)
        profileRef = DataService.ds.REF_USER_CURRENT.child("username")
        profileImageRef = DataService.ds.REF_USER_CURRENT.child("profileImage")
        
        //getting the profile name
        profileRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
        
            self.profileName.text = snapshot.value as? String
        })
        
        //downloading the profile image for the post
        profileImageRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
        
            if snapshot.value is NSNull {
                self.profileImage.image = UIImage(named: "profileImage")
            } else {
                
                if let profImg = snapshot.value as? String {
                    self.profileimageUrl = profImg
                }
                
                self.request = Alamofire.request(.GET, self.profileimageUrl).response(completionHandler: { request, response, data, err in
                
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.profileImage.image = img
                        //feedViewController.imageCache.setObject(img, forKey: (self.post.profileImage)!)
                    }
                
                })
            }
        })
        
        //getting the post image
        if post.imageUrl != nil {
            
            //if we have the image already in the cache get it from there
            if img != nil {
                self.showcaseImage.image = img
            // else get it from the internet
            } else {
                
                request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, err in
                    
                    if err == nil {
                        let img =  UIImage(data: data!)!
                        self.showcaseImage.image = img
                        //add the downloaded image to the cache
                        feedViewController.imageCache.setObject(img, forKey: self.post.imageUrl!)
                    }
                    
                })
            }
            
            
        } else {
            self.showcaseImage.hidden = true
        }
        
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //NSNull is Firabare's version of nil or null
            if snapshot.value is NSNull {
                //In this case the post was not liked
                self.likeImg.image = UIImage(named: "heart-empty")
            } else {
                self.likeImg.image = UIImage(named: "heart-full")
            }
        })
    }

    func likeTapped(sender: UITapGestureRecognizer) {
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            //NSNull is Firabare's version of nil or null
            if snapshot.value is NSNull {
                self.likeImg.image = UIImage(named: "heart-full")
                self.post.adjustLikes(true)
                self.likeRef.setValue(true)
            } else {
                self.likeImg.image = UIImage(named: "heart-empty")
                self.post.adjustLikes(false)
                self.likeRef.removeValue()
            }
        })
        
    }
    

}