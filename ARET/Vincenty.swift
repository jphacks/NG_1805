//
//  Vincenty.swift
//  ARET
//
//  Created by 落合裕也 on 2018/10/17.
//  Copyright © 2018年 落合裕也. All rights reserved.
//
import Foundation
import CoreLocation
import ARKit

extension Double {
    static func radian(_ deg:Double) -> Double {
        return Double.pi / 180.0 * deg
    }
    var radian:Double {
        return self * Double.pi / 180.0
    }
    
    static func degree(_ deg:Double) -> Double {
        return  180.0 * deg / Double.pi
    }
    var degree:Double {
        return  180.0 * self / Double.pi
    }
}
class Vincentry{
    let a: Double!
    let f: Double!
    let b: Double!
    var destination:CLLocation!
    var position:CLLocation!
    var positionFlag:Bool
    var distance:Double
    
    init(destination:CLLocation){
        /// Radius at equator [m]
        self.a = 6378137.06
        /// Flattening of the ellipsoid
          self.f = 1 / 298.257223563
        /// Radius at the poles [m]
        self.b = 6356752.314245
        /// 目的地
        self.destination = destination
        self.positionFlag = true
        self.distance = 0
    }


    func u(of latitude: Double) -> Double {
        
        return atan((1 - f) * tan(latitude))
    }

// MARK: - Internal
    //自分の位置を更新ついでに
    public func updatemyPosition(newposition:CLLocation) -> (SCNVector3,Bool){
        
        self.position = newposition
        if(positionFlag)
        {
            positionFlag = false
            return (self.transformDestination(),true)
        }
        return (self.transformDestination(),false)
    }
    
    public func updatemyDestination(newdestination:CLLocation){
        
        self.destination = newdestination
        self.positionFlag = true
    }
    
    public func getdistance()->Double
    {
        return self.distance
    }
    //Vincentyの逆　こっちを使う
public func calcurateDistanceAndAzimuths(location2: CLLocation) -> (s: Double, a1: Double, a2: Double) {
    
    let lat1 = self.position.coordinate.latitude.radian
    let lat2 = location2.coordinate.latitude.radian
    let lon1 = self.position.coordinate.longitude.radian
    let lon2 = location2.coordinate.longitude.radian
    
    let omega = lon2 - lon1
    let tanU1 = (1 - f) * tan(lat1)
    let cosU1 = 1 / sqrt(1 + pow(tanU1, 2.0))
    let sinU1 = tanU1 * cosU1
    let tanU2 = (1 - f) * tan(lat2)
    let cosU2 = 1 / sqrt(1 + pow(tanU2, 2.0))
    let sinU2 = tanU2 * cosU2
    
    var lambda = omega
    var lastLambda = omega - 100
    
    var cos2alpha: Double = 0.0
    var sinSigma: Double = 0.0
    var cosSigma: Double = 0.0
    var cos2sm: Double = 0.0
    var sigma: Double = 0.0
    var sinLambda: Double = 0.0
    var cosLambda: Double = 0.0
    
    while abs(lastLambda - lambda) > pow(10, -12.0) {
        
        sinLambda = sin(lambda)
        cosLambda = cos(lambda)
        let sin2sigma = pow(cosU2 * sinLambda, 2.0) + pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2.0)
        sinSigma = sqrt(sin2sigma)
        cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
        sigma = atan(sinSigma/cosSigma)
        let sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
        cos2alpha = 1 - pow(sinAlpha, 2.0)
        if cos2alpha == 0 {
            
            cos2sm = 0
        } else {
            
            cos2sm = cosSigma - 2 * sinU1 * sinU2 / cos2alpha
        }
        let C = f / 16.0 * cos2alpha * (4 + f * (4 - 3 * cos2alpha))
        lastLambda = lambda
        lambda = omega + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2sm + C * cosSigma * (2 * pow(cos2sm, 2.0) - 1)))
    }
    
    let u2 = cos2alpha * (pow(a, 2.0) - pow(b, 2.0)) / pow(b, 2.0)
    let A = 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)))
    let B = u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)))
    let dSigma = B * sinSigma * (cos2sm + B / 4 * (cosSigma * (2 * pow(cos2sm, 2.0) - 1) - B / 6 * cos2sm * (4 * pow(sinSigma, 2.0) - 3) * (4 * pow(cos2sm, 2.0) - 3)))
    
    // Result
    let s = b * A * (sigma - dSigma)
    let a1 = atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda)
    let a2 = atan2(cosU1 * sinLambda, cosU1 * sinU2 * cosLambda - sinU1 * cosU2)
    return (s: s, a1: a1.degree, a2: a2.degree)
}

    
     func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        
        var matrix: matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    func translationMatrix(with matrix: matrix_float4x4, for translation: vector_float4) -> matrix_float4x4 {
        
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    func transformMatrix(for matrix: simd_float4x4) -> simd_float4x4 {
        
        let (s: distance, a1: bearing, a2: _) = self.calcurateDistanceAndAzimuths(location2: self.destination)
        self.distance = distance
        let position = vector_float4(0.0, 0.0, Float(-distance), 0.0)
        let translationMatrix = self.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = self.rotateAroundY(with: matrix_identity_float4x4, for: Float(bearing.radian))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    //目的地のローカル座標を求める（緯度経度から変換）
    func transformDestination() -> SCNVector3{
        let res:simd_float4x4 =  self.transformMatrix(for: matrix_identity_float4x4)
        let newPosition = SCNMatrix4(res)
        return SCNVector3Make(newPosition.m41,newPosition.m42 , newPosition.m43)
    }

}
