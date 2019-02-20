# K8S RBAC

Shows that the version of k8s that ships with UCP allows using RBAC authorization.

Assumes a running UCP cluster.

Log into your UCP cluster as an admin, and create a new user named `bob` by navigating to `Access Control > Users > Create`.

Then let's create a few k8s resources (`Kubernetes > Create`):
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev

---

apiVersion: v1
kind: ReplicationController
metadata:
  name: redis-dev
  namespace: dev
spec:
  replicas: 2
  selector:
    app: redis
  template:
    metadata:
      name: redis-dev-rc
      namespace: dev
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis
        ports:
        - containerPort: 6379

---

apiVersion: v1
kind: Namespace
metadata:
  name: prod

---

apiVersion: v1
kind: ReplicationController
metadata:
  name: redis-prod
  namespace: prod
spec:
  replicas: 2
  selector:
    app: redis
  template:
    metadata:
      name: redis-prod-rc
      namespace: prod
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis
        ports:
        - containerPort: 6379

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: dev
  name: pod-rc-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods", "replicationcontrollers"]
  verbs: ["get", "watch", "list"]

---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: namespace-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["namespaces"]
  verbs: ["get", "watch", "list"]
```

Now create RBAC role bindings by navigating to `Access Control > Grants > Create Role Binding` in UCP's UI, to create bindings equivalent to:
```yaml
# This role binding allows "bob" to read pods in the "dev" namespace.
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-dev-pods-and-rcs
  namespace: dev
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-rc-reader
  apiGroup: rbac.authorization.k8s.io

---

# and we also let bob list namespaces
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-namespaces
  namespace: default
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-reader
  apiGroup: rbac.authorization.k8s.io
```

Finally, open an incognito window in your favorite browser, log into your UCP cluster as `bob`, and check that you can see the Redis controller and pods in the `dev` namespace, but can't see anything running in the `prod` namespace. Download its access bundle, and check the same applies to `kubectl get all` and `kubectl get --namespace=dev pods`.
