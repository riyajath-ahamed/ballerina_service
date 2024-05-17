import ballerina/http;
import ballerina/uuid;
import ballerinax/prometheus as _;

// Define a global variable to store book data
map<json> books = {};



service /bookstore on new http:Listener(9091) {

    // HTTP GET method to retrieve all books
    resource function get allBooks(http:Caller caller, http:Request req) returns error? {
        json[] bookList = [];
        foreach var [bookId, book] in books.entries() {
            // Include the bookId in the response
            bookList.push({id: bookId, details: book});
        }
        check caller->respond(bookList);
    }


    // HTTP GET method to retrieve a specific book by ID
    resource function get books/[string bookId](http:Caller caller, http:Request req) returns error? {
        json? book = books[bookId];
        if (book == null) {
            http:Response resp = new;
            resp.statusCode = 404;
            resp.setPayload("Book not found");
            check caller->respond(resp);
        } else {
            check caller->respond(book);
        }
    }

    // HTTP POST method to add a new book
    resource function post books(http:Caller caller, http:Request req) returns error? {
        json|error bookPayload = req.getJsonPayload();
        if (bookPayload is error) {
            http:Response resp = new;
            resp.statusCode = 500;
            resp.setPayload("Failed to parse JSON payload");
            check caller->respond(resp);
            return;
        }

        string bookId = uuid:createType1AsString();
        books[bookId] = bookPayload;
        check caller->respond({id: bookId, book: bookPayload});
    }

    // HTTP PUT method to update an existing book by ID
    resource function put books/[string bookId](http:Caller caller, http:Request req) returns error? {
        json updatedBook = check req.getJsonPayload();
        if (books.hasKey(bookId)) {
            books[bookId] = updatedBook;
            check caller->respond(updatedBook);
        } else {
            http:Response resp = new;
            resp.statusCode = 404;
            resp.setPayload("Book not found");
            check caller->respond(resp);
        }
    }

    // HTTP DELETE method to delete a book by ID
    resource function delete books/[string bookId](http:Caller caller, http:Request req) returns error? {
        if (books.hasKey(bookId)) {
            _ = books.remove(bookId);
            http:Response resp = new;
            resp.statusCode = 204;
            check caller->respond(resp);
        } else {
            http:Response resp = new;
            resp.statusCode = 404;
            resp.setPayload("Book not found");
            check caller->respond(resp);
        }
    }
}
