FROM nginx:latest

WORKDIR /usr/share/nginx/html

# Remove default nginx config and files
RUN rm -rf /etc/nginx/conf.d/default.conf
RUN rm -rf ./*

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/manhuong.conf

# Copy website files
COPY index.html /usr/share/nginx/html/
COPY wp-content /usr/share/nginx/html/wp-content
COPY wp-includes /usr/share/nginx/html/wp-includes

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
