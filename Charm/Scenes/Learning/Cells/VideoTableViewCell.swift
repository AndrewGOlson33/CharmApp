//
//  VideoTableViewCell.swift
//  Charm
//
//  Created by Daniel Pratt on 4/5/19.
//  Copyright © 2019 Charm, LLC. All rights reserved.
//

import UIKit

class VideoTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imgThumbnail: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    var thumbnailImage: UIImage? {
        didSet {
            imgThumbnail.image = thumbnailImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgThumbnail.image = thumbnailImage ?? UIImage(named: Image.placeholder) ?? nil
        lblTitle.text = ""
    }

    override func prepareForReuse() {
        imgThumbnail.image = thumbnailImage ?? UIImage(named: Image.placeholder) ?? nil
        lblTitle.text = ""
    }

}
