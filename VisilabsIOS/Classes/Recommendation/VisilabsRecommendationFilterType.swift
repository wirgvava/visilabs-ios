//
//  VisilabsRecommendationFilterType.swift
//  VisilabsIOS
//
//  Created by Egemen on 29.06.2020.
//

public enum VisilabsRecommendationFilterType: Int {
    case equals = 0
    case notEquals = 1
    case like = 2
    case notLike = 3
    case greaterThan = 4
    case lessThan = 5
    case greaterOrEquals = 6
    case lessOrEquals = 7
    
    static let include = like
    static let exclude = notLike
}

public enum VisilabsProductAttribute: String {
    case title
    case img
    case code
    case dest_url
    case brand
    case price
    case dprice
    case cur
    case rating
    case comment
    case freeshipping
    case samedayshipping
    case attr1
    case attr2
    case attr3
    case attr4
    case attr5
}

public class VisilabsRecommendationFilter {
    var attribute: VisilabsProductAttribute
    var filterType: VisilabsRecommendationFilterType
    var value: String
    
    init(attribute: VisilabsProductAttribute, filterType: VisilabsRecommendationFilterType, value: String){
        self.attribute = attribute
        self.filterType = filterType
        self.value = value
    }
}

public class VisilabsProduct {
    public var code: String
    public var title: String
    public var img: String
    public var dest_url: String
    public var brand: String
    public var price: Double
    public var dprice: Double
    public var cur: String
    public var dcur: String
    public var freeshipping: Bool
    public var samedayshipping: Bool
    public var rating: Int
    public var comment: Int
    public var discount: Double
    public var attr1: String
    public var attr2: String
    public var attr3: String
    public var attr4: String
    public var attr5: String
    
    internal init(code: String, title: String, img: String, dest_url: String, brand: String, price: Double, dprice: Double, cur: String, dcur: String, freeshipping: Bool, samedayshipping: Bool, rating: Int, comment: Int, discount: Double, attr1: String, attr2: String, attr3: String, attr4: String, attr5: String) {
        self.code = code
        self.title = title
        self.img = img
        self.dest_url = dest_url
        self.brand = brand
        self.price = price
        self.dprice = dprice
        self.cur = cur
        self.dcur = dcur
        self.freeshipping = freeshipping
        self.samedayshipping = samedayshipping
        self.rating = rating
        self.comment = comment
        self.discount = discount
        self.attr1 = attr1
        self.attr2 = attr2
        self.attr3 = attr3
        self.attr4 = attr4
        self.attr5 = attr5
    }
}

public class VisilabsRecommendationResponse {
    public var products: [VisilabsProduct]
    public var error: VisilabsReason?
    
    internal init(products: [VisilabsProduct], error: VisilabsReason? = nil) {
        self.products = products
        self.error = error
    }
}
