//
//  VisilabsCarouselItem.swift
//  VisilabsIOS
//
//  Created by Egemen Gülkılık on 2.02.2022.
//

import UIKit

// swiftlint:disable type_body_length
public class VisilabsCarouselItem {
    
    public enum PayloadKey {
        public static let imageUrlString = "image"
        public static let title = "title"
        public static let titleColor = "title_color"
        public static let titleFontFamily = "title_font_family"
        public static let title_custom_font_family_ios = "title_custom_font_family_ios"
        public static let title_textsize = "title_textsize"
        public static let body = "body"
        public static let body_color = "body_color"
        public static let body_font_family = "body_font_family"
        public static let body_custom_font_family_ios = "body_custom_font_family_ios"
        public static let body_textsize = "body_textsize"
        public static let promocode_type = "promocode_type"
        public static let promotion_code = "promotion_code"
        public static let promocode_background_color = "promocode_background_color"
        public static let promocode_text_color = "promocode_text_color"
        public static let button_text = "button_text"
        public static let button_text_color = "button_text_color"
        public static let button_color = "button_color"
        public static let button_font_family = "button_font_family"
        public static let button_custom_font_family_ios = "button_custom_font_family_ios"
        public static let button_textsize = "button_textsize"
        public static let background_image = "background_image"
        public static let background_color = "background_color"
        public static let ios_lnk = "ios_lnk"
    }
    
    public let imageUrlString: String?
    public let title: String?
    public let titleColor: UIColor?
    public let titleFontFamily: String?
    public let titleCustomFontFamily: String?
    public let titleTextsize: String?
    public let body: String?
    public let bodyColor: String?
    public let bodyFontFamily: String?
    public let bodyCustomFontFamily: String?
    public let bodyTextsize: String?
    public let promocodeType: String?
    public let promotionCode: String?
    public let promocodeBackgroundColor: String?
    public let promocodeTextColor: String?
    public let buttonText: String?
    public let buttonTextColor: String?
    public let buttonColor: String?
    public let buttonFontFamily: String?
    public let buttonCustomFontFamily: String?
    public let buttonTextsize: String?
    public let backgroundImage: String?
    public let backgroundColor: String?
    public let link: String?
    
    public init(imageUrlString: String?, title: String?, titleColor: String?, titleFontFamily: String?, titleCustomFontFamily: String?
                ,titleTextsize: String?, body: String?, bodyColor: String?, bodyFontFamily: String?, bodyCustomFontFamily: String?
                ,bodyTextsize: String?, promocodeType: String?, promotionCode: String?, promocodeBackgroundColor: String?
                ,promocodeTextColor: String?, buttonText: String?, buttonTextColor: String?, buttonColor: String?
                ,buttonFontFamily: String?, buttonCustomFontFamily: String?, buttonTextsize: String?, backgroundImage: String?
                ,backgroundColor:String?, link: String?) {
        self.imageUrlString = imageUrlString
        self.title = title
        self.titleColor = UIColor(hex: titleColor)
        self.titleFontFamily = titleFontFamily
        self.titleCustomFontFamily = titleCustomFontFamily
        self.titleTextsize = titleTextsize
        self.body = body
        self.bodyColor = bodyColor
        self.bodyFontFamily = bodyFontFamily
        self.bodyCustomFontFamily = bodyCustomFontFamily
        self.bodyTextsize = bodyTextsize
        self.promocodeType = promocodeType
        self.promotionCode = promotionCode
        self.promocodeBackgroundColor = promocodeBackgroundColor
        self.promocodeTextColor = promocodeTextColor
        self.buttonText = buttonText
        self.buttonTextColor = buttonTextColor
        self.buttonColor = buttonColor
        self.buttonFontFamily = buttonFontFamily
        self.buttonCustomFontFamily = buttonCustomFontFamily
        self.buttonTextsize = buttonTextsize
        self.backgroundImage = backgroundImage
        self.backgroundColor = backgroundColor
        self.link = link
    }
    
    // swiftlint:disable function_body_length disable cyclomatic_complexity
    public init?(JSONObject: [String: Any]?) {
        guard let object = JSONObject else {
            VisilabsLogger.error("carouselitem json object should not be nil")
            return nil
        }
        
        self.imageUrlString = object[PayloadKey.imageUrlString] as? String
        self.title = object[PayloadKey.title] as? String
        self.titleColor = UIColor(hex: object[PayloadKey.titleColor] as? String)
        self.titleFontFamily = object[PayloadKey.titleFontFamily] as? String
        self.titleCustomFontFamily = object[PayloadKey.title_custom_font_family_ios] as? String
        self.titleTextsize = object[PayloadKey.title_textsize] as? String
        self.body = object[PayloadKey.body] as? String
        self.bodyColor = object[PayloadKey.body_color] as? String
        self.bodyFontFamily = object[PayloadKey.body_font_family] as? String
        self.bodyCustomFontFamily = object[PayloadKey.body_custom_font_family_ios] as? String
        self.bodyTextsize = object[PayloadKey.body_textsize] as? String
        self.promocodeType = object[PayloadKey.promocode_type] as? String
        self.promotionCode = object[PayloadKey.promotion_code] as? String
        self.promocodeBackgroundColor = object[PayloadKey.promocode_background_color] as? String
        self.promocodeTextColor = object[PayloadKey.promocode_text_color] as? String
        self.buttonText = object[PayloadKey.button_text] as? String
        self.buttonTextColor = object[PayloadKey.button_text_color] as? String
        self.buttonColor = object[PayloadKey.button_color] as? String
        self.buttonFontFamily = object[PayloadKey.button_font_family] as? String
        self.buttonCustomFontFamily = object[PayloadKey.button_custom_font_family_ios] as? String
        self.buttonTextsize = object[PayloadKey.button_textsize] as? String
        self.backgroundImage = object[PayloadKey.background_image] as? String
        self.backgroundColor = object[PayloadKey.background_color] as? String
        self.link = object[PayloadKey.ios_lnk] as? String
    }
}

