//
//  SortedArraySearch+Extension.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

extension Array {
    func lowerBound(where isBeforeTarget: (Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex

        while low < high {
            let middle = low + (high - low) / 2

            if isBeforeTarget(self[middle]) {
                low = middle + 1
            } else {
                high = middle
            }
        }

        return low
    }
}
