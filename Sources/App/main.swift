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


drop.get("users"){ request in
    
    return try JSON(node:MainUser.all().makeNode())
    
}

drop.run()
