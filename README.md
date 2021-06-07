# Key-Value database Tarantool


### Build:
- Download tarantool [here](https://www.tarantool.io/ru/)
- Download Docker if you haven't docker on your machine [here](https://www.docker.com/products/docker-desktop)

### Run:
```
docker build . -t mytarantool
docker run -p 8888:8888 --name mytarantool -t mytarantool
```
After this, you have available to `http://localhost:8888` , where `localhost` is IP by your docker deamon

### Tests:
Before run tests open at browser `http://localhost:8888`

Run tests on new console with:
```
./Test.py `localhost`
```

### Api:
- POST /kv body: {key: "test", "value": {SOME ARBITRARY JSON}}
- PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}}
- GET kv/{id}
- DELETE kv/{id}

-----------------------------------------------------------------------------

- POST возвращает 409 если ключ уже существует,
- POST, PUT возвращают 400 если боди некорректное
- PUT, GET, DELETE возвращает 404 если такого ключа нет - все операции логируются
