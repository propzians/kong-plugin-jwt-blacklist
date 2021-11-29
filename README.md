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

##config
https://docs.konghq.com/gateway-oss/2.5.x/getting-started/configuring-a-service/

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


 http :8001/config config=@kong.yml


 https://hub.docker.com/_/kong


 ###

 kong migrations bootstrap [-c /path/to/kong.conf]