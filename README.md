```bash
alias k="kubectl --namespace=argo-events"
```

## 1. Print event payload

- Create an event source
    ```bash
    k create -f webhook-gateway-configmap.yaml
    ```
 
- Create gateway
    ```bash
    k create -f webhook-gateway.yaml 
    ```

- Create sensor
    ```bash
    k create -f webhook-sensor.yaml
    ```

- Post request

 ---
  
 - Update event sources
    ```yaml
       apiVersion: v1
       kind: ConfigMap
       metadata:
         name: webhook-gateway-configmap
       data:
         webhook.portConfig: |-
           port: "12000"
           endpoint: "/bar"
           method: "POST"
         webhook.fooConfig: |-
           endpoint: "/foo"
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
         - name: webhook-gateway/webhook.fooConfig
       triggers:
         - name: webhook-workflow-trigger
           resource:
             namespace: argo-events
             group: argoproj.io
             version: v1alpha1
             kind: Workflow
             parameters:
               - src:
                   signal: webhook-gateway/webhook.fooConfig
                 dest: spec.arguments.parameters.0.value
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
         - name: webhook-workflow-trigger-2
           resource:
             namespace: argo-events
             group: argoproj.io
             version: v1alpha1
             kind: Workflow
             source:
               inline: |
                   apiVersion: argoproj.io/v1alpha1
                   kind: Workflow
                   metadata:
                     generateName: hello-world-
                   spec:
                     entrypoint: whalesay
                     templates:
                       -
                         container:
                           args:
                             - "hello world"
                           command:
                             - cowsay
                           image: "docker/whalesay:latest"
                         name: whalesay

    ```

    - Post requests
    
## 2. Something more complex
 - Input image
 
    ![](kubelogo-wide.png)
 
 - Output image
 
    ![](output.jpg)

 - Event sources
   ```yaml
     apiVersion: v1
     kind: ConfigMap
     metadata:
       name: s3-gateway-configmap
     data:
       s3.fooConfig: |-
         s3EventConfig:
           bucket: input
           endpoint: minio-service.argo-events:9000
           event: s3:ObjectCreated:Put
           filter:
             prefix: ""
             suffix: ""
         insecure: true
         accessKey:
           key: accesskey
           name: artifacts-minio
         secretKey:
           key: secretkey
           name: artifacts-minio
       s3.barConfig: |-
         s3EventConfig:
           bucket: output
           endpoint: minio-service.argo-events:9000
           event: s3:ObjectCreated:Put
           filter:
             prefix: ""
             suffix: ""
         insecure: true
         accessKey:
           key: accesskey
           name: artifacts-minio
         secretKey:
           key: secretkey
           name: artifacts-minio
    ```
    
 - Gateway
    ```yaml
     apiVersion: argoproj.io/v1alpha1
     kind: Gateway
     metadata:
       name: s3-gateway
       labels:
         gateways.argoproj.io/gateway-controller-instanceid: argo-events
         gateway-name: "s3-gateway"
     spec:
       deploySpec:
         containers:
         - name: "s3-events"
           image: "argoproj/artifact-gateway:v0.6"
           imagePullPolicy: "Always"
           command: ["/bin/artifact-gateway"]
         serviceAccountName: "argo-events-sa"
       configMap: "s3-gateway-configmap"
       eventVersion: "1.0"
       imageVersion: "v0.6"
       type: "s3"
       dispatchMechanism: "HTTP"
       watchers:
         sensors:
         - name: "s3-sensor"
    ```
    
 - Sensor to process image
    ```yaml
     apiVersion: argoproj.io/v1alpha1
     kind: Sensor
     metadata:
       name: process-image-sensor
       labels:
         sensors.argoproj.io/sensor-controller-instanceid: argo-events
     spec:
       repeat: true
       serviceAccountName: argo-events-sa
       imageVersion: "v0.6"
       signals:
         - name: s3-gateway/input
       triggers:
         - name: argo-workflow
           resource:
             namespace: argo-events
             group: argoproj.io
             version: v1alpha1
             kind: Workflow
             parameters:
             - src:
                 signal: s3-gateway/input
                 path: s3.object.key
               dest: spec.templates.0.container.args.0
             - src:
                 signal: s3-gateway/input
                 path: s3.bucket.name
               dest: spec.templates.0.container.args.1
             source:
               inline: |
                   apiVersion: argoproj.io/v1alpha1
                   kind: Workflow
                   metadata:
                     generateName: process-image-
                   spec:
                     entrypoint: process-image
                     templates:
                       - name: process-image
                         container:
                           image: metalgearsolid/minio-image-processing:latest
                           args:
                             - "this will be replaced"
                             - "input"
                           env:
                             - name: NAMESPACE
                               valueFrom:
                                 fieldRef:
                                   fieldPath: metadata.namespace
                             - name: CONFIG_MAP
                               value: minio-access-configmap
                             - name: SERVICE_ACCOUNT_NAME
                               value: argo-events-sa
    ```
    
 - Sensor to notify end of pipeline
    ```yaml
     apiVersion: argoproj.io/v1alpha1
     kind: Sensor
     metadata:
       name: s3-output-sensor
       labels:
         sensors.argoproj.io/sensor-controller-instanceid: argo-events
     spec:
       repeat: true
       serviceAccountName: argo-events-sa
       imageVersion: "v0.6"
       signals:
         - name: s3-gateway/output
       triggers:
         - name: argo-workflow
           resource:
             namespace: argo-events
             group: argoproj.io
             version: v1alpha1
             kind: Workflow
             source:
               inline: |
                   apiVersion: argoproj.io/v1alpha1
                   kind: Workflow
                   metadata:
                     generateName: pipeline-completed-
                   spec:
                     entrypoint: whalesay
                     serviceAccountName: argo-events-sa
                     templates:
                       -
                         container:
                           args:
                             - "Image Processing Pipeline Completed"
                           command:
                             - cowsay
                           image: "docker/whalesay:latest"
                         name: whalesay
    ```