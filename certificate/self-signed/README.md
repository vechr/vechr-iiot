# Create Self Signed Certificate

## * Create Local Certificate Authority

1. generate root CA key
```bash
openssl genrsa -des3 -out rootCA.key 2048
```

2. Generate root CA pem
```bash
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1825 -out rootCA.pem
```
```
Country Name: ID
Province: Jawa Barat
City: Cimahi
Organization Name: Company CA
Organization Unit Name: Certificate Authority
Common Name: app.company.com
Email: admin@company.com
```
3. Convert root CA pem to p7b so can be used in windows OS
```
openssl crl2pkcs7 -nocrl -certfile rootCA.pem -out rootCA.p7b
```

### * Create SSL for our application

1. Generate app.company.com key
```
openssl genrsa -out app.company.com.key 2048
```

2. Buat csr file untuk diajukan ke Certificate Authority Sebelumnya
```
openssl req -new -key app.company.com.key -out app.company.com.csr 
```
```
Country Name: ID
Province: Jawa Barat
City: Cimahi
Organization Name: company
Organization Unit Name: DevOps
Common Name: app.company.com
Email: admin@company.com

Challenge Password: your password
Optional	Company Name: company.com
```
3. Create config.txt file
```txt
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = app.company.com
```
4. Buat Certificate crt file untuk Aplikasi kita 
```bash
openssl x509 -req -in app.company.com.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out app.company.com.crt -days 365 -sha256 -extfile config.txt 
```

### * Import rootCA.pem in our browser or OS so we will have secure connection https

For Example: </br>
[In MAC](https://support.apple.com/en-in/guide/keychain-access/kyca2431/mac)</br>
[In Chrome](https://docs.vmware.com/en/VMware-Adapter-for-SAP-Landscape-Management/2.1.0/Installation-and-Administration-Guide-for-VLA-Administrators/GUID-D60F08AD-6E54-4959-A272-458D08B8B038.html)
### * Create Secret In our kubernetes, for example NATS
```bash
#KONG
kubectl create secret generic nats-client-tls --from-file=tls.crt=./app.company.com.crt --from-file=tls.key=./app.company.com.key --from-file=ca.crt=./rootCA.pem
# KONG
kubectl create secret tls kong-vechr-cert --cert=./app.company.com.crt --key=./app.company.com.key
```
###  * Create Secret In our kubernetes yaml
```
cat app.company.com.crt | base64
cat app.company.com.key | base64
cat rootCA.pem | base64
```
```yaml
apiVersion: v1
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURKakNDQWc2.....
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBcG5wUU40MXZ6...
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVIekNDVndVb3NIU2hO.....
kind: Secret
metadata:
  name: kong-vechr-cert-dev
  namespace: default
type: kubernetes.io/tls
```