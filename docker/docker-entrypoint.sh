#!/usr/bin/env sh
set -eu

envsubst '${API_PREFIX} ${OAI_PREFIX} ${PUBLIC_NAME} ${PUBLIC_PREFIX} ${STAFF_NAME} ${STAFF_PREFIX} ${UPSTREAM_HOST}' \
  < /etc/nginx/conf.d/$PROXY_TYPE-domain.conf.template > /etc/nginx/conf.d/default.conf

exec "$@"
