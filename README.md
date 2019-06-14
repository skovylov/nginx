# Docker NGINX with additional modules

This project aimed to create docker nginx with additional modules. 


### Modules included

- VTS - [virtual host traffic status module](https://github.com/vozlt/nginx-module-vts)
- GEOIP2 - [GEOIP2 nginx module](https://github.com/leev/ngx_http_geoip2_module)
- NAXSI - [open-source, high performance, low rules maintenance WAF for NGINX](https://github.com/nbs-system/naxsi)
- LUAJIT - [Embed the Power of Lua into NGINX HTTP servers](https://github.com/openresty/lua-nginx-module)
- SYSGUARD - [Nginx sysguard module](https://github.com/vozlt/nginx-module-sysguard)

>All modules are dynamic, so you need to load them in section "conf.d/base" to enable.
## Brief description

By default, nginx.conf designed to allow user manages almost all options.
##### Here is a structure of conf.d directory:
- __conf.d/base/*.conf__
> This directory contains files for global nginx configurations (users, events etc.)
- __conf.d/http/*.conf__
> This directory contains files for __HTTP__ section of nginx config except __SERVER__ configuration
- __conf.d/sites/*.conf__
> This directory contains files for SERVER configs

Such structure has been chosen to have flexibility in configuration of nginx without need to edit nginx.conf itself.

## Timezone definition
By default no timezone selected and system uses __UTC__. To set correct timezone you need to use __NGINX_TZ__ environment variable.
```bash
docker run \
-e NGINX_TZ="Europe/Moscow"
skovylov/nginx:latest
```
This will set Moscow timezone as default to container.

## Usage 
First of all, you need to create configs in directories above. After that you need to mount config directory inside container
```bash
docker run \
-v /path/to/host/conf.d:/etc/nginx/conf.d \
skovylov/nginx:latest
```

It's also recommended to mount local path to logs:
```bash
docker run \
-v /path/to/host/conf.d:/etc/nginx/conf.d \
-v /path/to/host/logs:/var/log/nginx \
skovylov/nginx:latest
```