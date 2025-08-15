# OpenThread Border Router with MQTT-SN Gateway

A containerized solution that combines an **OpenThread Border Router** with a **Paho MQTT-SN Gateway**, enabling seamless communication between Thread mesh networks and MQTT brokers. This allows Thread devices to publish sensor data and receive commands through standard MQTT infrastructure.

## 🌟 Key Features

- **Thread to MQTT Bridge**: Connect Thread mesh networks to MQTT brokers
- **Docker Containerized**: Easy deployment and management  
- **Nordic SDK Compatible**: Works with nRF5 SDK examples out of the box
- **Configurable Network Parameters**: Flexible Thread network configuration
- **Multi-Protocol Support**: UDP6, DTLS, and other transport options
- **Web Management Interface**: Built-in OTBR web interface on port 8080

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Thread    │    │      OTBR       │    │   MQTT Broker   │
│   Devices   │◄──►│   + MQTT-SN     │◄──►│                 │
│             │    │    Gateway      │    │                 │
└─────────────┘    └─────────────────┘    └─────────────────┘
      │                      │                      │
   6LoWPAN              Thread/IPv6            MQTT/TCP
```

This solution provides:
- **Thread devices** communicate via 6LoWPAN with the border router
- **OTBR** handles Thread mesh routing and provides IPv6 connectivity  
- **MQTT-SN Gateway** translates between MQTT-SN and standard MQTT
- **External MQTT Broker** receives data from Thread network

## 📋 Prerequisites

### Required Hardware
- **Linux host** (tested on Ubuntu 18.04+)
- **Thread RCP device**: nRF52840 dongle or similar OpenThread RCP
- **USB connection** for RCP device

### Required Software
- **Docker** (version 20.10+)
- **Git** for cloning repositories
- **Internet connection** for accessing MQTT broker

### Network Requirements
- **Privileged Docker access** for network interface management
- **Port 8080** available for OTBR web interface
- **Internet connectivity** for MQTT broker communication (default: mqtt.eclipseprojects.io)

## 🔒 Security Considerations

⚠️ **IMPORTANT SECURITY WARNINGS**

### Default Network Keys
This project uses **default Thread network keys** for Nordic SDK compatibility:
- **Network Key**: `00112233445566778899AABBCCDDEEFF`  
- **PSKc**: `5ce66d049d007088ad900dfcc2a55ee3`

🚨 **For production use**: Always change these keys using `--network-key` and `--pskc` parameters.

### MQTT Broker Security
- Default MQTT broker (`mqtt.eclipseprojects.io`) is **public and unencrypted**
- For production: Use `--broker` to specify your secure MQTT broker
- Consider implementing MQTT authentication and TLS

### Network Isolation
- Container runs with `--privileged` for network management
- Consider network isolation in production environments

## 🚀 Quick Start

### 1. Build Docker Image

```shell 
docker build --pull --no-cache -t otbr-mqtt-sn .
```

### 2. Run Container

```shell
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

### 3. Access Web Interface

Open browser to `http://localhost:8080` to access the OpenThread Border Router web interface.

## 🔧 Building RCP for nRF52840 Dongle (PCA10059)

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

## ⚙️ Configuration Parameters

