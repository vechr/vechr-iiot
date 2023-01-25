# Vechr App

Vechr app is application IIoT for manufacturing, and running on kubernetes Cluster, Vechr can run on premises, cloud as long as having kubernetes cluster.

## TL;DR;
```bash
# Install Cert Manager first (if needed)
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true

# Install vechr
helm repo add vechr https://vechr.github.io/vechr-atlas/helm/charts/
helm repo update
helm install vechr vechr/vechr-production
```

## Create GKE Clusters
```bash
# Create Cluster GKE
gcloud compute machine-types list > machine-types.log

gcloud container get-server-config --zone asia-southeast2-a > asia-southeast2-a-cluster.log

gcloud container clusters create vechr-cluster \
--cluster-version 1.25.4-gke.2100 \
--disk-size 200 \
--num-nodes 1 \
--machine-type e2-highcpu-4 \
--zone asia-southeast2-a

gcloud container clusters get-credentials vechr-cluster --zone asia-southeast2-a

kubectl get nodes -o wide

# Example create address static for ingress in GKE
gcloud compute addresses create vechr-ip --region=asia-southeast2 --subnet=default
# After this add in your Domain and Put this in gke.nats.loadBalanceIP
gcloud compute addresses describe vechr-ip --format='value(address)' --global

# Clean Up
gcloud container clusters delete vechr-cluster --zone asia-southeast2-a
gcloud compute addresses delete vechr-ip --global
```

## Configuration

### Ingress
```yaml
ingresses:
  name: vechr-ingress
  enabled: true
  namespace: default
  ingressClassName: nginx

  tls:
    enabled: true
    secretName: kong-vechr-cert-dev #if you using development
    hosts: 
      - app.vechr.com
    ca: LS0tLS1CRUdJ.....
    key: LS0tLS1CRUdJ.....
  
  rules:
    -
      host: app.vechr.com
      services:
        # backend audit
        -
          name: vechr-microservice-audit-service
          path: /api/v2/audit
          port: 3004
        -
          name: vechr-microservice-audit-service
          path: /api/v1/audit
          port: 3004
        -
          name: vechr-microservice-audit-service
          path: /api/audit
          port: 3004
        # backend auth
        -
          name: vechr-microservice-auth-service
          path: /api/v2/auth
          port: 3005
        -
          name: vechr-microservice-auth-service
          path: /api/v1/auth
          port: 3005
        -
          name: vechr-microservice-auth-service
          path: /api/auth
          port: 3005
        # backend notification
        -
          name: vechr-microservice-notification-service
          path: /api/v2/notification
          port: 3002
        -
          name: vechr-microservice-notification-service
          path: /api/v1/notification
          port: 3002
        -
          name: vechr-microservice-notification-service
          path: /api/notification
          port: 3002
        # backend things
        -
          name: vechr-microservice-things-service
          path: /api/v2/things
          port: 3001
        -
          name: vechr-microservice-things-service
          path: /api/v1/things
          port: 3001
        -
          name: vechr-microservice-things-service
          path: /api/things
          port: 3001
        # frontend
        -
          name: vechr-frontend-web-app
          path: /
          port: 80
```

### Common Application
```yaml
common:
  postgres:
    - 
      name: "vechr"
      externalPort: 5432
      enabled: true

      env:
        - name: POSTGRES_DB
          value: "postgres"
        - name: POSTGRES_USER
          value: Vechr
        - name: POSTGRES_PASSWORD
          value: "123"

  frontend:
    name: web-app
    image: zulfikar4568/web-app
    tag: latest
    enabled: true

    # imagePullPolicy: Always is recommended when using latest tags. Otherwise, please use IfNotPresent
    imagePullPolicy: Always

    port: 80
    externalPort: 80

    # Resource
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "1024Mi"
        cpu: "1"

  influx:
    name: influxdb
    replicas: 2
    enabled: true
    deployment:
      image: influxdb
      tag: 2.1.0-alpine
    influx:
      mode: setup
      organization: Vechr
      bucket: Vechr
      token: vechr-token
    auth:
      username: admin
      password: isnaen1998

```

