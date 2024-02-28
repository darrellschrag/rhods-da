namespace=$1
gpu_count=$2

# wait to let the pods get created
echo "Waiting for nvidia-driver-deamonset pods to start"
counter=0
until [[ $(kubectl get pods -n $namespace --output name | grep nvidia-driver-daemonset | wc -l) -eq $gpu_count ]]
do
    kubectl get pods -n $namespace
    ((counter++))
    sleep 10

    if [[ counter -gt 60 ]]
    then
        echo "nvidia-driver-daemonset pods have not started!"
        echo "current state of all pods in '$namespace' namespace"
        kubectl get pods -n $namespace
        exit 1
    fi
done

# wait for all pods to at least get started
echo "waiting for 5 minutes to let pods startup"
sleep 300

# get the list of pods in the nvidia-gpu-operator namespace
echo "current state of all pods in '$namespace' namespace"
kubectl get pods -n $namespace

# wait for all pods to complete
echo "It could take up to 20 minutes for the entire set of pods of the GPU stack to reach a ready state"
echo "Wait for all pods to complete in the '$namespace' namespace (30 minute timeout)"
result=$(kubectl wait --for=condition=ready --field-selector=status.phase!=Succeeded --timeout=1800s --all -n $namespace pod  2>&1)

if [[ $result == *"timed out"* ]]
then
    echo "$result"
    echo "All pods failed to start!!"
    echo "final state of all pods in '$namespace' namespace"
    kubectl get pods -n $namespace
    exit 1
else
    echo "The GPU stack is ready"
    echo "final state of all pods in '$namespace' namespace"
    kubectl get pods -n $namespace

    driver_daemonset_pods=$(kubectl get pods -o name -n $namespace | grep nvidia-driver-daemonset 2>&1)
    IFS=' ' read -ra arr <<< "$driver_daemonset_pods"
    driver_daemonset=${arr[0]}
    echo "Nvidia gpu status"
    kubectl exec -n $namespace -it $driver_daemonset -- nvidia-smi
fi
