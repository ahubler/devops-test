
# Allow the UPSTREAM_SERVER to be set to allow for local development use.
envsubst '{$UPSTREAM_SERVER}' \
  < /etc/nginx/conf.d/php-upstream.temp \
  > /etc/nginx/conf.d/php-upstream.conf

exec nginx
