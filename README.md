```bash
alias k="kubectl --namespace=argo-events"
```

## 1. 

![](webhook-demo.png)

<br/>

- Create an event source
    ```bash
    k create -f demo1/gateway/webhook-gateway-configmap.yaml
    ```
 
- Create gateway
    ```bash
    k create -f demo1/gateway/webhook-gateway.yaml 
    ```

- Create sensor
    ```bash
    k create -f demo1/sensor/webhook-sensor.yaml
    ```
 ---
  
 - Update event sources
    ```bash
    https://raw.githubusercontent.com/VaibhavPage/kubecon-demo/master/demo1/gateway/webhook-gateway-configmap-updated.yaml
    ```

 - Update triggers in sensor
    ```bash
    https://raw.githubusercontent.com/VaibhavPage/kubecon-demo/master/demo1/sensor/webhook-sensor-updated.yaml
    ```

## 2.

 ![](S3-demo.png)

 - Input image
 
    ![](kubelogo-wide.png)
 
 - Output image
 
    ![](output.jpg)
  
 - Create event sources
 ```bash
  k create -f demo2/gateway/s3-gateway-configmap.yaml
 ```
 
 - Create S3 gateway
 ```bash
 k create -f demo2/gateway/s3-gateway.yaml
 ```
 
 - Check all event sources are running 
 ```bash
 k get gateways s3-gateway -o yaml
 ```
 
 - Create input sensor
 ```bash
 k create -f demo2/sensor/s3-input-sensor.yaml
 ```
 
 - Create output sensor
 ```bash
 k create -f demo2/sensor/s3-output-sensor.yaml
 ```