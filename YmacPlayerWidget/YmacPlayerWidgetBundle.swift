//
//  YmacPlayerWidgetBundle.swift
//  YmacPlayerWidget
//
//  Created by Valentyn Bazavluk on 30.07.26.
//

import WidgetKit
import SwiftUI

@main
struct YmacPlayerWidgetBundle: WidgetBundle {
    var body: some Widget {
        YmacPlayerWidget()
        YmacPlayerWidgetControl()
    }
}
