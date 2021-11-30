# Kong Plugins Jwt Placklist

## Develop plugins

### Install Lua and lua rock 
* https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Unix

install lua

```shell
curl -R -O http://www.lua.org/ftp/lua-5.4.3.tar.gz
tar -zxf lua-5.4.3.tar.gz
cd lua-5.4.3
make linux test
sudo make install
```

install lua rock

```shell

wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz
tar zxpf luarocks-3.8.0.tar.gz
cd luarocks-3.8.0
./configure --with-lua-include=/usr/local/include
make
sudo make install
```


## Build image

We will use docker-file in https://github.com/kong/docker-kong/blob/master/customize/Dockerfile. So we will clone repository https://github.com/kong/docker-kong

In MacOS

```shell

export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
```

```shell

cd docker-kong customize

docker build --no-cache \
--build-arg KONG_BASE="kong:2.6.0-alpine" \
--build-arg PLUGINS="kong-plugin-jwt-blacklist" \
--tag "kong-jwt-blacklist" .
```


## Test

https://docs.konghq.com/gateway-oss/2.5.x/getting-started/configuring-a-service/

```shell
---Create demo-service, demo service will redirect to http://host.docker.internal:8888
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=demo-service' \
  --data 'url=http://host.docker.internal:8888'

---Add route to demo-service

curl -i -X POST \
  --url http://localhost:8001/services/demo-service/routes \
  --data 'hosts[]=demo.com'

--Test demo-service
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: demo.com'

---Add plugin to demo-service
curl -i -X POST --url http://localhost:8001/services/demo-service/plugins/ --data 'name=jwt-blacklist'

---Add plugin to demo-service with redis config 

curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"'

--- Add plugin to demo-service with redis  with prefix 
curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"' \
--form 'config.token_prefix=token_'

http --form POST 'http://kong:8001/services/demo-service/plugins' \
  name=jwt-blacklist \
  config.redis_token_prefix=Token \
  config.redis_host=host.docker.internal \
  config.redis_port=6379 \
  config.redis_password='[redis password]' \
  config.redis_timeout=2000 \
  config.token_secret=secret


curl -i -X GET --url http://localhost:8001/services/demo-service/plugins/ 



--Delete plugins
curl -i -X DELETE --url http://localhost:8001/services/demo-service/plugins/d5b59ce0-8048-49b7-b2d8-e5b9c2a8e7b0

 http :8001/config config=@kong.yml

```


```shell

 https://hub.docker.com/_/kong

curl -i -X POST \
  --url http://localhost:8001/services/demo-service/plugins/ \
  --data 'name=jwt-blacklist'

```


###  Test
Redis add key
```shell
-- add token 'test' with default config.token_prefix=token_
SADD keycloak:token:blacklist token_test

-- SMEMBERS keycloak:token:blacklist

```

```shell



curl -i -X GET --url http://localhost:8000/ \
  --header 'Host: demo.com' \
  --header 'Authorization: Bearer test'


curl -i -X GET --url http://localhost:8000/ \
  --header 'Host: demo.com' \
  --header 'Authorization: Bearer hai'


```
