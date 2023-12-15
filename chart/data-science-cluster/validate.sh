# wait for 2 minutes to let the pods get created
echo "Waiting 2 minutes for all pods to get launched"
sleep 120

# get the list of pods in the redhat-ods-applications namespace
kubectl get pods -n redhat-ods-applications

# wait for all pods to complete
echo "Wait for all pods to complete in the 'redhat-ods-applications' namespace"
kubectl wait --for=condition=ContainersReady --timeout=300s --all -n redhat-ods-applications pod

kubectl get pods -n redhat-ods-applications