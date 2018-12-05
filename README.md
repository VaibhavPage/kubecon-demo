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
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: webhook-gateway-configmap
    data:
      hello: |-
        port: "12000"
        endpoint: "/hello"
        method: "POST"
      echo: |-
        endpoint: "/echo"
        method: "POST"
    ```

 - Update triggers in sensor
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Sensor
    metadata:
      name: webhook-sensor
      labels:
        sensors.argoproj.io/sensor-controller-instanceid: argo-events
    spec:
      repeat: true
      imageVersion: "v0.6"
      serviceAccountName: argo-events-sa
      signals:
        - name: webhook-gateway/hello
        - name: webhook-gateway/echo
      triggers:
        - name: webhook-hello-trigger
          resource:
            namespace: argo-events
            group: argoproj.io
            version: v1alpha1
            kind: Workflow
            parameters:
              - src:
                  signal: webhook-gateway/hello
                dest: spec.templates.0.container.args.0
            source:
              inline: |
                apiVersion: argoproj.io/v1alpha1
                kind: Workflow
                metadata:
                  generateName: hello-payload-
                spec:
                  entrypoint: whalesay
                  templates:
                    - name: whalesay
                      container:
                        args:
                          - "hello world"
                        command:
                          - cowsay
                        image: "docker/whalesay:latest"
        - name: webhook-echo-trigger
          resource:
            namespace: argo-events
            group: argoproj.io
            version: v1alpha1
            kind: Workflow
            parameters:
              - src:
                  signal: webhook-gateway/echo
                dest: spec.templates.0.container.args.0
            source:
              inline: |
                apiVersion: argoproj.io/v1alpha1
                kind: Workflow
                metadata:
                  generateName: echo-payload-
                spec:
                  entrypoint: whalesay
                  templates:
                    - name: whalesay
                      container:
                        args:
                          - "hello world"
                        command:
                          - cowsay
                        image: "docker/whalesay:latest"

    ```

## 2.
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