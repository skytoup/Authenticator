//
//  CodeTableViewDataSource.swift
//  Authenticator
//
//  Created by skytoup on 2019/10/13.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift

/// Code TavleView的数据源
class CodeTableViewDataSource: UITableViewDiffableDataSource<CodeTableViewDataSource.Section, AuthModel> {
    public enum Section {
        case main
    }
    
    /// 数据改变的Signal
    public var dataChangeSignal: Signal<[AuthModel], NoError> {
        cellData.signal
    }
    /// 数据在编辑状态删除的Signal
    public var dataEditingDeleteSignal: Signal<(), NoError> {
        dataEditingDeletePip.output
    }
    
    private let dataEditingDeletePip = Signal<(), NoError>.pipe()
    private let cellData = MutableProperty<[AuthModel]>([])

    convenience init(tbView: UITableView, cmiDelegate: UIContextMenuInteractionDelegate?) {
        self.init(tableView: tbView) { [weak cmiDelegate] (tableView, indexPath, authModel) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: CodeCell.identifier, for: indexPath)

            if let cmiDelegate = cmiDelegate, cell.interactions.count == 0 {
                cell.addInteraction(UIContextMenuInteraction(delegate: cmiDelegate))
            }
            (cell as? CodeCell)?.setAuthModel(model: authModel, isEditing: tableView.isEditing)

            return cell
        }
        
        defaultRowAnimation = .none
        
        let ntfTk = RealmDB.share.db?.objects(AuthModel.self)
            .sorted(byKeyPath: "score")
            .observe({ [weak self, weak tbView] change in
                guard let ws = self, let wTbView = tbView else { return }
                
                if case let .update(_, deletions, insertions, _) = change, deletions.count == 0 || insertions.count == 0 {
                    if wTbView.isEditing && deletions.count != 0 {
                        ws.dataEditingDeletePip.input.send(value: ())
                    }
                }
                
                switch change {
                case .update(let result, _, _, _):
                    fallthrough
                case .initial(let result):
                    ws.cellData.swap(result.map { $0 })
                    TOTPManager.share.secretKeys = ws.cellData.value.map { $0.secretKey }
                    
                    var snap = NSDiffableDataSourceSnapshot<CodeTableViewDataSource.Section, AuthModel>()
                    snap.appendSections([.main])
                    snap.appendItems(ws.cellData.value, toSection: .main)
                    ws.apply(snap, animatingDifferences: true, completion: nil)
                case .error(let error):
                    print("auth model observe error \(error.localizedDescription)")
                }
            })
        tbView.reactive.lifetime.observeEnded {
            ntfTk?.invalidate()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        sortModel(from: sourceIndexPath.row, to: destinationIndexPath.row)
        super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dataCount = super.tableView(tableView, numberOfRowsInSection: section)
        
        if dataCount == 0 && !tableView.isEditing {
            if tableView.backgroundView == nil {
                let lb = UILabel()
                lb.textColor = .label
                lb.text = "点击右上角按钮, 可添加数据"
                lb.font = UIFont.systemFont(ofSize: 18)
                lb.textAlignment = .center
                tableView.backgroundView = lb
            }
        } else {
            tableView.backgroundView = nil
        }

        return dataCount
    }
    
    // MARK: - Private
    private func sortModel(from: Int, to: Int) {
        guard from != to else { return }

        let base = (to == 0 ? 0 : cellData.value[to].score) + 1
        
        try? RealmDB.share.db?.write {
            cellData.value[from].score = base
            
            guard to + 1 != cellData.value.count else { return }
            
            let ajust = from - to > 0 ? 0 : 1
            ((to + ajust)..<cellData.value.count).filter { $0 != from }.enumerated().forEach {
                cellData.value[$1].score = base + $0 + 1
            }
        }
    }
}
