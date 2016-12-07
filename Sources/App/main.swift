import Vapor
import VaporPostgreSQL
import Auth
import HTTP
import Cookies
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Fluent
import Foundation

let drop = Droplet()
let auth = AuthMiddleware<MainUser>()
let database = Database(MemoryDriver())


try drop.addProvider(VaporPostgreSQL.Provider.self)
drop.preparations += Book.self
drop.preparations += MainUser.self

//drop.database = database

drop.middleware += auth
drop.middleware += TrustProxyMiddleware()

let bookController = BookController()
bookController.addRoutes(drop: drop)
let userController = UserController()
userController.addRoutes(drop: drop)
let apiController = APIController()
apiController.addRoutes(drop: drop)




func respond(request: Request) throws -> ResponseRepresentable{
    
    //    if let apiKey = request.auth.header?.basic {
    //
    //
    //        let mainuser = try MainUser.authenticate(credentials: apiKey)
    //        try? request.auth.login(apiKey, persist: true)
    //
    //        try print(request.user().username)
    //        //try? request.auth.login(apiKey, persist: false)
    //        //try? request.auth.login(apiKey, persist: false)
    //        return try JSON(node: mainuser.makeNode())
    //    }
    try print(request.user().username)
    //return try JSON(node: MainUser.query().all().makeNode())
    return try JSON(node: request.user().makeNode())
    
    //return try drop.view.make("register")
}

//drop.group("api"){ api in
//    api.get("me", handler: respond)
//}

drop.get("users"){ request in
    
    return try JSON(node:MainUser.all().makeNode())
    
}








//drop.get("/"){ req in
//
//    return try JSON(node:Book.all().makeNode())
//
//}



drop.get("susan"){ req in
    return try JSON(node: ["hey":"susan"])
}









drop.run()
