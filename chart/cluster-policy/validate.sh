namespace=$1

# create array of pod start-with strings
pod_types=("nvidia-driver-daemonset" "gpu-feature-discovery" "nvidia-container-toolkit-daemonset" "nvidia-dcgm" "nvidia-device-plugin-daemonset" "nvidia-node-status-exporter" "nvidia-operator-validator")

# wait for 2 minutes to let the pods get created
echo "It could take up to 20 minutes for the entire set of pods of the GPU stack to reach a ready state"
echo "Waiting 2 minutes for all pods to get launched"
sleep 120

# get the list of pods in the nvidia-gpu-operator namespace
kubectl get pods -n $namespace
podlist=`kubectl get pods -n $namespace -o jsonpath="{$.items..metadata.name}"`
podlistarr=($podlist)

# set timeout to 30 minutes
timeout="1800s"
fail=0
driver_daemonset=""

# iterate over the pod start-with strings
for i in "${pod_types[@]}"
do
    echo "Waiting on '$i' pods"
    # wait for each pod that matches the start-with string
    for j in "${podlistarr[@]}"
    do
        if [[ $j == "$i"* ]]
        then
            # save one of the nvidia-driver-daemonset pods for later
            if [[ $i == "nvidia-driver-daemonset" ]]
            then
                driver_daemonset=$j
            fi
            # wait for the pod to be ready
            echo "    Waiting for pod '$j' to be ready"
            result=$(kubectl wait --for=condition=ContainersReady --timeout=$timeout -n $namespace pod/$j 2>&1)
            if [[ $result == error* ]]
            then
                fail=1
                echo "        $result"
                break
            fi
            echo "        $result"
        fi
    done
    if [[ $fail == 1 ]]
    then
        break
    fi
done

if [[ $fail == 1 ]]
then
    echo "The GPU stack is not ready"
    exit 1
else
    echo "The GPU stack is ready"
    kubectl get pods -n $namespace
    if [[ $driver_daemonset != "" ]]
    then
        kubectl exec -n $namespace -it $driver_daemonset -- nvidia-smi
    fi
fi