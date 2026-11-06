# Web API example (mocked)

let users = @GET "api/users"
print("Users: {users}")

let user = @GET "api/users/1"
print("User 1: {user}")

let new_user = @POST "api/users" { name: "Alice", age: 30 }
print("Created: {new_user}")
