//
//  CodeCell.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/2.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import ReactiveSwift

class CodeCell: UITableViewCell {

    
    public static var identifier: String {
        return "CodeCell"
    }
    
    private static let placeholdCode = "--- ---"
    
    let accountLb = UILabel()
    let codeLb = UILabel()
    let remarkLb = UILabel()
    
    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let sv = UIStackView(arrangedSubviews: [accountLb, codeLb, remarkLb])
        let lv = UIView()
        
        sv.axis = .vertical
        sv.distribution = .equalSpacing
        lv.backgroundColor = .lightGray
        accountLb.font = UIFont.boldSystemFont(ofSize: 18)
        accountLb.textColor = .label
        codeLb.font = UIFont.systemFont(ofSize: 38)
        codeLb.textColor = .blue
        remarkLb.font = UIFont.systemFont(ofSize: 18)
        remarkLb.textColor = .label
        
        [sv, lv].forEach {
            contentView.addSubview($0)
        }
        
        sv.snp.makeConstraints {
            $0.edges.equalTo(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }
        lv.snp.makeConstraints {
            $0.left.right.bottom.equalTo(0)
            $0.height.equalTo(1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAuthModel(model: AuthModel, isEditing: Bool) {
        accountLb.text = model.account
        
        codeLb.text = (isEditing ? nil : TOTPManager.share.codeFrom(secretKey: model.secretKey)?.codeString) ?? CodeCell.placeholdCode
        
        let hasRemark = model.remark.count != 0
        remarkLb.text = hasRemark ? model.remark : "备注"
        remarkLb.textColor = hasRemark ? .label : .placeholderText
    }

}
