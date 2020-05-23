//
//  TableViewCell.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 08.01.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell, UIPointerInteractionDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if #available(iOS 13.4, *) {
            configurePointer()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @available(iOS 13.4, *)
    func configurePointer() {
        let interaction = UIPointerInteraction(delegate: self)
        addInteraction(interaction)
    }

    // MARK: - UIPointerInteractionDelegate -
    @available(iOS 13.4, *)
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: UIPointerEffect.highlight(targetedPreview))
        }
        return pointerStyle
    }
    
}
