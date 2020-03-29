# otbr-mqtt-sn
Docker file for OpenThread Border Router with MQTT-SN

# Building

```shell 
docker build --no-cache -t otbr-mqtt-sn -f ./Dockerfile .
```

# Running

```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```