Поднять систему:
```
docker-compose up
```

Создать пользователя-владельца и БД
```
cat db.sql | docker exec -i pg_test psql -U postgres
```

Запусить бекап:
```
cat backup.sql | docker exec -i pg_test psql -U postgres
```