# To containarise the app : multistage docker file
# 1. use go image with correct version, alias it as base
FROM golang:1.22 AS base
# set working directory
WORKDIR /app
# copy go.mod to goimage
COPY go.mod .
# install all dependencies
RUN go mod download
# 2. copy contents from go-web-app-devops/* to .
COPY . .
# 3.run "go build -o main ."
RUN go build -o main .

# 4.use scratch image (smallest image available)
FROM gcr.io/distroless/base
# set working directory
WORKDIR /app
# copy static files
COPY --from=base /app/static ./static
# 5. copy build file from base image to here
COPY --from=base /app/main .
# expose port
EXPOSE 8080
# 6.run that build file
CMD [ "/app/main" ]


