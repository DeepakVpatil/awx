# LDAP Authentication Configuration for AWX

Configure AWX to use LDAP/Active Directory for user authentication instead of local accounts.

## LDAP Configuration Methods

### Method 1: Environment Variables (Recommended)

Add LDAP configuration to `aks-helm/values.yaml`:

```yaml
# AWX Configuration with LDAP
AWX:
  enabled: true
  name: awx
  spec:
    service_type: LoadBalancer
    
    # LDAP Environment Variables
    extra_settings:
      - setting: AUTH_LDAP_SERVER_URI
        value: "ldap://your-ldap-server.company.com:389"
      - setting: AUTH_LDAP_BIND_DN
        value: "CN=awx-service,OU=Service Accounts,DC=company,DC=com"
      - setting: AUTH_LDAP_USER_SEARCH
        value: "LDAPSearch('OU=Users,DC=company,DC=com', ldap.SCOPE_SUBTREE, '(sAMAccountName=%(user)s)')"
      - setting: AUTH_LDAP_GROUP_SEARCH
        value: "LDAPSearch('OU=Groups,DC=company,DC=com', ldap.SCOPE_SUBTREE, '(objectClass=group)')"
      - setting: AUTH_LDAP_USER_ATTR_MAP
        value: "{'first_name': 'givenName', 'last_name': 'sn', 'email': 'mail'}"
      - setting: AUTH_LDAP_GROUP_TYPE
        value: "ActiveDirectoryGroupType()"
      - setting: AUTH_LDAP_REQUIRE_GROUP
        value: "CN=AWX-Users,OU=Groups,DC=company,DC=com"
      - setting: AUTH_LDAP_USER_FLAGS_BY_GROUP
        value: "{'is_superuser': 'CN=AWX-Admins,OU=Groups,DC=company,DC=com'}"

# LDAP Bind Password Secret
ldap:
  enabled: true
  bind_password: "your-ldap-bind-password"
```

### Method 2: Kubernetes Secret

Create LDAP configuration secret:

```yaml
# ldap-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: awx-ldap-config
  namespace: awx
type: Opaque
stringData:
  ldap_bind_password: "your-ldap-bind-password"
  ldap_config.py: |
    import ldap
    from django_auth_ldap.config import LDAPSearch, ActiveDirectoryGroupType
    
    # LDAP Server Configuration
    AUTH_LDAP_SERVER_URI = "ldap://your-ldap-server.company.com:389"
    AUTH_LDAP_BIND_DN = "CN=awx-service,OU=Service Accounts,DC=company,DC=com"
    AUTH_LDAP_BIND_PASSWORD = "your-ldap-bind-password"
    
    # User Search
    AUTH_LDAP_USER_SEARCH = LDAPSearch(
        "OU=Users,DC=company,DC=com",
        ldap.SCOPE_SUBTREE,
        "(sAMAccountName=%(user)s)"
    )
    
    # Group Search
    AUTH_LDAP_GROUP_SEARCH = LDAPSearch(
        "OU=Groups,DC=company,DC=com",
        ldap.SCOPE_SUBTREE,
        "(objectClass=group)"
    )
    
    # User Attribute Mapping
    AUTH_LDAP_USER_ATTR_MAP = {
        "first_name": "givenName",
        "last_name": "sn",
        "email": "mail"
    }
    
    # Group Configuration
    AUTH_LDAP_GROUP_TYPE = ActiveDirectoryGroupType()
    AUTH_LDAP_REQUIRE_GROUP = "CN=AWX-Users,OU=Groups,DC=company,DC=com"
    
    # User Permissions by Group
    AUTH_LDAP_USER_FLAGS_BY_GROUP = {
        "is_superuser": "CN=AWX-Admins,OU=Groups,DC=company,DC=com",
        "is_staff": "CN=AWX-Users,OU=Groups,DC=company,DC=com"
    }
    
    # Additional LDAP Options
    AUTH_LDAP_CONNECTION_OPTIONS = {
        ldap.OPT_DEBUG_LEVEL: 1,
        ldap.OPT_REFERRALS: 0,
    }
```

