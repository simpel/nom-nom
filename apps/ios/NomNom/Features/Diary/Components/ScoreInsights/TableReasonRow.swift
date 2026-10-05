import SwiftUI

extension ListRow {
    /// One `TableReason` as a row: the reason, who it is about, and its change in points
    /// as a delta Badge. A tag reason ("Too spicy, said by Anna and Leo") carries no badge.
    init(reason: TableReason) {
        self.init(
            reason.title,
            meta: reason.detail,
            trailing: reason.delta.map { .badge(.delta($0)) }
        )
    }
}
