/*
 This file is part of GeoFeatures, a program for populating a graph of
 geo features from KML or GeoJSON files
 Copyright (C) 2023  Michael E. Rockhold

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation

public class Coordinates: Element {
    
    internal private(set) var coordinates = [Coordinate]()
    
    internal override func didEnd() {
        let tuples = text?.split(separator: " ", omittingEmptySubsequences: true)
        for t in tuples! {
            let coordStrs = t.split(separator: ",")
            // TODO: handle the various kinds of errors we could have here
            let coordinate = Coordinate(longitude: Double(coordStrs[0])!, latitude: Double(coordStrs[1])!, altitude: Double(coordStrs[2])!)
            coordinates.append(coordinate)
        }
        
        if let p = parent as? AcceptsCoordinates {
            p.accept(coordinates: self)
        }
    }
}
