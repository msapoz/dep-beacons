//
//  ContentView.swift
//  deputy-beacon
//
//  Created by Mikhail Sapozhnikov on 10/24/19.
//  Copyright © 2019 Deputy. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Image("Deputy-Star-White-RGB")
        .resizable()
        .frame(width: 150, height: 150)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