Apply the secret:
```bash
kubectl apply -f ldap-config.yaml
```

Update `values.yaml` to reference the secret:
```yaml
AWX:
  enabled: true
  name: awx
  spec:
    service_type: LoadBalancer
    ldap_configuration_secret: awx-ldap-config
```

## Company-Specific LDAP Examples

### Active Directory Configuration

```yaml
# For Microsoft Active Directory
AWX:
  spec:
    extra_settings:
      - setting: AUTH_LDAP_SERVER_URI
        value: "ldap://dc01.company.com:389"
      - setting: AUTH_LDAP_BIND_DN
        value: "CN=svc-awx,OU=Service Accounts,OU=IT,DC=company,DC=com"
      - setting: AUTH_LDAP_USER_SEARCH
        value: "LDAPSearch('OU=Employees,DC=company,DC=com', ldap.SCOPE_SUBTREE, '(sAMAccountName=%(user)s)')"
      - setting: AUTH_LDAP_GROUP_SEARCH
        value: "LDAPSearch('OU=Security Groups,DC=company,DC=com', ldap.SCOPE_SUBTREE, '(objectClass=group)')"
      - setting: AUTH_LDAP_REQUIRE_GROUP
        value: "CN=Ansible-Users,OU=Security Groups,DC=company,DC=com"
```

### OpenLDAP Configuration

```yaml
# For OpenLDAP
AWX:
  spec:
    extra_settings:
      - setting: AUTH_LDAP_SERVER_URI
        value: "ldap://ldap.company.com:389"
      - setting: AUTH_LDAP_BIND_DN
        value: "uid=awx-service,ou=services,dc=company,dc=com"
      - setting: AUTH_LDAP_USER_SEARCH
        value: "LDAPSearch('ou=people,dc=company,dc=com', ldap.SCOPE_SUBTREE, '(uid=%(user)s)')"
      - setting: AUTH_LDAP_GROUP_SEARCH
        value: "LDAPSearch('ou=groups,dc=company,dc=com', ldap.SCOPE_SUBTREE, '(objectClass=groupOfNames)')"
      - setting: AUTH_LDAP_GROUP_TYPE
        value: "GroupOfNamesType()"
```

## LDAP over SSL/TLS

### Secure LDAP Configuration

```yaml
AWX:
  spec:
    extra_settings:
      - setting: AUTH_LDAP_SERVER_URI
        value: "ldaps://ldap.company.com:636"
      - setting: AUTH_LDAP_CONNECTION_OPTIONS
        value: "{ldap.OPT_X_TLS_REQUIRE_CERT: ldap.OPT_X_TLS_NEVER}"
      - setting: AUTH_LDAP_START_TLS
        value: "True"
```

### Custom CA Certificate

Create secret with CA certificate:
```bash
kubectl create secret generic ldap-ca-cert \
  --from-file=ca.crt=company-ca.crt \
  -n awx
```

Reference in AWX configuration:
```yaml
AWX:
  spec:
    ca_trust_bundle: ldap-ca-cert
```

## Deployment with LDAP

### Update values.yaml

