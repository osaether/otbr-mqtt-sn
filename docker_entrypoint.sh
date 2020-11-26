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
            BACKBONE_INTERFACE_ARG="-B $2"
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

        *)
            shift
            ;;
        esac
    done
}

parse_args "$@"

[ -n "$RADIO_URL" ] || RADIO_URL="spinel+hdlc+uart:///dev/ttyACM0"
[ -n "$TUN_INTERFACE_NAME" ] || TUN_INTERFACE_NAME="wpan0"
[ -n "$AUTO_PREFIX_ROUTE" ] || AUTO_PREFIX_ROUTE=true
[ -n "$AUTO_PREFIX_SLAAC" ] || AUTO_PREFIX_SLAAC=true
[ -n "$NAT64_PREFIX" ] || NAT64_PREFIX="64:ff9b::/96"
[ -n "$PSKC" ] || PSKC="5ce66d049d007088ad900dfcc2a55ee3"
# Use same default network configuration as the Nordic Semiconductor Raspberry PI
# borderrouter (see /etc/border_router.conf on the RPI)
[ -n "$MASTER_KEY" ] || MASTER_KEY="00112233445566778899AABBCCDDEEFF"
[ -n "$PANID" ] || PANID="0xABCD"
[ -n "$XPANID" ] || XPANID="DEAD00BEEF00CAFE"
[ -n "$CHANNEL" ] || CHANNEL="11"
[ -n "$BROKER_NAME" ] || BROKER_NAME="mqtt.eclipse.org"

echo "RADIO_URL:" $RADIO_URL
echo "TUN_INTERFACE_NAME:" $TUN_INTERFACE_NAME
echo "BACKBONE_INTERFACE: $BACKBONE_INTERFACE_ARG"
echo "NAT64_PREFIX:" $NAT64_PREFIX
echo "AUTO_PREFIX_ROUTE:" $AUTO_PREFIX_ROUTE
echo "AUTO_PREFIX_SLAAC:" $AUTO_PREFIX_SLAAC

NAT64_PREFIX=${NAT64_PREFIX/\//\\\/}

sed -i "s/^prefix.*$/prefix $NAT64_PREFIX/" /etc/tayga.conf
sed -i "s/dns64.*$/dns64 $NAT64_PREFIX {};/" /etc/bind/named.conf.options

sed -i "s/^BrokerName=.*$/BrokerName=$BROKER_NAME/" /app/gateway.conf
sed -i "s/^GatewayUDP6Hops=.*$/GatewayUDP6Hops=64/" /app/gateway.conf
sed -i "s/^GatewayUDP6Port=.*$/GatewayUDP6Port=47193/" /app/gateway.conf

echo "OTBR_AGENT_OPTS=\"-I $TUN_INTERFACE_NAME $BACKBONE_INTERFACE_ARG -d7 $RADIO_URL\"" >/etc/default/otbr-agent
echo "OTBR_WEB_OPTS=\"-I $TUN_INTERFACE_NAME -d7 -p 80\"" >/etc/default/otbr-web

echo "net.ipv6.conf.all.disable_ipv6=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf

/app/script/server
sleep 5

ot-ctl dataset init new
ot-ctl dataset networkname "$NETWORK_NAME"
ot-ctl dataset activetimestamp 1
ot-ctl dataset masterkey "$MASTER_KEY"
ot-ctl dataset panid "$PANID"
ot-ctl dataset extpanid "$XPANID"
ot-ctl dataset channel "$CHANNEL"
ot-ctl dataset pskc "$PSKC"
ot-ctl dataset commit active
ot-ctl ifconfig up
ot-ctl thread start

MESH=$(ot-ctl dataset meshlocalprefix | sed -n 1p | sed 's/Mesh Local Prefix: //' | awk -F '::' '{print $1}')
sed -i "s/^GatewayUDP6Broadcast=.*$/GatewayUDP6Broadcast=ff33:40:$MESH::1/" /app/gateway.conf

echo "Starting MQTT-SN Gateway"
nohup 2>&1 /app/MQTT-SNGateway &

tail -f /var/log/syslog
