//
//  VisilabsHelper.swift
//  VisilabsIOS
//
//  Created by Egemen on 27.04.2020.
//

import Foundation

internal class VisilabsHelper{
    
    //TODO: buradaki değerleri VisilabsConfig e aktar, metersPerNauticalMile niye var?
    static func distanceSquared(forLat1 lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let radius = 0.0174532925199433 // 3.14159265358979323846 / 180.0
        let nauticalMilesPerLatitude = 60.00721
        //let nauticalMilesPerLongitude = 60.10793
        let metersPerNauticalMile = 1852.00
        let nauticalMilesPerLongitudeDividedByTwo = 30.053965
        // simple pythagorean formula - for efficiency
        let yDistance = (lat2 - lat1) * nauticalMilesPerLatitude
        let xDistance = (cos(lat1 * radius) + cos(lat2 * radius)) * (lng2 - lng1) * nauticalMilesPerLongitudeDividedByTwo
        let res = ((yDistance * yDistance) + (xDistance * xDistance)) * (metersPerNauticalMile * metersPerNauticalMile)
        return res
    }
}
