FROM openresty/openresty:1.13.6.2-1-stretch AS installer

RUN apt-get update \
    && apt-get install git libqrencode-dev libpng-dev gcc make -y \
	&& git clone https://github.com/openresty/lua-resty-upload.git \
	&& git clone https://github.com/bungle/lua-resty-uuid.git \
	&& git clone https://github.com/orangle/lua-resty-qrencode.git \
	&& cd lua-resty-qrencode \
	&& make \
	&& make install

# final build
FROM openresty/openresty:1.13.6.2-1-stretch

WORKDIR /data/wwwroot/

COPY --from=installer lua-resty-upload/lib/resty/upload.lua /usr/local/openresty/lualib/resty/upload.lua 
COPY --from=installer lua-resty-uuid/lib/resty/uuid.lua /usr/local/openresty/lualib/resty/uuid.lua 
COPY --from=installer /usr/local/openresty/lualib/qrencode.so /usr/local/openresty/lualib/qrencode.so

COPY . .

RUN mv default.conf /etc/nginx/conf.d/default.conf \
    && mkdir -p /data/uploadfiles
