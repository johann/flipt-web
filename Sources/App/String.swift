//
//  String.swift
//  Flipt-web
//
//  Created by Johann Kerr on 12/26/16.
//
//

import Foundation


extension String {
    func trunc(length: Int, trailing: String? = "...") -> String {
        if self.characters.count > length {
            let index = self.index(self.startIndex, offsetBy: length)
            return self.substring(to:index) + (trailing ?? "")
        } else {
            return self
        }
    }
}
