# Kong Plugins Jwt Blacklist

## Flow chart

![Alt text](image/jwt_blacklist.png?raw=true "Title")
## Develop plugins

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


## Testing

### Config service 

* https://docs.konghq.com/gateway-oss/2.5.x/getting-started/configuring-a-service/


* Create `demo-service`, `demo-service` will redirect to http://host.docker.internal:8888
```shell
curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=demo-service' \
  --data 'url=http://host.docker.internal:8888'
```
* Add route to `demo-service`
```shell
curl -i -X POST \
  --url http://localhost:8001/services/demo-service/routes \
  --data 'hosts[]=demo.com'
```
* Test call  `demo-service`

```shell
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: demo.com'
```

* Add plugin to `demo-service` with `redis` config redis

```shell
curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"'
```

* Add plugin to `demo-service` with `redis`  with prefix 

```shell
curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"' \
--form 'config.token_prefix=token_'
```

* Add plugin to `demo-service` with `Redis` and `client`
```shell
curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"' \
--form 'config.client_id="kong"' \
--form 'config.client_secret="e1dd102e-538d-44f2-8735-f6418693024a"' \
--form 'config.introspection_endpoint="http://0799-116-110-41-202.ngrok.io/auth/realms/demo/protocol/openid-connect/token/introspect"' 
```

```shell
http --form POST 'http://kong:8001/services/demo-service/plugins' \
  name=jwt-blacklist \
  config.redis_token_prefix=Token \
  config.redis_host=host.docker.internal \
  config.redis_port=6379 \
  config.redis_password='[redis password]' \
  config.redis_timeout=2000 \
  config.token_secret=secret
```
* Retrieve all plugins by `demo-service`
```shell
curl -i -X GET --url http://localhost:8001/services/demo-service/plugins/ 
```


* Delete plugins
```shell
curl -i -X DELETE --url http://localhost:8001/services/demo-service/plugins/{{pluginId}}
```

###  Call api 

* Put `token` into blacklist `keycloak:token:blacklist`  with `redis-cli`

Add token 'test' with default config.token_prefix=token_
```shell
SADD keycloak:token:blacklist token_test
```

Retrieve all token of `keycloak:token:blacklist`
```shell
SMEMBERS keycloak:token:blacklist
```

Call HTTP request
```shell

curl -i -X GET --url http://localhost:8000/ \
  --header 'Host: demo.com' \
  --header 'Authorization: Bearer test'


curl -i -X GET --url http://localhost:8000/ \
  --header 'Host: demo.com' \
  --header 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJmN0ZuTjRHam9JVnhSNkRGRGo1VEFIQktWQUFLN2tYVzlwOVV5M3B6MnlBIn0.eyJleHAiOjE2MzgzMzE1MjksImlhdCI6MTYzODMzMTIyOSwianRpIjoiOWVjMmU0M2ItY2YyZi00MjIyLWI5ZjItNjJhNjY0YjA4OWI4IiwiaXNzIjoiaHR0cDovL2Rldi1rZXljbG9hay1zZXJ2aWNlLXYxLms4cy5wcm9wenkuYXNpYS9hdXRoL3JlYWxtcy9kZW1vIiwic3ViIjoiODFlODY1MWUtZWVkZC00ODQwLWFhMDktYjIxM2U0MWM0YTRmIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoidGVzdDAwMSIsInNlc3Npb25fc3RhdGUiOiJkNzY2NGI4ZC1iZWE5LTQ3ODEtODZkMC1mOGU2N2E1YzE1MjciLCJhY3IiOiIxIiwiYWxsb3dlZC1vcmlnaW5zIjpbImh0dHA6Ly9sb2NhbGhvc3Q6ODA4MSJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsidXNlciJdfSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwic2lkIjoiZDc2NjRiOGQtYmVhOS00NzgxLTg2ZDAtZjhlNjdhNWMxNTI3IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJ1c2VyIn0.XIxvvz3IjSPK1NzgvHJr4lO-NtgkU-63tYbUlgphnLNwKiz3__c-4qTRnR_-9tfPF9KN-8Y5ZRGf4lVVxHYaVWVNcUjH6qfXGu1vp70vUR00fJdswnOkp53ZceCr-L81GE00gftZH3-luyrAd-H_XrT7yUYSVJkn-mveG_0wv2qdGHImq51znsxUuerDRseAvXg19XYx8UzpRA8IL2oj2z8DLykfafxACzgmk3YaDptKWHuMka0bnpzQzO0iKWYymd5gEFwVaQ5eSb2wFyRb39pnS17DhjX8WGesTnhsDKCI_dxilREKIoQcLZjYz_HwYPksy5WSAW33wxCQRizwuA'
```
