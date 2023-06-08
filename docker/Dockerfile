FROM --platform=linux/amd64 nginx

ENV API_PREFIX="/api/" \
    OAI_PREFIX="/oai" \
    PROXY_TYPE="single" \
    PUBLIC_NAME="" \
    PUBLIC_PREFIX="/" \
    STAFF_NAME="" \
    STAFF_PREFIX="/" \
    UPSTREAM_HOST="localhost"

COPY templates/*-domain.conf.template /etc/nginx/conf.d/
COPY common-config /etc/nginx/

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
