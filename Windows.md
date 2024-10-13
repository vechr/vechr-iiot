## Setup Application (Development)
Before pulling you'll need to all **access** for submodule repository.

### 1. Import Certificate
Download or Import [root certificate](./certificate/self-signed/rootCA.pem) or you can generate by your self, be aware that you need to create for  [./certificate/self-signed/ingress](./certificate/self-signed/ingress) and [./certificate/self-signed/nats](./certificate/self-signed/nats) as well. Import in our browser or OS so we will have secure connection https

If you don't now how to generate your own certificate, you can try to follow this [tutorial](./certificate/self-signed/README.md)

Here are some article how to import the certificate: </br>
[In Chrome](https://docs.vmware.com/en/VMware-Adapter-for-SAP-Landscape-Management/2.1.0/Installation-and-Administration-Guide-for-VLA-Administrators/GUID-D60F08AD-6E54-4959-A272-458D08B8B038.html)

### 2. Pull repository
```
git clone --recursive https://github.com/vechr/vechr-iiot.git
```
Somehow the `.env` and `*.sh` file is not working on windows, so if you want to change some of the configuration you need to change directly on `docker-compose.yaml`. But you still need to configured the `.env` on each application

### 3. Configured `.env` in each application
You need to setup the .env variable file, and see in each application have `.env.example`
1. `application/web-app/.env` <== See `application/web-app/.env.example`
2. `microservices/auth-service/.env` <== See `microservices/auth-service/.env.example`
3. `microservices/db-logger-service/.env` <== See `microservices/db-logger-service/.env.example`
4. `microservices/notification-service/.env` <== See `microservices/notification-service/.env.example`
5. `microservices/things-service/.env` <== See `microservices/things-service/.env.example`
6. `.env` <== `.env.example`
### 4. Running Application

Running all container
```bash
docker compose up -d --build
```

### 5. Test the connection
Try to ping the connection, if cannot be access, you need to settings the hosts files
```bash
ping app.vechr.com
ping nats.vechr.com
```

In MAC or Linux, and set `/etc/hosts`, if your environment windows setting in `C:\Windows\System32\drivers\etc\hosts`
```h
127.0.0.1 app.vechr.com
127.0.0.1 nats.vechr.com
```

### 6. Access the Application
You can try to access the application, you can visit the app in here `https://app.vechr.com`

## Administrative Matters
### 1. Starting All Container
```bash
docker compose up -d --build
```
### 2. Stoping All Container
```bash
docker compose down
```
