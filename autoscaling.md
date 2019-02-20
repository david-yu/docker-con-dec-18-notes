# K8S horizontal pod autoscaling

Shows that the version of k8s that ships with UCP allows using horizontal pod autoscaling.

Assumes a running k8s cluster.

## Preparation

### Deploy k8s' metrics-server

The k8s version that comes with UCP does not include k8s' `metrics-server`, which is what horizontal pod autoscaling uses for its scheduling. As a k8s admin, run the following:
```bash
for s in resource-reader metrics-apiservice aggregated-metrics-reader auth-delegator auth-reader metrics-server-service; do
    echo "doing $s"
    url="https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/$s.yaml"
    curl -s $url | kubectl apply -f - && continue
    echo "failed at $s"
    break
done
# kubelet options had to be changed a bit for UCP
# this is referring the file in this repo
kubectl apply -f autoscaling/metrics-server-deployment.yaml
```

Then after a minute or so, `kubectl get --raw /apis/metrics.k8s.io/` should show that the metrics-server is running.

### Create test Docker image (optional)

*This step is optional as both Docker images have already been built and pushed to the Docker public registry.*

Inside of this repo's `autoscaling` directory, run:
```bash
docker build . -f service.dockerfile -t wk88/autoscale-example
docker build . -f load-generator.dockerfile -t wk88/autoscale-example
```
Feel free to replace with your own tags, of course.

## Demo

### Deploy a web service to scale

Apply the following manifest to your k8s cluster (change the image names if needed):
```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  labels:
    run: php-apache
  name: php-apache
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      run: php-apache
  template:
    metadata:
      creationTimestamp: null
      labels:
        run: php-apache
    spec:
      containers:
      - image: wk88/autoscale-example
        imagePullPolicy: Always
        name: php-apache
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m # 0.2 CPU per pod

---

apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
  namespace: default
spec:
  maxReplicas: 10
  minReplicas: 1
  scaleTargetRef:
    apiVersion: extensions/v1beta1
    kind: Deployment
    name: php-apache
  targetCPUUtilizationPercentage: 50 # maintain avg utilization at 50% of max (ie 0.1 CPU) on each pod

---

apiVersion: v1
kind: Service
metadata:
  name: php-apache
  namespace: default
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: php-apache
  type:
    LoadBalancer
```

This creates a web service that computes an approximation of π in an horrendously inefficient (and CPU intensive) fashion.

The important part of this manifest is the `HorizontalPodAutoscaler` resource, which together with the `Deployment`'s resource limitations is asking k8s to maintain CPU usage to 0.1 CPU per pod on average.

You can access this service's through your favorite browser to check it works.

### 

Then let's create another service to create load on our web service:
```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  labels:
    run: load-generator
  name: load-generator
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      run: load-generator
  template:
    metadata:
      labels:
        run: load-generator
    spec:
      containers:
      - image: wk88/load-generator
        imagePullPolicy: Always
        name: load-generator
```

If you look at the Dockerfile used to create this deployment's image (`autoscaling/load-generator.dockerfile` in this repo), you'll see it simply keeps pinging our web service.

You can now watch k8s scale the number of pods running for our web service:
```bash
watch -n 1 kubectl get HorizontalPodAutoscaler
```

In a minute or two, the number of pods running should go from 1 to 10 (which is the max we set in our `HorizontalPodAutoscaler` resource).
