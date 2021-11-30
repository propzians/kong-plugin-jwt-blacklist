## Install Lua && lua rock 
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


## Test plugins

```shell

pongo run --no-cassandra --redis  


pongo up --expose  --no-cassandra --redis 


docker exec -it kong kong config init kong.yml


docker run -d --name kong \                                                                      │bash-5.1$ ps
    -e "KONG_DATABASE=off" \                                                                                           │PID   USER     TIME  COMMAND
    -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \                                                                           │    1 kong      0:00 nginx: master process /usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf
    -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \                                                                           │ 1098 kong      0:00 nginx: worker process
    -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \                                                                            │ 1099 kong      0:00 nginx: worker process
    -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \                                                                            │ 1100 kong      0:00 nginx: worker process
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \                                                            │ 1101 kong      0:00 nginx: worker process
    -p 8000:8000 \                                                                                                     │ 1273 kong      0:00 bash
    -p 8443:8443 \                                                                                                     │ 1281 kong      0:00 ps
    -p 8001:8001 \                                                                                                     │bash-5.1$ clear%
    -p 8444:8444 \
```
## config

https://docs.konghq.com/gateway-oss/2.5.x/getting-started/configuring-a-service/

```shell

curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=demo-service' \
  --data 'url=http://host.docker.internal:8888'



curl -i -X POST \
  --url http://localhost:8001/services/demo-service/routes \
  --data 'hosts[]=demo.com'


curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: demo.com'


curl -i -X POST --url http://localhost:8001/services/demo-service/plugins/ --data 'name=jwt-blacklist'

curl -X POST http://localhost:8001/services/demo-service/plugins \
    --data "name=jwt-blacklist"  \
    --data "config.redis_host="host.docker.internal"" \
    --data "config.redis_port=6379"
    
curl --location --request POST 'http://localhost:8001/services/demo-service/plugins/' \
--form 'name="jwt-blacklist"' \
--form 'config.redis_host="host.docker.internal"' \
--form 'config.redis_port=6379' \
--form 'config.redis_timeout="2000"'

http --form POST 'http://kong:8001/services/demo-service/plugins' \
  name=jwt-blacklist \
  config.redis_token_prefix=Token \
  config.redis_host=host.docker.internal \
  config.redis_port=6379 \
  config.redis_password='[redis password]' \
  config.redis_timeout=2000 \
  config.token_secret=secret


curl -i -X GET --url http://localhost:8001/services/demo-service/plugins/ 



Delete plugins
curl -i -X DELETE --url http://localhost:8001/services/demo-service/plugins/09d62db4-045f-46d3-847c-222e4a37e982

 http :8001/config config=@kong.yml

```


```shell

 https://hub.docker.com/_/kong

curl -i -X POST \
  --url http://localhost:8001/services/demo-service/plugins/ \
  --data 'name=jwt-blacklist'

```

 ###

 kong migrations bootstrap [-c /path/to/kong.conf]





### Build image

```shell
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

docker build --no-cache \
--build-arg KONG_BASE="kong:2.6.0-alpine" \
--build-arg PLUGINS="kong-plugin-jwt-blacklist" \
--tag "kong-jwt-blacklist" .
```

###  Test


```shell



curl -i -X GET --url http://localhost:8000/ \
  --header 'Host: demo.com' \
  --header 'Authorization: Bearer test'


curl -i -X GET --url http://localhost:8000/ \
  --header 'Host: demo.com' \
  --header 'Authorization: Bearer hai'


```
