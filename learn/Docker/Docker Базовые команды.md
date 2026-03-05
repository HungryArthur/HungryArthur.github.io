
Чтобы запустить контейнер необходимо выполнить команду **`docker run <метка образа>`** , например для запуска ubuntu:
```bash
docker run ubuntu
```

Для запуска контейнера в интерактивном режиме необходимо передать ключ **`-it`**
```bash
docker run -it ubuntu
```

Выйти из контейнера можно с помощью команды **`exit`**
```bash
exit
```

Посмотреть работающие контейнеры можно командой `docker ps`:
Вывод:
```d
CONTAINER ID   IMAGE               COMMAND
dc4240f64724   nginx-hello-world   "/docker-entrypoint.…"
8072cc90e1b3   nginx               "/docker-entrypoint.…"
b83d4ac8ef64   ubuntu              "/bin/bash"

CREATED          STATUS          PORTS                  NAMES
41 seconds ago   Up 41 seconds   0.0.0.0:9999->80/tcp   cranky_maxwell
16 minutes ago   Up 16 minutes   0.0.0.0:8888->80/tcp   eager_archimedes
22 minutes ago   Up 20 minutes                          vigorous_lalande
```

Посмотреть все образы можно с помощью команды `docker images`
```d
REPOSITORY          TAG       IMAGE ID       CREATED          SIZE
nginx-hello-world   latest    31e7d9018a0a   8 minutes ago    161MB
nginx               latest    fd204fe2f750   8 days ago       161MB
ubuntu              latest    bbdabce66f1b   3 weeks ago      78.1MB
postgres            latest    019965b81888   7 weeks ago      456MB
metabase/metabase   latest    cffcebd4cd25   8 weeks ago      882MB
```

Присоединиться к работающему контейнеру можно командой `**attach**` (необходимо указать _id_ контейнера)
```bash
docker attach 4e9fa3526059
```

Остановить контейнер можно командой `**stop**`
```plain
docker stop 4e9fa3526059
```

A запустить командой `start`
```plain
docker start 4e9fa3526059
```

Чтобы запустить контейнер с открытым портом надо передать флаг `-p` и указать какой порт операционной системы переадресуем в открытый в контейнере порт (через двоеточие)
```bash
docker run -p 8888:80 nginx
```

### Создание Dockerfile
Для указания базового образа используется инструкция `FROM`.  
Для указания рабочей директории используется инструкция `WORKDIR`.  
Для копирования файлов инструкция `COPY`.  
**RUN** позволяет выполнить определенную команду при построении образа.  
**CMD** является входной точкой для запуска приложения.

Пример Dockerfile для приложения написанного на Go.
```plain
FROM golang:1.21
WORKDIR /app
COPY main.go .
RUN go build -o hello-go main.go
CMD ["./hello-go"]
```

```d
C:\Users\Arthur\Desktop\docker-go>docker build . -t hello-go:1.0

C:\Users\Arthur\Desktop\docker-go>docker images
REPOSITORY          TAG       IMAGE ID       CREATED          SIZE
hello-go            1.0       fbbb5541756b   2 minutes ago    937MB

C:\Users\Arthur\Desktop\docker-go>docker run -d -p 5555:8080 hello-go:1.0
```
