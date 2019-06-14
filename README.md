SOGo docker image
=================

About and installation
----------------------

This is a docker image for SOGo stable releases. The main goal is to
have a stable release again.

It provides a docker-compose file. You need to provide a sogo.conf file
that must be copied to the docker volume sogoconf. Therefor I suggest
you start the compose file once and after it you can copy the sogo.conf
file into the volume.

Locate the sogoconf volume:

```
docker volume ls

DRIVER              VOLUME NAME
local               dockersogo_backups
local               dockersogo_tmp_vol
local               dockersogo_sogoconf
```

Inspect the sogoconf volume:

```
docker volume inspect dockersogo_sogoconf

[
    {
        "CreatedAt": "2019-05-29T14:51:49+02:00",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "dockersogo",
            "com.docker.compose.volume": "sogoconf"
        },
        "Mountpoint": "/var/lib/docker/volumes/dockersogo_sogoconf/_data",
        "Name": "dockersogo_sogoconf",
        "Options": null,
        "Scope": "local"
    }
]
```

Change to the directory pointed by Mountpoint:

```
cd /var/lib/docker/volumes/dockersogo_sogoconf/_data
```

Put your sogo.conf file there. Make sure it can be read by the docker
container user *sogo*.

The sogo.conf file probably has some postgresql lines. If they used to
go to *localhost*, you should change them to *172.16.238.1*.

If you have already a database, I suggest you create a backup. After
that go into the ACL table and fix the localhost->172.16.238.1 lines.

On the host side, I run memcached and PostgreSQL. Therefor the sogo.conf
completely goes to 172.16.238.1.

You will also need a nginx proxy on the host side. Here is my
configuration file that works pretty fine with this image:

```
server
{
    listen        80 default;
    server_name sogo.example.com;
    ## redirect http to https ##
    rewrite      ^ https://$server_name$request_uri? permanent;
}

server
{
    listen 443 ssl http2;
    listen 8443 ssl http2;
    listen 8843 ssl http2;
    server_name sogo.example.com;

    ssl_certificate /etc/letsencrypt/live/sogo.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sogo.example.com/privkey.pem;
    ssl_session_timeout 5m;
    ssl_session_cache shared:SSL:5m;
    ssl_protocols TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE+AESGCM:ECDHE+CHACHA20";

    ## requirement to create new calendars in Thunderbird ##
    proxy_http_version 1.1;

    # Message size limit
    client_max_body_size 512m;

    client_body_buffer_size 512k;
    client_header_timeout 360;
    client_body_timeout 360;
    send_timeout 360;

    rewrite ^/.well-known/caldav/?$ /SOGo/dav/ permanent;

    location /favicon.ico {
        root /usr/share/nginx/www;
    }

    location ~ \.php$ {
        root /usr/share/nginx/www;
        index index.html index.htmi index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_URI $document_uri;
        fastcgi_pass 127.0.0.1:9000;
    }

    location = / {
        rewrite ^ https://$server_name/SOGo;
        allow all;
    }

    # For iOS 7
    location = /principals/ {
        rewrite ^ https://$server_name/SOGo/dav;
        allow all;
    }

    location ^~/SOGo {
        proxy_pass http://127.0.0.1:20000;
        proxy_redirect http://127.0.0.1:20000 default;
        # forward user's IP address
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header x-webobjects-server-protocol HTTP/1.0;
        proxy_set_header x-webobjects-remote-host $remote_addr;
        proxy_set_header x-webobjects-server-name $server_name;
        proxy_set_header x-webobjects-server-url $scheme://$host;
        proxy_set_header x-webobjects-server-port $server_port;
        proxy_connect_timeout 90;
        proxy_send_timeout 3600;
        proxy_read_timeout 3600;
        proxy_buffer_size 4k;
        proxy_buffers 4 32k;
        proxy_busy_buffers_size 64k;
        proxy_temp_file_write_size 64k;
        break;
    }

    location /SOGo.woa/WebServerResources/ {
        proxy_pass http://127.0.0.1:8180;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }

    location /SOGo/WebServerResources/ {
        proxy_pass http://127.0.0.1:8180;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }

    location (^/SOGo/so/ControlPanel/Products/([^/]*)/Resources/(.*)$) {
        proxy_pass http://127.0.0.1:8180;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }

    location (^/SOGo/so/ControlPanel/Products/[^/]*UI/Resources/.*\.(jpg|png|gif|css|js)$) {
        proxy_pass http://127.0.0.1:8180;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }

    ##
    ## !!! ActiveSync provided by Z-Push !!!
    ##

    #location ^~ /Microsoft-Server-ActiveSync {
    #    access_log /var/log/nginx/activesync.log;
    #    error_log  /var/log/nginx/activesync-error.log;
    #
    #    proxy_connect_timeout 75;
    #    proxy_send_timeout 3600;
    #    proxy_read_timeout 3600;
    #    proxy_buffers 64 256k;
    #
    #    proxy_set_header Host $host;
    #    proxy_set_header X-Real-IP $remote_addr;
    #    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    #    proxy_pass http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync;
    #    proxy_redirect http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync /;
    #}
}
```

Some notes for this config file:

It used Let's encrypt. So go ahead and adopt it to your needs. The
docker image does not provide ActiveSync support, as I like z-push more.
The image is not built with the ActiveSync service!

If you run this image on CentOS as I do, you might need to add some
ports to htt_port_t

```
semanage port -a -t http_port_t -p tcp 8180
semanage port -a -t http_port_t -p tcp 20000
...
```
Have a look at the /var/log/audit/audit.log file to see, if you have
added all ports to the policy.

Credits
-------

I found a basic Dockerfile repository here:

[docker-sogo by Julien Fastré](https://framagit.org/julienfastre/docker-sogo)

I have completely modified his version to suite my needs. Thanks for his
idea!
