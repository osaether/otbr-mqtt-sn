# OpenThread Border Router with MQTT-SN Gateway

A containerized solution that combines an **OpenThread Border Router** with a **Paho MQTT-SN Gateway**, enabling seamless communication between Thread mesh networks and MQTT brokers. This allows Thread devices to publish sensor data and receive commands through standard MQTT infrastructure.

## Key Features

- **Thread to MQTT Bridge**: Connect Thread mesh networks to MQTT brokers
- **Docker Containerized**: Easy deployment and management  
- **Nordic SDK Compatible**: Works with nRF5 SDK examples out of the box
- **Configurable Network Parameters**: Flexible Thread network configuration
- **Web Management Interface**: Built-in OTBR web interface on port 8080

## Security Considerations

⚠️ **IMPORTANT**: This project uses default Thread network keys for Nordic SDK compatibility:
- **Network Key**: `00112233445566778899AABBCCDDEEFF`  
- **PSKc**: `5ce66d049d007088ad900dfcc2a55ee3`

🚨 **For production use**: Always change these keys using `--network-key` and `--pskc` parameters.

The default MQTT broker (`mqtt.eclipseprojects.io`) is public and unencrypted. For production, use `--broker` to specify your secure MQTT broker.

## Building Docker image

```shell 
docker build --pull --no-cache -t otbr-mqtt-sn -f ./Dockerfile .
```

## Building RCP for the nRF52840 dongle (PCA10059)

```shell
git clone https://github.com/openthread/ot-nrf528xx.git
cd ot-nrf528xx
git submodule update --init
# Skip the following line if you have the GNU Arm Embedded tools installed
./script/bootstrap
./script/build nrf52840 USB_trans -DOT_BOOTLOADER=USB
arm-none-eabi-objcopy -O ihex build/bin/ot-rcp rcp-pca10059.hex
```
See here for instructions on how to program the nRF52840 dongle:
[nRF52840 Dongle Programming Tutorial](https://devzone.nordicsemi.com/nordic/short-range-guides/b/getting-started/posts/nrf52840-dongle-programming-tutorial)

## Running

To run the container with the default parameters:

```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

Access the OpenThread Border Router web interface at `http://localhost:8080`.

## Configuration Parameters

The most common network parameters can be set on the docker command line. The default values are taken from the [Nordic Semiconductor border router](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee/Download#infotabs) such that it works with the examples in the [nRF5 SDK for Thread and Zigbee](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee).

| Parameter | Command line option | Default value |
|-----------|---------------------|---------------|
| Network Name | `--network-name` | OTBR-MQTT-SN |
| RCP Serial Port | `--radio-url` | spinel+hdlc+uart:///dev/ttyACM0 |
| PAN ID | `--panid` | 0xABCD |
| Extended PAN ID | `--xpanid` | DEAD00BEEF00CAFE |
| Channel | `--channel` | 11 |
| Network Key | `--network-key` | 00112233445566778899AABBCCDDEEFF ⚠️ |
| Network PSKc | `--pskc` | 5ce66d049d007088ad900dfcc2a55ee3 ⚠️ |
| TUN Interface Name | `--interface` | wpan0 |
| NAT64 Prefix | `--nat64-prefix` | 64:ff9b::/96 |
| Default prefix route | `--disable-default-prefix-route` | Enabled |
| Default prefix slaac | `--disable-default-prefix-slaac` | Enabled |
| Backbone Interface | `--backbone-interface` | eth0 |
| MQTT Broker | `--broker` | mqtt.eclipseprojects.io |
| MQTT-SN Broadcast Address | `--mqttsn-broadcast-address` | ff33:40:MESH::1 |

## Example Usage

Basic setup:
```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

Production setup with custom keys:
```shell
docker run --name otbr-mqtt-sn \
  -p 8080:80 --dns=127.0.0.1 -it --privileged \
  otbr-mqtt-sn \
  --network-key "YOUR_SECURE_128BIT_KEY_HERE" \
  --pskc "YOUR_SECURE_PSKC_HERE" \
  --broker "mqtt.mycompany.com"
```

## Troubleshooting

**Container won't start**: Ensure Docker daemon is running and user is in `docker` group:
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
```

**RCP device not found**: Check device connection and permissions:
```bash
ls /dev/ttyACM*
sudo chmod 666 /dev/ttyACM0
```

**Thread network issues**: Reset the Thread dataset:
```bash
docker exec otbr-mqtt-sn ot-ctl dataset clear
```

**Verify setup**: Check container logs and Thread status:
```bash
docker logs otbr-mqtt-sn
docker exec otbr-mqtt-sn ot-ctl state
```