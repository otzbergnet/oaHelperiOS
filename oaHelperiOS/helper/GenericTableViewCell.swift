//
//  GenericTableViewCell.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 23.05.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import UIKit

class GenericTableViewCell: UITableViewCell, UIPointerInteractionDelegate {

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
