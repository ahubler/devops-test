## Welcome to the Health Recovery Solutions Widgets API


This is a devops interview project. The goal of this assignment is to test for creativity in solving a common problem. There are no right answers. We are more interested in the approach.

You have been given 2 codebases. These codebases are in different
repositories represented here as folders `api-1` and `api-2`


### The Goals

#### Goal #1

You must containerize these two applications to be shippable to production
as separate docker images. You may consider using a php-fpm-nginx docker image such as https://hub.docker.com/r/richarvey/nginx-php-fpm/ or roll your own docker image.
This application does very little and does not require any special php modules.


#### Goal #2

Developers must be able to work on both projects locally. This means that one developer
can alter both projects simultaneously. Even though the project files are in one place here, pretend that each project is a separate repository that must be checked out independently.
`api-1` must be able to communicate with `api-2`

### Project breakdown

- Both projects are written in PHP using the Laravel framework. You do not need to be familar with the framework. Each project has instructions on how to build the code.
- Project `api-1` is the public api project. On production it will be served under a domain name such as `https://api.hrstech.com/`
Please ensure that when this container goes live we will be able to serve it with `https`. For this demonstration it does not need to be a real certificate authority. A self signed certificate will be sufficient.

- This project is a laravel project and requires a mysql 5.7 database. The developer has provided a README file inside the project folder to get started.

- Project `api-2` is a PRIVATE api. It is not to be exposed to the outside world under any circumstances. The only consumer of this api will be `api-1`. The url for this api can be a private dns entry.


#### Goal Acceptance

- Use your best judgement to set up a development environment that makes it as easy as possible for developers. (Hint - we like docker and docker-compose)
- You may use nginx to do a reverse proxy locally so the developer can edit code and serve `api-1` locally under a domain such as `https://api.hrstech.local/`
- Using a tool such as postman the developer can test their api locally. It should look similar to the provided image `screenshot1.png`
- Document and discuss which tools are used
- Provide instructions on how to launch this project on production, including any dns setup. You may assume we will have full control of public and private dns zones.

### Launching the Development environment
#### Set up `api-1`.
 - In the `api-1` directory, copy `.env.example` to `.env` and fill out all the DB Connection Info to connect to Mysql.
 - Run `composer install`, then `php artisan key:generate`.
 - Create new locally trusted self-signed certificates. (I used `mkcert` and created my certs by running `mkcert -key-file nginx/key.pem -cert-file nginx/cert.pem api.hrstech.local 127.0.0.1 localhost`)
 - If the mysql database needs to be created, at this point you can follow the directions in api-1/README.md.

#### Set up `api-2`.
- In the `api-2` directory, copy `.env.example` to `.env`.
- Run `composer install`, then `php artisan key:generate`.

#### Launch services with `docker-compose up`.
- In the devops-test directory, run `docker-compose up` to launch the services described in `devops-test/docker-compose.yml`. Modify your hosts file to point `api.hrstech.local` to `127.0.0.1`, then test the service by sending a get request to `https://api.hrstech.local/api/widgets`.

### Services in `docker-compose.yml`
For each service, the docker-compose file specifies the build context and Dockerfile used to build the container image along with some other configuration to get the services talking to each other. Below is a summary of how each service is configured.

- The `private-api` service that runs the internal API. It runs on a php container listening for php-fpm connections on port 9000 and the service has the api-2 application code mounted as a volume so changes can be made without needing to rebuild the container image.

- The `nginx-private-api` service runs the web server for the internal API. It runs off a simple NGINX container image and has some NGINX config mounted as volumes in addition to the api-2 application code. Changes to NGINX configuration can be applied by sending a reload signal to NGINX by running the command `docker exec nginx-private-api nginx -s reload`. The `nginx-private-api` service is connected to the `private-api` service through the upstream configured in `/etc/nginx/conf.d/php-upstream.conf`. This file is created when the nginx container first starts up and uses `envsubst` to fill in the given `UPSTREAM_SERVER`.

- The `public-api` service that runs the public facing API. It runs on a php container listening for php-fpm connections on port 9000 and the service has the api-1 application code mounted as a volume so changes can be made without needing to rebuild the container image. This is set up almost identically to the `private-api` service, the main difference (aside from the different application code) being the extra config in .env for MYSQL and private-api connections.

- The `nginx-public-api` service runs the web server for the public facing API. Just like the `nginx-private-api` service, it runs off a simple NGINX container image and has some NGINX config mounted as volumes in addition to the api-1 application code. Changes to NGINX configuration can be applied by sending a reload signal to NGINX by running the command `docker exec nginx-private-api nginx -s reload`. The `nginx-private-api` service is connected to the `private-api` service through the upstream configured in `/etc/nginx/conf.d/php-upstream.conf`. This file is created when the nginx container first starts up and uses `envsubst` to fill in the given `UPSTREAM_SERVER`. The `nginx-public-api` service is also configured to reroute HTTP traffic to HTTPS, and it uses a self-signed cert and some extra nginx config to handle the HTTPS traffic.

#### Instructions for launching in production.

- A lot of the specific instructions for launching the services in production will depend on what orchestration service will be used, so these instructions are more general.

- The public NGINX and PHP containers should be run together as one unit as should the private NGINX and PHP containers. If they are run together in a Kubernetes pod or ECS task then the NGINX container can communicate with the PHP container via `127.0.0.1:9000`, which is the default value for `UPSTREAM_SERVER` in the NGINX containers.

- Ideally, setup steps like composer install and key generation would be done as a part of the build pipeline.

- Configuration like MYSQL connection information and BACKEND_SERVER URLs and sensitive files like SSL Certs would be passed to the container at runtime.

- In this local dev example, the private api only accepts HTTP traffic. It would be best to have this running on HTTPS in production. In order to get it running over https in this local environment, we would have to add a self signed cert to the private api's NGINX server and also add that certificate's root CA cert to the public api service. Else the curl calls to the private service will fail.

- DNS for api.hrstech.com should be pointed to some kind of load balancing solution which will pass the traffic to the NGINX containers for the public API. The private api can be made accessible to the public API using a service discovery tool or a simpler private DNS zone setup. The specifics of DNS setup really depend on what tools you want to use for load balancing/scaling.

- It would also be wise to develop some kind of health checks for both the public and private apis.
