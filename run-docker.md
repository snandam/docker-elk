### Instructions tested to be working in OSX

##### Run docker container
docker run -d -p 5601:5601 -p 80:80 -p 9200:9200 -p 49021:49021 -p 49022:49022 gunmetalz/elk


* 80=ngnx, 9200=elasticsearch, 5601=kibana, 49021=logstash, 49022=lumberjack, 9999=udp

##### Find IP address
```sh
➜  ~  docker-machine ip default
192.168.99.100
```
##### Application dashboards

###### Elasticsearch
* http://192.168.99.100:9200
* http://192.168.99.100:9200/_plugin/marvel/sense/index.html

######  Kibana
http://192.168.99.100:5601

##### Connect to the container
```sh
➜  ~  docker exec -it 74bc10c850f8 bash
root@74bc10c850f8:/# top
TERM environment variable not set.
```
To fix the TERM issue you can run the below command
```sh
export TERM=dumb
```
