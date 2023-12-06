import ballerina/http;

type User readonly & record {|
    int id;
    string email;
    string password;
|};

type ErrorDetails record {
    string message;
    string details;
    string status;
};

type UserNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};
type Details record {
    string message;
    string details;
};

type UserExist record {|
    *http:Conflict;
    Details body; 
|};

type userEmail record {
    string email;
};

type newUser record {|
    string email;
    string password;
|};

type loggedUser record {
    string password;
    string email;
};

table<User> key(id) users = table [
    {id: 1,  email: "john@gmail.com", password: "test123"},
    {id: 2,  email: "gerry@gmail.com", password: "test321"},
    {id: 3,  email: "jonny@gmail.com", password: "321test"}
];

service / on new http:Listener(9090) {

    resource function get users() returns User[] | error {
        return users.toArray();
    }

    resource function get users/[int id]() returns User | UserNotFound | error {
        User? user = users[id];
        if user is () {
            UserNotFound userNotFound = {
                body: {
                    message: string `id: ${id}`, 
                    details: string `user not exist`,
                    status: string `Not Found(404)`
                }
            };

            return userNotFound;
        }

        return user;
    }
    
    resource function post users(newUser newUser) returns http:Created | UserExist | error {
       boolean findUser = users.toArray().some(user => user.email === newUser.email);
       if findUser is false {
        users.add({id: users.length() + 1, ...newUser});
       
        return http:CREATED;
        }

        UserExist userExist = {
            body: {
                message: string `Cannot create new user`,
                details: string `Such email or username already exist`
            }
        };

        return userExist;
    }

    resource function post auth/login(loggedUser loggedUser) returns  http:Ok | http:Unauthorized | error{
        User? user = users.toArray().filter(userInTable => userInTable.email === loggedUser.email)[0];
        if user is () {
            return http:UNAUTHORIZED;
        }

        if (user is User && user.password == loggedUser.password) {
            return http:OK;
        } else {
              return http:UNAUTHORIZED;
        }
    }

    resource function post users/resetPassword(userEmail userEmail) returns http:Accepted | http:BadRequest {
        boolean user = users.toArray().some(lookingUser => lookingUser.email === userEmail.email);
        if user is true {
            return http:ACCEPTED;
        } else {
            return http:BAD_REQUEST;
        }
    }

}