#!/bin/bash
#
#  Copyright (c) 2018, The OpenThread Authors.
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#  3. Neither the name of the copyright holder nor the
#     names of its contributors may be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

function parse_args()
{
    while [ $# -gt 0 ]
    do
        case $1 in
        --radio-url)
            RADIO_URL="$2"
            shift
            shift
            ;;
        --interface|-I)
            TUN_INTERFACE_NAME=$2
            shift
            shift
            ;;
        --backbone-interface | -B)
            BACKBONE_INTERFACE=$2
            shift
            shift
            ;;
        --nat64-prefix)
            NAT64_PREFIX=$2
            shift
            shift
            ;;
        --disable-default-prefix-route)
            AUTO_PREFIX_ROUTE=false
            shift
            ;;
        --disable-default-prefix-slaac)
            AUTO_PREFIX_SLAAC=false
            shift
            ;;
        --panid)
            PANID=$2
            shift
            shift
            ;;
        --xpanid)
            XPANID=$2
            shift
            shift
            ;;
        --channel)
            CHANNEL=$2
            shift
            shift
            ;;
        --network-name)
            NETWORK_NAME=$2
            shift
            shift
            ;;
        --masterkey-key)
            MASTER_KEY=$2
            shift
            shift
            ;;
        --psck)
            PSKC=$2
            shift
            shift
            ;;

        --broker)
            BROKER_NAME=$2
            shift
            shift
            ;;

        --mqttsn-broadcast-address)
           MQTTSN_BROADCAST_ADDRESS=$2
           shift
           shift
           ;;

        *)
            shift
            ;;
        esac
    done
}

parse_args "$@"

[ -n "$RADIO_URL" ] || RADIO_URL="spinel+hdlc+uart:///dev/ttyACM0"
[ -n "$TUN_INTERFACE_NAME" ] || TUN_INTERFACE_NAME="wpan0"
[ -n "$BACKBONE_INTERFACE" ] || BACKBONE_INTERFACE="eth0"
[ -n "$AUTO_PREFIX_ROUTE" ] || AUTO_PREFIX_ROUTE=true
[ -n "$AUTO_PREFIX_SLAAC" ] || AUTO_PREFIX_SLAAC=true
[ -n "$NAT64_PREFIX" ] || NAT64_PREFIX="64:ff9b::/96"
[ -n "$NETWORK_NAME" ] || NETWORK_NAME="OTBR-MQTT-SN"
[ -n "$PSKC" ] || PSKC="5ce66d049d007088ad900dfcc2a55ee3"
# Use same default network configuration as the Nordic Semiconductor Raspberry PI
# borderrouter (see /etc/border_router.conf on the RPI)
[ -n "$MASTER_KEY" ] || MASTER_KEY="00112233445566778899AABBCCDDEEFF"
[ -n "$PANID" ] || PANID="0xABCD"
[ -n "$XPANID" ] || XPANID="DEAD00BEEF00CAFE"
[ -n "$CHANNEL" ] || CHANNEL="11"
[ -n "$BROKER_NAME" ] || BROKER_NAME="mqtt.eclipseprojects.io"

echo "RADIO_URL:" $RADIO_URL
echo "TUN_INTERFACE_NAME:" $TUN_INTERFACE_NAME
echo "BACKBONE_INTERFACE:" $BACKBONE_INTERFACE
echo "NAT64_PREFIX:" $NAT64_PREFIX
echo "AUTO_PREFIX_ROUTE:" $AUTO_PREFIX_ROUTE
echo "AUTO_PREFIX_SLAAC:" $AUTO_PREFIX_SLAAC

NAT64_PREFIX=${NAT64_PREFIX/\//\\\/}

sed -i "s/^prefix.*$/prefix $NAT64_PREFIX/" /etc/tayga.conf
sed -i "s/dns64.*$/dns64 $NAT64_PREFIX {};/" /etc/bind/named.conf.options

sed -i "s/^BrokerName=.*$/BrokerName=$BROKER_NAME/" /app/gateway.conf
sed -i "s/^GatewayUDP6Hops=.*$/GatewayUDP6Hops=64/" /app/gateway.conf
sed -i "s/^GatewayUDP6Port=.*$/GatewayUDP6Port=47193/" /app/gateway.conf

echo "OTBR_AGENT_OPTS=\"-I $TUN_INTERFACE_NAME -B $BACKBONE_INTERFACE -d7 $RADIO_URL\"" >/etc/default/otbr-agent
echo "OTBR_WEB_OPTS=\"-I $TUN_INTERFACE_NAME -d7 -p 80\"" >/etc/default/otbr-web

echo "net.ipv6.conf.all.disable_ipv6=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf

/app/script/server
# ensure enough time for the otbr services to start
sleep 20

ot-ctl dataset init new
ot-ctl dataset networkname "$NETWORK_NAME"
# Set the dataset timestamp to 'now'. This will ensure that when the border router is
# restarted (and thus gets  a different mesh-local prefix), the nodes which were previously
# connected to the network will be forced to move over to this new mesh-local prefix.
ot-ctl dataset activetimestamp $(date +%s)
ot-ctl dataset networkkey "$MASTER_KEY"
ot-ctl dataset panid "$PANID"
ot-ctl dataset extpanid "$XPANID"
ot-ctl dataset channel "$CHANNEL"
# Since 20/06/2021, the default OpenThread config (and therefore also the default border router
# docker image) has Thread 1.2.1 "MLE Announce" turned on. This is a feature which announces the
# presence of the network periodically on all channels in the active dataset's channel mask, but
# has the consequence of making the router switch away from the active channel for a bit. If you
# have sleepy end devices connected to the router, these may end up going to a detached state if
# they attempt a data poll when the parent has switched away to announce on another channel.
# To avoid this, set the channel mask for the border router such that only the configured channel
# is allowed. This avoids the issue with the announce feature, but will prevent channel hopping
# from taking place (which would be a very advanced use-case versus having sleepy devices in the
# network).
CHANNELMASK=$((2 ** $CHANNEL))
CHANNELMASK=$(printf '0x%08x' $CHANNELMASK)
ot-ctl dataset channelmask $CHANNELMASK
ot-ctl dataset pskc "$PSKC"
ot-ctl dataset commit active
ot-ctl ifconfig up
ot-ctl thread start

# Set the address on which the MQTT-SN gateway needs to listen for discovery requests
# Defaults to Thread's mesh-local "all nodes" address unless explicitly overridden
MESH=$(ot-ctl dataset meshlocalprefix | sed -n 1p | sed 's/Mesh Local Prefix: //' | awk -F '::' '{print $1}')
[ -n "$MQTTSN_BROADCAST_ADDRESS" ] || MQTTSN_BROADCAST_ADDRESS="ff33:40:$MESH::1"
sed -i "s/^GatewayUDP6Broadcast=.*$/GatewayUDP6Broadcast=$MQTTSN_BROADCAST_ADDRESS/" /app/gateway.conf

echo "Starting MQTT-SN Gateway listening on: " $MQTTSN_BROADCAST_ADDRESS
nohup 2>&1 /app/MQTT-SNGateway &

tail -f /var/log/syslog
