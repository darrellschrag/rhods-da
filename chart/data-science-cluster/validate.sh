namespace=$1

# wait to let the pods get created
echo "Waiting for all pods to get launched"
counter=0
until [[ $(kubectl get pods -n $namespace --output name | wc -l) -gt 8 ]]
do
    kubectl get pods -n $namespace
    ((counter++))
    sleep 10

    if [[ counter -gt 60 ]]
    then
        echo "Pods have not started!"
        echo "current state of all pods in '$namespace' namespace"
        kubectl get pods -n $namespace
        exit 1
    fi
done

# get the list of pods in the redhat-ods-applications namespace
echo "current state of all pods in '$namespace' namespace"
kubectl get pods -n $namespace

# wait for all pods to complete
echo "Wait for all pods to complete in the '$namespace' namespace (5 minute timeout)"
result=$(kubectl wait --for=condition=ready --field-selector=status.phase!=Succeeded --timeout=300s --all -n $namespace pod  2>&1)

if [[ $result == *"timed out"* ]]
then
    echo "$result"
    echo "All pods failed to start!!"
    echo "final state of all pods in '$namespace' namespace"
    kubectl get pods -n $namespace
    exit 1
else
    echo "the Red Hat OpenShift AI cluster has started successfully!"
    echo "final state of all pods in '$namespace' namespace"
    kubectl get pods -n $namespace
fi