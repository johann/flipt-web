//
//  Book.swift
//  Flipt-web
//
//  Created by Johann Kerr on 11/21/16.
//
//

//
//  Book.swift
//  flatiron-teacher-assistant
//
//  Created by Johann Kerr on 11/15/16.
//
//


import Vapor
import Foundation
import Fluent
import Foundation



final class Book: Model{
    var id: Node?
    var exists: Bool = false
    
    
    
    var title:String
    var isbn:String
    var imgUrl:String
    var mainuser_id: Node?
    var lat:Double
    var long:Double
    
    init(title:String, isbn:String,imgUrl:String,lat:Double,long:Double, mainuser_id:Node?){
        self.id = nil
        self.title = title
        self.isbn = isbn
        self.imgUrl = imgUrl
        self.lat = lat
        self.long = long
        self.mainuser_id = mainuser_id
    }
    

    
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        title = try node.extract("title")
        isbn = try node.extract("isbn")
        imgUrl = try node.extract("imgurl")
        mainuser_id = try node.extract("mainuser_id")
        lat = try node.extract("lat")
        long = try node.extract("long")

    }
    
    func makeNode(context: Context) throws -> Node {
        
        return try Node(node: [
            "id":id,
            "title": title,
            "isbn": isbn,
            "imgUrl": imgUrl,
            "mainuser_id": mainuser_id,
            "lat":lat,
            "long":long
            ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create("books"){ books in
            books.id()
            books.string("title")
            books.string("isbn")
            books.string("imgUrl")
            books.double("lat")
            books.double("long")
            books.parent(MainUser.self, optional: false)
            
            
        }
    }
    
    static func revert(_ database: Database) throws{
        try database.delete("books")
    }
    
}

extension Book {
    func owner() throws -> Parent<MainUser>{
        return try parent(mainuser_id)
    }
    
    func findOwner() throws -> MainUser {
        let owner = try MainUser.query().filter("id", self.mainuser_id!).first()
        return owner!
    }
}




