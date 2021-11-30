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
--build-arg PLUGINS="kong-plugin-jwt-blacklist,lua-resty-openidc" \
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

--- Add plugin to demo-service with redis  with prefix 
curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"' \
--form 'config.client_id="kong"' \
--form 'config.client_secret="e1dd102e-538d-44f2-8735-f6418693024a"' \
--form 'config.introspection_endpoint="http://0799-116-110-41-202.ngrok.io/auth/realms/demo/protocol/openid-connect/token/introspect"' 


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
curl -i -X DELETE --url http://localhost:8001/services/demo-service/plugins/7eb96d3a-9a91-41f4-9505-5a519a51a10e

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
  --header 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJ5N3VobVhyTUpVaEUxNExkc2lqb0VxbG56YUF0d3JyeE43b19zVEZIVWJJIn0.eyJleHAiOjE2MzgyOTgxMjYsImlhdCI6MTYzODI4MDEyNiwianRpIjoiM2UwZGVmOGUtZDhhNS00NjU5LTkwMTQtYjNlMTM0NGFmNTFiIiwiaXNzIjoiaHR0cDovLzA3OTktMTE2LTExMC00MS0yMDIubmdyb2suaW8vYXV0aC9yZWFsbXMvZGVtbyIsImF1ZCI6ImFjY291bnQiLCJzdWIiOiI0OTNkZGQyMS01NDAyLTQ4NWUtOTdlNy03MjhlMzRhYTA3ZmUiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJrb25nIiwic2Vzc2lvbl9zdGF0ZSI6IjNkMzQ4NTRkLWRhNzAtNGJhOS04N2MxLTU2ODZjNzc0M2UxMyIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiIsImRlZmF1bHQtcm9sZXMtZGVtbyJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoiZW1haWwgcHJvZmlsZSIsInNpZCI6IjNkMzQ4NTRkLWRhNzAtNGJhOS04N2MxLTU2ODZjNzc0M2UxMyIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJoYWluZC52bmdAZ21haWwuY29tIiwiZW1haWwiOiJoYWluZC52bmdAZ21haWwuY29tIn0.mKu94MGcaw4tlaRRrGdwznH6K1bfqzPMyxSvC2C2hQtXSQMoiK4XTGkKeEHUXJPLKLNF2jxIEFrvFaIPgQmK08fNHiX_tUD4q7dQwkpxEexgCB_T5SNCMNy42oqlpwyJuFrItdTmYoVzLTtX1sz9MrKAXISGr864s5BIWR2qfZRPg-jaE_G0lFZaWlqE3idWXoEsOzydgk5EPwb1OFivMk5sUwA-CikUfiU0qUIxcVospJ_833eOJwJGwpf0xUiok4CaQ01sLeaMBNnIVxXkQYyq44cpbL4WxLl7tNCXsfHm9UXoqNZv3XyULMAfHBeNogFZTZDKmYCOm0jK04cfnA'


```