## Microservices
You can enable Horizontal Auto Pod Scalling in this Microservices
```yaml
microservices:
  -
    name: audit-service
    image: zulfikar4568/audit-service
    tag: latest
    enabled: true

    # imagePullPolicy: Always is recommended when using latest tags. Otherwise, please use IfNotPresent
    imagePullPolicy: Always

    # these will be passed as environment variables
    env:
      - name: APP_PORT
        value: "3000"
      - name: NATS_URL
        value: "nats://nats-lb.default.svc.cluster.local:4222"
      - name: JWT_SECRET
        value: "secretvechr"
      - name: ECRYPTED_SECRET
        value: "usersecret"
      - name: JWT_EXPIRES_IN
        value: "3d"
      - name: DB_URL
        value: "postgresql://Vechr:123@vechr-postgres-vechr.default.svc.cluster.local:5432/audit_db?schema=public&connect_timeout=300"

    # this will expose port 80 on the host on port 8080
    port: 3000
    externalPort: 3004

    # Resource
    resources:
      requests:
        memory: "300Mi"
        cpu: "300m"
      limits:
        memory: "1024Mi"
        cpu: "1"

    hpa:
      enabled: false
      minReplicas: 1
      maxReplicas: 2
      averageUtilization: 70
  -
    name: auth-service
    image: zulfikar4568/auth-service
    tag: latest
    enabled: true

    # imagePullPolicy: Always is recommended when using latest tags. Otherwise, please use IfNotPresent
    imagePullPolicy: Always

    # these will be passed as environment variables
    env:
      - name: APP_PORT
        value: "3000"
      - name: NATS_URL
        value: "nats://nats-lb.default.svc.cluster.local:4222"
      - name: JWT_SECRET
        value: "secretvechr"
      - name: ECRYPTED_SECRET
        value: "usersecret"
      - name: JWT_EXPIRES_IN
        value: "3d"
      - name: DB_URL
        value: "postgresql://Vechr:123@vechr-postgres-vechr.default.svc.cluster.local:5432/auth_db?schema=public&connect_timeout=300"
      - name: JWT_REFRESH_EXPIRES_IN
        value: "30d"
      - name: INITIAL_SITE
        value: '{"code":"ST1","name":"Site Default","location":"Server Default"}'
      - name: INITIAL_SUPERUSER
        value: '{"fullName":"root","username": "root","emailAddress":"root@vechr.id","phoneNumber":"+62","password":"password123"}'

    # this will expose port 3000 on the host on port 3005
    port: 3000
    externalPort: 3005

    # Resource
    resources:
      requests:
        memory: "300Mi"
        cpu: "300m"
      limits:
        memory: "1024Mi"
        cpu: "1"

    hpa:
      enabled: false
      minReplicas: 1
      maxReplicas: 2
      averageUtilization: 70
  -
    name: db-logger-service
    image: zulfikar4568/db-logger-service
    tag: latest
    enabled: true

    # imagePullPolicy: Always is recommended when using latest tags. Otherwise, please use IfNotPresent
    imagePullPolicy: Always

    # these will be passed as environment variables
    env:
      - name: APP_PORT
        value: "3000"
      - name: NATS_URL
        value: "nats://nats-lb.default.svc.cluster.local:4222"
      - name: JWT_SECRET
        value: "secretvechr"
      - name: ECRYPTED_SECRET
        value: "usersecret"
      - name: JWT_EXPIRES_IN
        value: "3d"
      - name: INFLUX_URL
        value: "http://influxdb-service.default.svc.cluster.local:8086/"
      - name: INFLUX_TOKEN
        value: "vechr-token"
      - name: INFLUX_ORG
        value: "Vechr"
      - name: INFLUX_BUCKET
        value: "Vechr"

    # this will expose port 3000 on the host on port 3003
    port: 3000
    externalPort: 3003

    # Resource
    resources:
      requests:
        memory: "300Mi"
        cpu: "300m"
      limits:
        memory: "1024Mi"
        cpu: "1"

    hpa:
      enabled: true
      minReplicas: 1
      maxReplicas: 2
      averageUtilization: 70
  -
    name: notification-service
    image: zulfikar4568/notification-service
    tag: latest
    enabled: true

    # imagePullPolicy: Always is recommended when using latest tags. Otherwise, please use IfNotPresent
    imagePullPolicy: Always

    # these will be passed as environment variables
    env:
      - name: APP_PORT
        value: "3000"
      - name: NATS_URL
        value: "nats://nats-lb.default.svc.cluster.local:4222"
      - name: JWT_SECRET
        value: "secretvechr"
      - name: ECRYPTED_SECRET
        value: "usersecret"
      - name: JWT_EXPIRES_IN
        value: "3d"
      - name: EMAIL_ID
        value: isnaen71@gmail.com
      - name: EMAIL_PASS
        value: ofhbzrgtvmzbgrlh
      - name: EMAIL_HOST
        value: gmail-service.default.svc.cluster.local
      - name: EMAIL_PORT
        value: "587"
      - name: DB_URL
        value: "postgresql://Vechr:123@vechr-postgres-vechr.default.svc.cluster.local:5432/notification_db?schema=public&connect_timeout=300"

    # this will expose port 3000 on the host on port 3002
    port: 3000
    externalPort: 3002

    # Resource
    resources:
      requests:
        memory: "300Mi"
        cpu: "300m"
      limits:
        memory: "1024Mi"
        cpu: "1"

    hpa:
      enabled: false
      minReplicas: 1
      maxReplicas: 2
      averageUtilization: 70
  -
    name: things-service
    image: zulfikar4568/things-service
    tag: latest
    enabled: true

    # imagePullPolicy: Always is recommended when using latest tags. Otherwise, please use IfNotPresent
    imagePullPolicy: Always

    # these will be passed as environment variables
    env:
      - name: APP_PORT
        value: "3000"
      - name: NATS_URL
        value: "nats://nats-lb.default.svc.cluster.local:4222"
      - name: JWT_SECRET
        value: "secretvechr"
      - name: ECRYPTED_SECRET
        value: "usersecret"
      - name: JWT_EXPIRES_IN
        value: "3d"
      - name: DB_URL
        value: "postgresql://Vechr:123@vechr-postgres-vechr.default.svc.cluster.local:5432/things_db?schema=public&connect_timeout=300"

    # this will expose port 3000 on the host on port 3002
    port: 3000
    externalPort: 3001
      
    # Resource
    resources:
      requests:
        memory: "300Mi"
        cpu: "300m"
      limits:
        memory: "1024Mi"
        cpu: "1"

    hpa:
      enabled: false
      minReplicas: 1
      maxReplicas: 2
      averageUtilization: 70
  
```

