# MAIL RU(TARANTOOL) COMPANY TEST TASK
## Key-Value database Tarantool

### MAIL RU(TARANTOOL) COMPANY TEST TASK

### Build:
- Download tarantool [here](https://www.tarantool.io/ru/).
- Download Docker if you haven't docker on your machine

### Run:
```
docker run -p 8888:8888 --name tarantool-api-server -t tarantool-api-server
```
After this, you have available to `http://localhost:8888` , where 'localhost' is IP by your docker deamon

### TESTS
Run tests on console with:
```
./tests.py `localhost`
```

### API
POST     | /kv      | {"key":<string>, "value":<arbitrary_json>}   | 200 OK, 400 Bad Request, 409 Conflict  |
PUT      | /kv/{id} | {"value":<arbitrary_json>}                   | 200 OK, 400 Bad Request, 404 Not Found |
GET      | /kv/{id} | none                                          | 200 OK, 404 Not Found |
DELETE   | /kv/{id} | none                                          | 200 OK, 404 Not Found |