The most common network parameters can be set on the docker command line. The default values are taken from the [Nordic Semiconductor border router](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee/Download#infotabs) such that it works with the examples in the [nRF5 SDK for Thread and Zigbee](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK-for-Thread-and-Zigbee).

| Parameter | Option | Default | Description |
|-----------|--------|---------|-------------|
| **Network Name** | `--network-name` | `OTBR-MQTT-SN` | Thread network identifier |
| **RCP Serial Port** | `--radio-url` | `spinel+hdlc+uart:///dev/ttyACM0` | RCP device connection string |
| **PAN ID** | `--panid` | `0xABCD` | Personal Area Network identifier |
| **Extended PAN ID** | `--xpanid` | `DEAD00BEEF00CAFE` | 64-bit extended PAN identifier |
| **Channel** | `--channel` | `11` | Thread radio channel (11-26) |
| **Network Key** | `--network-key` | `00112233445566778899AABBCCDDEEFF` | 128-bit Thread network key ⚠️ |
| **PSKc** | `--pskc` | `5ce66d049d007088ad900dfcc2a55ee3` | Pre-shared key for commissioning ⚠️ |
| **TUN Interface** | `--interface` | `wpan0` | Thread network interface name |
| **NAT64 Prefix** | `--nat64-prefix` | `64:ff9b::/96` | IPv6 to IPv4 translation prefix |
| **Default prefix route** | `--disable-default-prefix-route` | Enabled | Border router prefix route |
| **Default prefix slaac** | `--disable-default-prefix-slaac` | Enabled | SLAAC for prefix assignment |
| **Backbone Interface** | `--backbone-interface` | `eth0` | Host network interface |
| **MQTT Broker** | `--broker` | `mqtt.eclipseprojects.io` | MQTT broker hostname/IP |
| **MQTT-SN Broadcast** | `--mqttsn-broadcast-address` | `ff33:40:MESH::1` | MQTT-SN discovery address |

## ✅ Verification Steps

### 1. Check Container Status
```bash
docker ps
# Should show otbr-mqtt-sn container running
```

### 2. Access OTBR Web Interface
Open browser to `http://localhost:8080`
- Should show OpenThread Border Router interface
- Check Thread network status

### 3. Verify Thread Network
```bash
docker exec otbr-mqtt-sn ot-ctl state
# Should return: leader, router, or child
```

### 4. Test MQTT-SN Gateway
```bash
docker logs otbr-mqtt-sn
# Look for: "Starting MQTT-SN Gateway listening on: ff33:40:..."
```

### 5. Monitor MQTT Traffic
Use MQTT client to subscribe to broker:
```bash
mosquitto_sub -h mqtt.eclipseprojects.io -t '#' -v
```

## 📚 Examples

### Basic Setup
```bash
# Build image
docker build -t otbr-mqtt-sn .

# Run with defaults
docker run --name otbr-mqtt-sn -p 8080:80 --dns=127.0.0.1 -it --privileged otbr-mqtt-sn
```

### Custom Network Configuration
```bash
# Production setup with custom keys
docker run --name otbr-mqtt-sn \
  -p 8080:80 --dns=127.0.0.1 -it --privileged \
  otbr-mqtt-sn \
  --network-name "MyProductionNetwork" \
  --network-key "YOUR_SECURE_128BIT_KEY_HERE" \
  --pskc "YOUR_SECURE_PSKC_HERE" \
  --broker "mqtt.mycompany.com"
```

### Development with Different Hardware
```bash
# Using different RCP device
docker run --name otbr-mqtt-sn \
  -p 8080:80 --dns=127.0.0.1 -it --privileged \
  --device=/dev/ttyUSB0 \
  otbr-mqtt-sn \
  --radio-url "spinel+hdlc+uart:///dev/ttyUSB0"
```

### Custom Channel and Network Settings
```bash
# Use different Thread channel and network settings
docker run --name otbr-mqtt-sn \
  -p 8080:80 --dns=127.0.0.1 -it --privileged \
  otbr-mqtt-sn \
  --channel 15 \
  --panid 0x1234 \
  --xpanid "1234567890ABCDEF" \
  --network-name "CustomNetwork"
```

## 🛠️ Troubleshooting

### Common Issues

#### Container Won't Start
**Problem**: `docker run` fails with permission errors  
**Solution**: Ensure Docker daemon is running and user is in `docker` group
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in
```

#### RCP Device Not Found
**Problem**: `Error: RCP device not found at /dev/ttyACM0`  
**Solutions**:
1. Check device connection: `ls /dev/ttyACM*`
2. Use correct device: `--radio-url spinel+hdlc+uart:///dev/ttyUSB0`
3. Check permissions: `sudo chmod 666 /dev/ttyACM0`

#### Thread Network Formation Fails
**Problem**: OTBR shows "disabled" state  
**Solutions**:
1. Check channel conflicts with WiFi
2. Verify network parameters are valid
3. Reset Thread network: `docker exec otbr-mqtt-sn ot-ctl dataset clear`

#### MQTT-SN Gateway Connection Issues
**Problem**: No MQTT messages received  
**Solutions**:
1. Check MQTT broker connectivity: `ping mqtt.eclipseprojects.io`
2. Verify firewall settings
3. Check gateway logs: `docker logs otbr-mqtt-sn | grep MQTT`

#### Port 8080 Already in Use
**Problem**: `bind: address already in use`  
**Solution**: Use different port mapping: `-p 8081:80`

#### Privileged Mode Issues
**Problem**: Container networking fails  
**Solutions**:
1. Ensure `--privileged` flag is used
2. Check Docker daemon has sufficient permissions
3. Verify host network interfaces are available

### Debug Commands

```bash
# Check container logs
docker logs otbr-mqtt-sn

# Access container shell
docker exec -it otbr-mqtt-sn bash

# Check Thread status
docker exec otbr-mqtt-sn ot-ctl state
docker exec otbr-mqtt-sn ot-ctl dataset active

# Check network interfaces
docker exec otbr-mqtt-sn ip addr show

# Test MQTT connectivity
docker exec otbr-mqtt-sn ping mqtt.eclipseprojects.io
```

## 🔗 Related Projects and Resources

### Documentation
- **OpenThread**: https://openthread.io/guides/border-router
- **MQTT-SN Specification**: http://mqtt.org/new/wp-content/uploads/2009/06/MQTT-SN_spec_v1.2.pdf
- **Paho MQTT-SN**: https://github.com/eclipse-paho/paho.mqtt-sn.embedded-c

### Compatible Hardware
- **nRF52840 Dongle**: Nordic Semiconductor PCA10059
- **nRF52840 DK**: Nordic Semiconductor PCA10056
- **Other OpenThread RCP devices**: Check OpenThread platform support

### MQTT Brokers
- **Eclipse Mosquitto**: https://mosquitto.org/
- **AWS IoT Core**: https://aws.amazon.com/iot-core/
- **Azure IoT Hub**: https://azure.microsoft.com/en-us/services/iot-hub/

## 🤝 Contributing

Issues and pull requests are welcome! Please see our [issue tracker](https://github.com/osaether/otbr-mqtt-sn/issues) for current known issues and feature requests.

## 📄 License

This project follows the licensing of its components:
- **OpenThread**: BSD 3-Clause License
- **Paho MQTT-SN**: Eclipse Public License v2.0

See the respective project repositories for full license details.