## NATS
For Secret TLS Configuration
```yaml
natsSecret:
  enabled: true
  secretName: nats-vechr-cert-dev
  ca: LS0tLS1CRUdJTi.....
  cert: LS0tLS1CRUdJTiBDR.....
  key: LS0tLS1CRUdJTiBQU.....

```
You can refer to the documentation for Configuration [NATS](https://artifacthub.io/packages/helm/nats/nats)
```yaml
nats:
  enabled: true

  cluster:
    enabled: true
    replicas: 3
    noAdvertise: true

    tls:
      secret:
        name: nats-vechr-cert-dev
      ca: "ca.crt"
      cert: "tls.crt"
      key: "tls.key"
  nats:
    jetstream:
      enabled: true
      connectRetries: 30

      memStorage:
        enabled: true
        size: "2Gi"

      fileStorage:
        enabled: false
        # storageDirectory: /data/
        # existingClaim: nats-js-disk
        # claimStorageSize: 3Gi

  mqtt:
    enabled: true
    port: 1883

    tls:
      secret:
        name: nats-vechr-cert-dev
      ca: "ca.crt"
      cert: "tls.crt"
      key: "tls.key"

  websocket:
    enabled: true
    port: 9090
    noTLS: false

    tls:
      secret:
        name: nats-vechr-cert-dev
      ca: "ca.crt"
      cert: "tls.crt"
      key: "tls.key"

    sameOrigin: false
    allowedOrigins: []

  natsbox:
    enabled: true

```

## Metric Server
```yaml
metricsServer:
  enabled: false
```

## Postgresql Bitnami
You can refer to the documentation for Configuration [POSTGRESQL BITNAMI](https://artifacthub.io/packages/helm/bitnami/postgresql)
```yaml
postgresql:
  enabled: false
  auth:
    postgresPassword: "vechr123"
    username: "vechrUser"
    password: "vechr123"
  
  containerPorts:
    postgresql: 5432
```

## Nginx Ingress
```yaml
nginx:
  enabled: true
```