# Operator Requirements
## Kiali Operator
## Red Hat Openshift Service Mesh 3
## Red Hat build of OpenTelemetry
## Tempo Operator

# Create project 
oc new-project istio-system
oc new-project istio-cni

# Minimum deployment requires Istio and IstioCNI 
oc create -f istio-ingress-gateway.yml

# Deploy Application 

## Create project bookinfo
oc new-project bookinfo

## Create labels to istio discovery and injection 
oc label namespace bookinfo istio-discovery=enabled
oc label namespace bookinfo istio-injection=enabled

## Deploy bookinfo sample application
oc apply -n bookinfo -f https://raw.githubusercontent.com/openshift-service-mesh/istio/release-1.26/samples/bookinfo/platform/kube/bookinfo.yaml
oc apply -n bookinfo -f https://raw.githubusercontent.com/openshift-service-mesh/istio/release-1.26/samples/bookinfo/platform/kube/bookinfo-versions.yaml

#Verifica que esta sem sidecar 
oc get pods -n bookinfo

# Habilitar sidecar injection no namespace da aplicação
oc -n bookinfo rollout restart deployments

#Verifica sidecar rodando 
oc get pods -n bookinfo


oc create -f bookinfo-app/bookinfo-gateway.yml
oc create -f bookinfo-app/bookinfo-igw.yml 
oc create -f bookinfo-app/bookinfo-vs.yml 

# Expose gateway svc 
oc expose svc istio-ingressgateway -n bookinfo --port=http2
oc get route istio-ingressgateway -n bookinfo-gateway

HOST=$(oc get route istio-ingressgateway -n bookinfo -o jsonpath='{.spec.host}')
echo "http://$HOST/productpage"
curl -I "http://$HOST/productpage"


# Create Monitoring Components
oc create -f monitoring/prometheus-metrics.yml
oc create -f monitoring/service-monitor.yml
oc create -f monitoring/pod-monitor.yml

# Minio (eh preciso porque nao temos um s3 da vida, apenas block storage)
oc create -f minio/minio-pvc.yml
oc create -f minio/minio-secret.yml
oc create -f minio/minio.yml
oc create -f minio/minio-client.yml
# mc --config-dir /tmp/.mc alias set minio http://minio:9000 minio minio123
# mc --config-dir /tmp/.mc mb minio/tempo
# mc --config-dir /tmp/.mc ls minio

# Tempo
oc new-project tempo
oc create -f tracing/tempo-stack.yml
oc create -f tracing/otel-telemetry.yml
oc create -f tracing/otel-collector.yml

