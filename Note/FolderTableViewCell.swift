//
//  FolderTableViewCell.swift
//  Note
//
//  Created by 南優也 on 2018/03/11.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import SwiftyDropbox

class FolderTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    var file: Folder? {
        didSet {
            titleLabel.text = self.file?.name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