```yaml
# Complete LDAP configuration in values.yaml
AWX:
  enabled: true
  name: awx
  spec:
    service_type: LoadBalancer
    
    # LDAP Configuration
    extra_settings:
      - setting: AUTH_LDAP_SERVER_URI
        value: "ldap://your-ldap-server.company.com:389"
      - setting: AUTH_LDAP_BIND_DN
        value: "CN=awx-service,OU=Service Accounts,DC=company,DC=com"
      - setting: AUTH_LDAP_USER_SEARCH
        value: "LDAPSearch('OU=Users,DC=company,DC=com', ldap.SCOPE_SUBTREE, '(sAMAccountName=%(user)s)')"
      - setting: AUTH_LDAP_GROUP_SEARCH
        value: "LDAPSearch('OU=Groups,DC=company,DC=com', ldap.SCOPE_SUBTREE, '(objectClass=group)')"
      - setting: AUTH_LDAP_USER_ATTR_MAP
        value: "{'first_name': 'givenName', 'last_name': 'sn', 'email': 'mail'}"
      - setting: AUTH_LDAP_GROUP_TYPE
        value: "ActiveDirectoryGroupType()"
      - setting: AUTH_LDAP_REQUIRE_GROUP
        value: "CN=AWX-Users,OU=Groups,DC=company,DC=com"
      - setting: AUTH_LDAP_USER_FLAGS_BY_GROUP
        value: "{'is_superuser': 'CN=AWX-Admins,OU=Groups,DC=company,DC=com'}"

# LDAP Bind Password (use Kubernetes secret in production)
env:
- name: AUTH_LDAP_BIND_PASSWORD
  valueFrom:
    secretKeyRef:
      name: awx-ldap-secret
      key: bind_password
```

### Create LDAP Password Secret

```bash
kubectl create secret generic awx-ldap-secret \
  --from-literal=bind_password='your-ldap-bind-password' \
  -n awx
```

### Deploy with LDAP

```bash
cd aks-helm
./download-chart.sh
helm install awx-operator ./awx-operator-chart -n awx -f values.yaml
```

## Testing LDAP Authentication

### Verify LDAP Configuration

```bash
# Check AWX logs for LDAP authentication
kubectl logs -n awx -l app.kubernetes.io/name=awx -c awx-web

# Test LDAP connection from AWX pod
kubectl exec -it -n awx deployment/awx-web -- python manage.py shell
```

### LDAP Test Commands

```python
# Inside AWX shell
from django_auth_ldap.backend import LDAPBackend
backend = LDAPBackend()

# Test user authentication
user = backend.authenticate(request=None, username='testuser', password='testpass')
print(user)

# Test LDAP connection
import ldap
conn = ldap.initialize('ldap://your-ldap-server.company.com:389')
conn.simple_bind_s('CN=awx-service,OU=Service Accounts,DC=company,DC=com', 'password')
```

## Troubleshooting LDAP

### Common Issues

```bash
# Check LDAP connectivity
kubectl exec -it -n awx deployment/awx-web -- nslookup your-ldap-server.company.com

# Check LDAP port connectivity
kubectl exec -it -n awx deployment/awx-web -- telnet your-ldap-server.company.com 389

# View LDAP debug logs
kubectl logs -n awx -l app.kubernetes.io/name=awx -c awx-web | grep -i ldap
```

### LDAP Debug Configuration

```yaml
AWX:
  spec:
    extra_settings:
      - setting: LOGGING
        value: |
          {
            'version': 1,
            'disable_existing_loggers': False,
            'handlers': {
              'console': {
                'class': 'logging.StreamHandler',
              },
            },
            'loggers': {
              'django_auth_ldap': {
                'handlers': ['console'],
                'level': 'DEBUG',
              },
            },
          }
```

## Security Best Practices

1. **Use service account** with minimal LDAP permissions
2. **Store passwords in Kubernetes secrets**
3. **Use LDAPS** for encrypted connections
4. **Restrict LDAP groups** for AWX access
5. **Regular password rotation** for service accounts
6. **Monitor LDAP authentication logs**

## Group-Based Permissions

```yaml
# Map LDAP groups to AWX permissions
AUTH_LDAP_USER_FLAGS_BY_GROUP:
  is_superuser: "CN=AWX-Admins,OU=Groups,DC=company,DC=com"
  is_staff: "CN=AWX-Users,OU=Groups,DC=company,DC=com"

AUTH_LDAP_ORGANIZATION_MAP:
  "Default": {
    "users": "CN=AWX-Users,OU=Groups,DC=company,DC=com",
    "admins": "CN=AWX-Admins,OU=Groups,DC=company,DC=com"
  }
```

This configuration enables enterprise LDAP authentication for AWX with proper security and group-based access control.