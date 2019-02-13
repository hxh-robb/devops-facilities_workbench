FROM alpine:latest
MAINTAINER Robb Tsang <robb@smeinternet.com>
COPY .out /app_starter
#RUN rm /app_starter/upgrade.sh
#RUN rm /app_starter/settings
#RUN rm -rf /app_starter/config
