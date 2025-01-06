
# Use the latest NGINX image as the base
FROM  nginx:1.26.2-alpine-slim AS nginx

ENV KEYVAL_VERSION="0.3.0"

FROM nginx AS builder

# Install necessary build dependencies
RUN apk update && apk add \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre2-dev \
        zlib-dev \
        linux-headers \
        bash \
        alpine-sdk \
        unzip


# Download and extract the nginx-mod-http-keyval module
RUN wget -O nginx-keyval-${KEYVAL_VERSION}.zip https://github.com/kjdev/nginx-keyval/archive/refs/tags/${KEYVAL_VERSION}.zip \
    && unzip nginx-keyval-${KEYVAL_VERSION}.zip

# Download and extract the NGINX source code
RUN wget -O nginx-${NGINX_VERSION}.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz  \
    && tar -zxvf nginx-${NGINX_VERSION}.tar.gz

# Compile the module
RUN cd nginx-${NGINX_VERSION} \ 
    && ./configure --with-compat --add-dynamic-module=../nginx-keyval-${KEYVAL_VERSION} \
    && make modules \
    && cp objs/ngx_http_keyval_module.so /etc/nginx/modules/

FROM nginx

COPY --from=builder /etc/nginx/modules/ngx_http_keyval_module.so /etc/nginx/modules/ngx_http_keyval_module.so
RUN  sed -i '7s|^|load_module "/etc/nginx/modules/ngx_http_keyval_module.so"; \n |' /etc/nginx/nginx.conf

