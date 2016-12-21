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
    var publisher: String
    var author: String
    var description: String
    var publishYear: String
    var lat:Double
    var long:Double
    

    init(title:String, isbn:String,imgUrl:String, lat:Double,long:Double, mainuser_id:Node?, publisher:String, author:String, description:String, publishYear:String){
        self.id = nil
        self.title = title
        self.isbn = isbn
        self.imgUrl = imgUrl
        self.publisher = publisher
        self.author = author
        self.description = description
        self.publishYear = publishYear
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
        publisher = try node.extract("publisher")
        author = try node.extract("author")
        description = try node.extract("description")
        publishYear = try node.extract("publishyear")
    
 
    }
    
    
    func makeNode(context: Context) throws -> Node {
        print("getting called")
        return try Node(node: [
            "id":id,
            "title": title,
            "isbn": isbn,
            "imgUrl": imgUrl,
            "mainuser_id": mainuser_id,
            "lat":lat,
            "long":long,
            "publisher":publisher,
            "author":author,
            "description": description,
            "publishYear":publishYear
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
            books.string("publisher")
            books.string("author")
            books.string("description")
            books.string("publishYear")
            
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
    
    func findOwner() throws -> MainUser? {
        if let owner = try MainUser.query().filter("id", self.mainuser_id!).first() {
            return owner
        }
        return nil
    }
    
}




