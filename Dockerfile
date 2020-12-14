# base image
FROM node:12.2.0

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/:$PATH

RUN mvn spring-boot:run
