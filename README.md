# Magento 2 docker container environment

# Create container
```
docker run -it -d --name=magento2 -h=magento2 -p 1080:80 -p 1022:22 -p 9001:9000 tsurkanovm/magento2 /bin/bash
```
# MySQL
```
user: root 
password: root
```
# SSH as docker user in Groups: www-data,sudo
```
ssh -p1022 docker@localhost
password: docker
```
# SSH as root user
```
ssh -p1022 root@localhost
password: root
```

#XDebug Intellij/PHPStorm setup
Go to: Languages & Frameworks > PHP > Debug > DBGp Proxy and set the following settings:
```
    Host: your IP address (example 172.17.0.1 for docker host)
    Port: 9001
```
# Origin
[Docker Hub] (https://registry.hub.docker.com/u/tsurkanovm/magento2/)
[Git Hub] (https://github.com/tsurkanovm/magento2)
