//
//  FloodImage.swift
//  ToneEditor-iOS
//
//  Created by Анатолий on 07.11.2017.
//  Copyright © 2017 Анатолий. All rights reserved.
//

import UIKit

class FloodImage: UIImageView {
    
    /// Filter Sensitivity
    var tolerance: Int = 100
    /// Pixel target color
    var newColor: UIColor = .blue
    /// Image setter
    var originImage: UIImage? {
        didSet {
            self.image = originImage
            self.setup()
        }
    }
    /// Touch position
    var pos = CGPoint(x: 150, y: 150)
    /// Includes anti-aliasing effect
    let antiAlias = false
    /// Representation of image data as an UInt8 Array
    var pixelData = [UInt8]()
    /// Workspace of changing image data
    var context: CGContext!
    /// Representation UIImage in CGImage
    var cgImage: CGImage!
    
    /// Linked List
    var point = LinkedList<PointNode>()
    var antiAliasingPoints = LinkedList<PointNode>()
    
    /// Color
    var ncolor: UInt!
    /// Color
    var ocolor: UInt!
    
    // New data color value's
    var newRed: UInt8 = 0
    var newGreen: UInt8 = 0
    var newBlue: UInt8 = 0
    var newAlpha: UInt8 = 0
    
    
    var bytesPerRow: Int!
    var bytesPerPixel: Int!
    var byteIndex: Int!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let tapLocation = event?.allTouches?.first?.location(in: self)
        pos = CGPoint(x: ((originImage?.size.width)!/self.bounds.size.width)*(tapLocation?.x)!,
                      y: ((originImage?.size.height)!/self.bounds.size.height)*(tapLocation?.y)!)
        point.removeAll()
        antiAliasingPoints.removeAll()
        
