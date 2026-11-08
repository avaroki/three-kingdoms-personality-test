FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html script.js style.css /usr/share/nginx/html/
COPY images/ /usr/share/nginx/html/images/
COPY version.json /usr/share/nginx/html/version.json
EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1
