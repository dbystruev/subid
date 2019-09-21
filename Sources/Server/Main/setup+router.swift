//
//  setup+router.swift
//
//  Created by Denis Bystruev on 21/09/2019.
//

import Foundation
import Kitura
import KituraStencil
import LoggerAPI

// MARK: - Setup Router
func setup(_ router: Router) {
    router.setDefault(templateEngine: StencilTemplateEngine())
    
    // MARK: - GET /
    router.get("/") { request, response, next in
        try response.render("home", context: [:])
        next()
    }
    
    // MARK: - GET /categories
    router.get("/categories") { request, response, next in
        var categories = catalog.shop?.categories
        
        // MARK: "id"
        if let id = request.queryParameters["id"] {
            categories = categories?.filter { $0.id == Int(id) }
        }
        
        // MARK: "name"
        if let name = request.queryParameters["name"] {
            categories = categories?.filter { $0.name?.lowercased().contains(name.lowercased()) == true }
        }
        
        // MARK: "parentId"
        if let parentId = request.queryParameters["parentId"] {
            categories = categories?.filter { $0.parentId == Int(parentId) }
        }
        
        // MARK: "count"
        if request.queryParameters["count"] == nil {
            response.send(json: categories)
        } else {
            response.send(json: ["count": categories?.count])
        }
        
        next()
    }
    
    // MARK: - GET /currencies
    router.get("/currencies") { request, response, next in
        let currencies = catalog.shop?.currencies
        
        // MARK: "count"
        if request.queryParameters["count"] == nil {
            response.send(json: currencies)
        } else {
            response.send(json: ["count": currencies?.count])
        }
        
        next()
    }
    
    // MARK: - GET /date
    router.get("/date") { request, response, next in
        response.send(json: ["date": catalog.date?.toString])
        next()
    }
    
    // MARK: - GET /images
    router.get("/images") { request, response, next in
        let images = Set(catalog.shop?.offers.flatMap { $0.pictures } ?? [])
        
        // MARK: "count"
        if request.queryParameters["count"] == nil {
            response.send(json: images)
        } else {
            response.send(json: ["count": images.count])
        }
        
        next()
    }
    
    // MARK: - GET /offers
    router.get("/offers") { request, response, next in
        var offers = catalog.shop?.offers
        
        // Show only available offers by default
        if request.queryParameters["available"] == nil && request.queryParameters["deleted"] == nil {
            offers = offers?.filter { $0.available == true }
        } else {
            // MARK: "available"
            if let available = request.queryParameters["available"] {
                offers = offers?.filter { $0.available == Bool(available) }
            }
            
            // MARK: "deleted"
            if let deleted = request.queryParameters["deleted"] {
                offers = offers?.filter { $0.deleted == Bool(deleted) }
            }
        }
        
        // MARK: "id"
        if let id = request.queryParameters["id"] {
            offers = offers?.filter { $0.id?.lowercased() == id.lowercased() }
        }
        
        // MARK: "categoryId"
        if let categoryId = request.queryParameters["categoryId"] {
            offers = offers?.filter { $0.categoryId == Int(categoryId) }
        }
        
        // MARK: "currencyId"
        if let currencyId = request.queryParameters["currencyId"] {
            offers = offers?.filter { $0.currencyId?.lowercased() == currencyId.lowercased() }
        }
        
        // MARK: "description"
        if let description = request.queryParameters["description"] {
            offers = offers?.filter { $0.description?.lowercased().contains(description.lowercased()) == true }
        }
        
        // MARK: "manufacturer_warranty"
        if let manufacturer_warranty = request.queryParameters["manufacturer_warranty"] {
            offers = offers?.filter { $0.manufacturer_warranty == Bool(manufacturer_warranty) }
        }
        
        // MARK: "model"
        if let model = request.queryParameters["model"] {
            offers = offers?.filter { $0.model?.lowercased().contains(model.lowercased()) == true }
        }
        
        // MARK: "modified_after"
        if let modified_after = request.queryParameters["modified_after"] {
            if let userTime = TimeInterval(modified_after) {
                offers = offers?.filter { offer in
                    guard let offerTime = offer.modified_time else { return false }
                    return userTime <= offerTime
                }
            }
        }
        
        // MARK: "modified_before"
        if let modified_before = request.queryParameters["modified_before"] {
            if let userTime = TimeInterval(modified_before) {
                offers = offers?.filter { offer in
                    guard let offerTime = offer.modified_time else { return false }
                    return offerTime <= userTime
                }
            }
        }
        
        // MARK: "modified_time"
        if let modified_time = request.queryParameters["modified_time"] {
            offers = offers?.filter { $0.modified_time == TimeInterval(modified_time) }
        }
        
        // MARK: "name"
        if let name = request.queryParameters["name"] {
            offers = offers?.filter { $0.name?.lowercased().contains(name.lowercased()) == true }
        }
        
        // MARK: "oldprice"
        if let oldprice = request.queryParameters["oldprice"] {
            offers = offers?.filter { $0.oldprice == Decimal(string: oldprice) }
        }
        
        // MARK: "oldprice_above"
        if let oldprice_above = request.queryParameters["oldprice_above"] {
            if let userOldPrice = Decimal(string: oldprice_above) {
                offers = offers?.filter { offer in
                    guard let offerOldPrice = offer.oldprice else { return false }
                    return userOldPrice <= offerOldPrice
                }
            }
        }
        
        // MARK: "oldprice_below"
        if let oldprice_below = request.queryParameters["oldprice_below"] {
            if let userOldPrice = Decimal(string: oldprice_below) {
                offers = offers?.filter { offer in
                    guard let offerOldPrice = offer.oldprice else { return false }
                    return offerOldPrice <= userOldPrice
                }
            }
        }
        
        // MARK: "{params}"
        if let paramNames = offers?.flatMap({ $0.params.compactMap({ param in param.name?.lowercased() }) }) {
            for name in Set(paramNames) {
                if let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    if let value = request.queryParameters[encodedName]?.lowercased() {
                        offers = offers?.filter { offer in
                            for param in offer.params {
                                if param.name?.lowercased() == name && param.value?.lowercased() == value {
                                    return true
                                }
                            }
                            return false
                        }
                    }
                }
            }
        }
        
        // MARK: "picture"
        if let picture = request.queryParameters["picture"] {
            offers = offers?.filter { offer in
                for url in offer.pictures {
                    if url.absoluteString.lowercased().contains(picture.lowercased()) { return true }
                }
                return false
            }
        }
        
        // MARK: "price"
        if let price = request.queryParameters["price"] {
            offers = offers?.filter { $0.price == Decimal(string: price) }
        }
        
        // MARK: "price_above"
        if let price_above = request.queryParameters["price_above"] {
            if let userPrice = Decimal(string: price_above) {
                offers = offers?.filter { offer in
                    guard let offerPrice = offer.price else { return false }
                    return userPrice <= offerPrice
                }
            }
        }
        
        // MARK: "price_below"
        if let price_below = request.queryParameters["price_below"] {
            if let userPrice = Decimal(string: price_below) {
                offers = offers?.filter { offer in
                    guard let offerPrice = offer.price else { return false }
                    return offerPrice <= userPrice
                }
            }
        }
        
        // MARK: "sales_notes"
        if let sales_notes = request.queryParameters["sales_notes"] {
            offers = offers?.filter { $0.sales_notes?.lowercased().contains(sales_notes.lowercased()) == true }
        }
        
        // MARK: "typePrefix"
        if let typePrefix = request.queryParameters["typePrefix"] {
            offers = offers?.filter { $0.typePrefix?.lowercased().contains(typePrefix.lowercased()) == true }
        }
        
        // MARK: "url"
        if let url = request.queryParameters["url"] {
            offers = offers?.filter { $0.url?.absoluteString.lowercased().contains(url.lowercased()) == true }
        }
        
        // MARK: "vendor"
        if let vendor = request.queryParameters["vendor"] {
            offers = offers?.filter { $0.vendor?.lowercased().contains(vendor.lowercased()) == true }
        }
        
        // MARK: "vendorCode"
        if let vendorCode = request.queryParameters["vendorCode"] {
            offers = offers?.filter { $0.vendorCode?.lowercased() == vendorCode.lowercased() }
        }
        
        if request.queryParameters["count"] == nil {
            response.send(json: offers)
            // MARK: "count"
        } else {
            response.send(json: ["count": offers?.count])
        }
        
        next()
    }
    
    // MARK: - GET /offers/modified_times
    router.get("/offers/modified_times") { request, response, next in
        let offers = catalog.shop?.offers
        
        if
            let modifiedTimes = offers?.compactMap({ $0.modified_time }),
            let minTime = modifiedTimes.min(),
            let maxTime = modifiedTimes.max()
        {
            #if DEBUG
            Log.debug("Min Time: \(minTime), Max Time: \(maxTime)")
            #endif
            
            response.send(json: ["modified_time_min": minTime, "modified_time_max": maxTime])
        }
        
        next()
    }
    
    // MARK: "/offers/prices"
    router.get("/offers/prices") { request, response, next in
        let offers = catalog.shop?.offers
        
        if
            let priceRange = offers?.compactMap({ $0.price }),
            let minPrice = priceRange.min(),
            let maxPrice = priceRange.max()
        {
            #if DEBUG
            Log.debug("Min Price: \(minPrice), Max Price: \(maxPrice)")
            #endif
            
            response.send(json: ["price_min": minPrice, "price_max": maxPrice])
        }
        
        next()
    }
    
    // MARK: - GET /params
    router.get("/params") { request, response, next in
        let isNotCounting = request.queryParameters["count"] == nil
        let offers = catalog.shop?.offers
        
        if let paramNames = offers?.flatMap({ $0.params.compactMap({ param in param.name?.lowercased() }) }) {
            let names = Set(paramNames)
            
            // MARK: "count"
            if isNotCounting {
                response.send(json: names)
            } else {
                response.send(json: ["count": names.count])
            }
        } else {
            if isNotCounting {
                response.send(json: Set<String>())
            } else {
                response.send(json: ["count": 0])
            }
        }
        
        next()
    }
    
    // MARK: - GET /stylist
    router.get("/stylist") { request, response, next in
        guard let subid = request.queryParameters["subid"] else {
            try response.status(.badRequest).end()
            return
        }
        
        Log.info("Generated links for subid: \(subid)")
        
        try response.render("stylist", context: ["subid": subid])
        
        next()
    }
    
    // MARK: - GET /update
    router.get("/update") { request, response, next in
        let yesterday = Date().addingTimeInterval(-86400)
        
        guard let updatedCatalogDate = catalog.date, updatedCatalogDate < yesterday else {
            response.send(json: ["date": catalog.date?.toString])
            next()
            return
        }
        
        xmlManager.lastImport = updatedCatalogDate
        updateCatalogFromRemote { remoteCatalog, error in
            if let error = error { Log.error(error.localizedDescription) }
            if let remoteCatalog = remoteCatalog { catalog.update(with: remoteCatalog) }
            #if DEBUG
            Log.debug(
                "Updated catalog from remote \(catalog)"
            )
            #endif
            
            save(catalog)
            response.send(json: ["date": catalog.date?.toString])
            next()
        }
    }
}