        self.image = fillNewColor()
    }
    
    //MARK: -Setup image data-
    /// Extracting time-consuming data from an image
    fileprivate func setup () {
        imageData ()
        createNColor ()
        setupAlgoritm()
    }
    
    fileprivate func imageData () {
        let size = originImage!.size
        let dataSize = size.width * size.height * 4
        pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        
        context = CGContext(data: &pixelData,
                            width: Int(size.width),
                            height: Int(size.height),
                            bitsPerComponent: 8,
                            bytesPerRow: 4 * Int(size.width),
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        cgImage = originImage?.cgImage
        context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        cgImage = originImage?.cgImage
    }
    
    fileprivate func createNColor () {
        let components = newColor.cgColor.components!
        if newColor.cgColor.numberOfComponents == 2 {
            newBlue = UInt8(components[0] * 255)
            newGreen = newBlue
            newRed = newGreen
            newAlpha = UInt8(components[1] * 255)
        } else if newColor.cgColor.numberOfComponents == 4 {
            newRed = UInt8(components[0] * 255)
            newGreen = UInt8(components[1] * 255)
            newBlue = UInt8(components[2] * 255)
            newAlpha = 255
        }
        let tempRed =  UInt(newRed)
        let tempGreen =  UInt(newGreen)
        let tempBlue =  UInt(newBlue)
        let tempAlpha =  UInt(newAlpha)
        ncolor = (tempRed << 24) | (tempGreen << 16) | (tempBlue << 8) | tempAlpha
    }
    
    fileprivate func setupAlgoritm() {
        bytesPerRow = Int(4 * originImage!.size.width)
        bytesPerPixel = (cgImage?.bitsPerPixel)!/8
        byteIndex = (bytesPerRow! * Int(pos.y)) + Int(pos.x) * bytesPerPixel
        //        let pixelDataByte = Data(bytes: pixelData, count: (cgImage?.bitsPerComponent)! * bytesPerPixel * Int(bytesPerRow))
        ocolor = getColorCode(byteIndex!, pixelData)
    }
    
    //MARK: -Algoritm-
    
    fileprivate func fillNewColor () -> UIImage {

        let pixelColor = getPixelColor(pos: pos)
        var color: UInt = 0
        var spanLeft = false
        var spanRight = false
        var x = Int(pos.x)
        var y = Int(pos.y)
        
        if point.isEmpty {
            point.append(PointNode(pointX: Int(x), pointY: Int(y)))
            while let points = point.removeLast() {
                (x, y) = points.getPoints
                
                byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                color = getColorCode(byteIndex, pixelData)
                // Цикл уменьшения байтов в массиве
                while y >= 0 && compareColor(ocolor, color, tolerance) {
                    y = y - 1
                    if y >= 0 {
                        byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                        color = getColorCode(byteIndex, pixelData)
                    }
                }
                // Add the top most point on the antialiasing list
                if y >= 0 && !compareColor(ocolor, color, 0) {
                    antiAliasingPoints.append(PointNode(pointX: Int(x), pointY: Int(y)))
                }
                y = y + 1
                spanRight = false
                spanLeft = false
                byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                color = getColorCode(byteIndex, pixelData)
                
                while y < (cgImage?.height)! && compareColor(ocolor, color, tolerance) && ncolor != color {
                    pixelData[byteIndex] = UInt8(newRed)
                    pixelData[byteIndex+1] = UInt8(newGreen)
                    pixelData[byteIndex+2] = UInt8(newBlue)
                    pixelData[byteIndex+3] = UInt8(newAlpha)
                    
                    if x > 0 {
                        byteIndex = (bytesPerRow * y) + (x-1) * bytesPerPixel
                        color = getColorCode(byteIndex, pixelData)
                        
                        if !spanLeft && x > 0 && compareColor(ocolor, color, tolerance) {
                            point.append(PointNode(pointX: Int(x-1), pointY: Int(y)))
                            spanLeft = true
                        } else if spanLeft && x > 0 && !compareColor(ocolor, color, tolerance) {
                            spanLeft = false
                        }
                        
                        if !spanLeft && x > 0 && !compareColor(ocolor, color, tolerance) && !compareColor(ncolor, color, tolerance) {
                            antiAliasingPoints.append(PointNode(pointX: Int(x-1), pointY: Int(y)))
                        }
                    }
                    
                    if x < (cgImage?.width)! - 1 {
                        byteIndex = (bytesPerRow * y) + (x+1) * bytesPerPixel
                        color = getColorCode(byteIndex, pixelData)
                        
                        if !spanRight && compareColor(ocolor, color, tolerance) {
                            point.append(PointNode(pointX: Int(x+1), pointY: Int(y)))
                            spanRight = true
                        } else if spanRight && !compareColor(ocolor, color, tolerance) {
                            spanRight = false
                        }
                        
                        if !spanRight && !compareColor(ocolor, color, tolerance) && !compareColor(ncolor, color, tolerance) {
                            antiAliasingPoints.append(PointNode(pointX: Int(x+1), pointY: Int(y)))
                        }
                    }
                    
                    y = y + 1
                    
                    if y < (cgImage?.height)! {
                        byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                        color = getColorCode(byteIndex, pixelData)
                    }
                }
                if y < (cgImage?.height)! {
                    byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                    color = getColorCode(byteIndex, pixelData)
                    if !compareColor(ocolor, color, 0) {
                        antiAliasingPoints.append(PointNode(pointX: Int(x), pointY: Int(y)))
                    }
                }
            }
        }
        
        var antialiasColor: UInt = getColorCodeFromUIColor(newColor)
        let red1 = (0xff000000 & antialiasColor) >> 24
        let green1 = (0x00ff0000 & antialiasColor) >> 16
        let blue1 = (0x0000ff00 & antialiasColor) >> 8
        let alpha1 = 0x000000ff & antialiasColor
        
        while let pointsAlias = antiAliasingPoints.removeLast() {
            (x, y) = pointsAlias.getPoints
            
            byteIndex = (bytesPerRow * y) + x * bytesPerPixel
            color = getColorCode(byteIndex, pixelData)
            
            func compareColorInBytes() {
                let red2 = (0xff000000 & color) >> 24
                let green2 = (0x00ff0000 & color) >> 16
                let blue2 = (0x0000ff00 & color) >> 8
                let alpha2 = 0x000000ff & color
                if antiAlias {
                    pixelData[byteIndex] = UInt8((red1 + red2) / 2)
                    pixelData[byteIndex + 1] = UInt8((green1 + green2) / 2)
                    pixelData[byteIndex + 2] = UInt8((blue1 + blue2) / 2)
                    pixelData[byteIndex + 3] = UInt8((alpha1 + alpha2) / 2)
                } else {
                    pixelData[byteIndex] = UInt8(red2)
                    pixelData[byteIndex + 1] = UInt8(green2)
                    pixelData[byteIndex + 2] = UInt8(blue2)
                    pixelData[byteIndex + 3] = UInt8(alpha2)
                }
                pixelData[byteIndex + 0] = 255
                pixelData[byteIndex + 1] = 255
                pixelData[byteIndex + 2] = 255
                pixelData[byteIndex + 3] = 255
            }
            
            if !compareColor(ncolor, color, 0) {
                compareColorInBytes()
            }
            
            if x > 0 {
                byteIndex = (bytesPerRow * y) + (x-1) * bytesPerPixel
                color = getColorCode(byteIndex, pixelData)
                
                if !compareColor(ncolor, color, 0) {
                    compareColorInBytes()
                }
            }
            
            if x < cgImage.width {
                byteIndex = (bytesPerRow * y) + (x+1) * bytesPerPixel
                color = getColorCode(byteIndex, pixelData)
                if !compareColor(ncolor, color, 0) {
                    compareColorInBytes()
                }
            }
            
            if y > 0 {
                byteIndex = (bytesPerRow * (y - 1)) + x * bytesPerPixel
                color = getColorCode(byteIndex, pixelData)
                if !compareColor(ncolor, color, 0) {
                    compareColorInBytes()
                }
            }
            y = y + 1
            if y < cgImage.height {
                byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                color = getColorCode(byteIndex, pixelData)
                if !compareColor(ncolor, color, 0) {
                    compareColorInBytes()
                }
            }
        }
       
        // Create Image from Data
        let newCGImage = context?.makeImage()
        antiAliasingPoints.removeAll()
        return UIImage(cgImage: newCGImage!, scale: originImage!.scale, orientation: .up)
    }
    
    fileprivate func getColorCode(_ byteIndex: Int,_ pixelData: [UInt8]) -> UInt {
        let red = UInt(pixelData[byteIndex])
        let green = UInt(pixelData[byteIndex + 1])
        let blue = UInt(pixelData[byteIndex + 2])
        let alpha = UInt(pixelData[byteIndex + 3])
        return (red<<24 | green<<16 | blue<<8 | alpha)
    }
    
    fileprivate func getColorCodeFromUIColor(_ color: UIColor) -> UInt {
        //Convert newColor to RGBA value so we can save it to image.
        let newColor = CIColor(color: color)
        let newRed = UInt(newColor.red * 255 + 0.5)
        let newBlue = UInt(newColor.blue * 255 + 0.5)
        let newGreen = UInt(newColor.green * 255 + 0.5)
        let newAlpha = UInt(newColor.alpha * 255 + 0.5)
        return ((newRed << 24) | (newGreen << 16) | (newBlue << 8) | newAlpha)
    }
    
    fileprivate func compareColor(_ color1: UInt,_ color2: UInt,_ tolorance: Int) -> Bool {
        if color1 == color2 {
            return true
        }
    
        let red1 = (0xff000000 & color1) >> 24
        let green1 = (0x00ff0000 & color1) >> 16
        let blue1 = (0x0000ff00 & color1) >> 8
        let alpha1 = 0x000000ff & color1
        let red2 = (0xff000000 & color2) >> 24
        let green2 = (0x00ff0000 & color2) >> 16
        let blue2 = (0x0000ff00 & color2) >> 8
        let alpha2 = 0x000000ff & color2
        
        let diffRed = (red1>red2 ? red1-red2 : red2-red1)
        let diffGreen = (green1>green2 ? green1-green2 : green2-green1)
        let diffBlue = (blue1>blue2 ? blue1-blue2 : blue2-blue1)
        let diffAlpha = (alpha1>alpha2 ? alpha1-alpha2 : alpha2-alpha1)
        if diffRed > tolorance || diffGreen > tolorance || diffBlue > tolorance || diffAlpha > tolorance {
            return false
        }
        return true
    }
    
    fileprivate func getPixelColor(pos: CGPoint) -> UIColor {
        let pixelData = originImage?.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let pixelInfo = Int((((originImage?.size.width)! * pos.y) + pos.x) * 4)
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}


