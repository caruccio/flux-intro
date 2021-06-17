FROM nginx:stable-alpine

ARG APP_VERSION
RUN echo -e "<html>\n<body>\n  <p>App-$APP_VERSION</p>\n</body>\n</html>" > /usr/share/nginx/html/index.html
