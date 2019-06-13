FROM alpine:3.9
LABEL maintainer="SVK [https://github.com/skovylov/nginx]"

EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]


ENV NGX_BUILD /usr/src/nginx
ENV NGINX_VERSION 1.16.0
ENV NAXSI_VER 0.56
ENV NGX_MODULES ""
ENV NGX_NDK 0.3.1rc1
ENV LUA_MODULE_VERSION 0.10.15
ENV NGX_STICKY 1.2.6

ENV LUAJIT_LIB=/usr/lib
ENV LUAJIT_INC=/usr/include/luajit-2.1

RUN set -ex \
  && apk add --no-cache \
  ca-certificates \
  libressl \
  pcre \
  zlib \
  libmaxminddb \
  luajit\
  && apk add --no-cache --virtual .build-deps \
  build-base \
  linux-headers \
  libressl-dev \
  pcre-dev \
  wget \
  zlib-dev \
  git \
  libmaxminddb-dev \
  luajit-dev \
  && mkdir -p $NGX_BUILD \
  && cd $NGX_BUILD \
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar xzf nginx-${NGINX_VERSION}.tar.gz \
#Begin 3rd party modules building
#================================
#-- VTS module
  && git clone git://github.com/vozlt/nginx-module-vts.git \
  && NGX_MODULES="$NGX_MODULES --add-dynamic-module=../nginx-module-vts" \
#-- GEOIP2 module
  && git clone https://github.com/leev/ngx_http_geoip2_module.git \
  && NGX_MODULES="$NGX_MODULES --add-dynamic-module=../ngx_http_geoip2_module" \
#-- NAXSI module
  && wget https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz -O naxsi_$NAXSI_VER.tar.gz \
  && tar vxf naxsi_$NAXSI_VER.tar.gz \
  && NGX_MODULES="$NGX_MODULES --add-dynamic-module=../naxsi-$NAXSI_VER/naxsi_src/" \
#-- LUAJIT module
  && wget https://github.com/simplresty/ngx_devel_kit/archive/v$NGX_NDK.tar.gz \
  && wget https://github.com/openresty/lua-nginx-module/archive/v$LUA_MODULE_VERSION.tar.gz \
  && tar vxf v$NGX_NDK.tar.gz \
  && NGX_MODULES="$NGX_MODULES --add-dynamic-module=../ngx_devel_kit-$NGX_NDK" \
  && tar vxf v$LUA_MODULE_VERSION.tar.gz \
  && NGX_MODULES="$NGX_MODULES --add-dynamic-module=../lua-nginx-module-$LUA_MODULE_VERSION" \
#-- SYSGUARD module
  && git clone git://github.com/vozlt/nginx-module-sysguard.git \
  && NGX_MODULES="$NGX_MODULES --add-dynamic-module=../nginx-module-sysguard" \
#================================
# End 3-rd party modules building
  && ls /usr/include/* \
  && cd /$NGX_BUILD/nginx-${NGINX_VERSION} \
  && ./configure \
  \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  \
  --user=nginx \
  --group=nginx \
  \
  --with-threads \
  \
  --with-file-aio \
  \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_auth_request_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_stub_status_module \
  \
  --http-log-path=/var/log/nginx/access.log \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  \
  --with-mail \
  --with-mail_ssl_module \
  \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  $NGX_MODULES \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && sed -i -e 's/#access_log  logs\/access.log  main;/access_log \/dev\/stdout;/' -e 's/#error_log  logs\/error.log  notice;/error_log stderr notice;/' /etc/nginx/nginx.conf \
  && adduser -D nginx \
  && mkdir -p /var/cache/nginx \
  && apk del .build-deps \
  && apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
   \
  && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
  && apk add --no-cache $runDeps \
  && apk del .gettext \
  && mv /tmp/envsubst /usr/local/bin/ \
# Bring in tzdata so users could set the timezones through the environment
# variables
  && apk add --no-cache tzdata \
  && rm -rf /tmp/* \
  && rm -rf $NGX_BUILD \
  && mkdir -p /etc/nginx/conf.d/{base,http,sites}

COPY nginx.conf /etc/nginx/
COPY http.conf /etc/nginx/conf.d/http/
COPY base.conf /etc/nginx/conf.d/base/
COPY default.conf /etc/nginx/conf.d/sites/
