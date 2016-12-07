//
//  APIController.swift
//  Flipt-web
//
//  Created by Johann Kerr on 12/5/16.
//
//

import Foundation
import PostgreSQL
import Vapor
import Auth
import HTTP
import Cookies
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Fluent

final class APIController {
    
    let protect = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))
    
    func addRoutes(drop:Droplet){
        drop.grouped(BasicAuthenticationMiddleware(), protect).group("api") { api in
            api.get("myBooks", handler: myBooks)
            api.get("me", handler: respond)
            api.post("book", handler: addBook)
            api.get("search", handler:search)
            api.get("near", handler:near)
            api.get("user", Int.self) { request, userId in
                try self.userbooks(request: request, id: userId)
            }
            
        }
        
    }
    
    func userbooks(request:Request, id:Int) throws -> ResponseRepresentable{
        let books = try Book.query().filter("mainuser_id", id).all()
        
        return try JSON(node: books.makeNode())
    }
    func respond(request: Request) throws -> ResponseRepresentable{
        
        return try JSON(node: request.user().makeNode())
    }
    func near(request:Request) throws -> ResponseRepresentable{
       // 40.719503, -73.985142
        var latitudeRadians = 0.0
        var longitudeRadians = 0.0
        if let latitude = request.data["lat"]?.double, let longitude = request.data["long"]?.double {
            latitudeRadians = latitude * M_PI/180
            longitudeRadians = longitude * M_PI/180
        }
 
        var foundbooks = [Book]()
        findBooks(within: 1609, from: latitudeRadians, longitude: longitudeRadians) { (books) in
            foundbooks = books
        }
  
        return try JSON(node: foundbooks.makeNode())
    }
    
    func search(request: Request) throws -> ResponseRepresentable{
     
        if let titlesearch = request.data["title"]?.string {
            print(titlesearch)
            let searchTerm = titlesearch.replacingOccurrences(of: "+", with: " ")
            let books = try Book.query().filter("title",searchTerm).all()
            
            return try JSON(node:books.makeNode())
        }
        if let isbn = request.data["isbn"]?.string{
            let books = try Book.query().filter("isbn", isbn).all()
            return try JSON(node: books.makeNode())
        }
        return try JSON(node: [])
    }
    func addBook(request: Request) throws -> ResponseRepresentable{
        var title = ""
        var isbn = ""
        var imgUrl = ""
        var latitude = 0.0
        var longtitude = 0.0
        if let titleString = request.data["title"]?.string {
            title = titleString
        }
        if let isbnString = request.data["isbn"]?.string {
            isbn = isbnString
        }
        if let imgUrlString = request.data["imgurl"]?.string {
            imgUrl = imgUrlString
        }
        if let latDouble = request.data["latitude"]?.double{
            latitude = latDouble
        }
        if let longDouble = request.data["longitude"]?.double{
            longtitude = longDouble
        }
        let owner = try request.user()
        
        var book = Book(title: title, isbn: isbn, imgUrl: imgUrl, lat: latitude, long: longtitude, mainuser_id: owner.id!)
        try book.save()
        
        return try JSON(node: book.makeNode())
        
    }
    func myBooks(request: Request) throws -> ResponseRepresentable{
        let user = try request.user()
        if let userId = user.id{
            
            let books = try Book.query().filter("mainuser_id", userId).all()
            return try JSON(node: books.makeNode())
        }
        
        return try JSON(node: Book.all().makeNode())
    }
    
    func findBooks(within distance:Double, from myLat:Double, longitude myLong:Double, completion:([Book])->()){
        
        let radiusOfEarth = 6371.0
        let angularRadius = distance/radiusOfEarth
        print(myLat)
        print(myLong)
//        let lat = 0.0
//        let long = 0.0
        let minLat = myLat - angularRadius
        let maxLat = myLat + angularRadius
        
        let maxT = asin(sin(myLat)/cos(angularRadius))
        
        let deltalon = acos((cos(angularRadius)-sin(maxT)*sin(myLat))/(cos(maxT)*cos(myLat)))
        let minLong = myLong - deltalon
        let maxLong = myLong + deltalon
        
        let postgreSQL = PostgreSQL.Database(dbname: "flipt", user: "johannkerr=", password: "")
        do {

            let books = try Book.query().filter("lat", Filter.Comparison.greaterThan, minLat).filter("lat", Filter.Comparison.lessThan, maxLat).filter("long", Filter.Comparison.greaterThan, minLong).all()
            
            print(books.count)
            
            var nearBooks = [Book]()
            for book in books {
                let booklat = book.lat
                let booklong = book.long
                print(acos(sin(myLat) * sin(booklat) + cos(myLat) * cos(booklat) * cos(booklong - (myLong))))
                print(angularRadius)

                let deltaCheck = acos(sin(myLat) * sin(booklat) + cos(myLat) * cos(booklat) * cos(booklong - (myLong))) <= angularRadius
                if deltaCheck{
                    print("hooray in range")
                    nearBooks.append(book)
                }else{
                    print("nah too far")
                }
            }
            
            completion(nearBooks)
            
//            let version = try postgreSQL.execute("SELECT version()")
//            
//            let results = try postgreSQL.execute("SELECT * FROM books WHERE (lat => $1 AND lat <= $2) AND (lon >= $3 AND lon <= $4) AND acos(sin($5) * sin(lat) + cos($5) * cos(lat) * cos(lon - ($6))) <= $7", [Node(minLat), Node(maxLat), Node(minLong), Node(maxLong), Node(myLat), Node(myLong), Node(angularRadius)])
//            print(results)
//            
//            print(version)
        }catch{
            print("error")
        }
        
        
    }
    
}
