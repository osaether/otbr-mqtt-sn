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
        echo $1
        case $1 in
        --ncp-path)
            NCP_PATH=$2
            shift
            shift
            ;;
        --interface|-I)
            TUN_INTERFACE_NAME=$2
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
            NETWORK_PANID=$2
            shift
            shift
            ;;
        --xpanid)
            NETWORK_XPANID=$2
            shift
            shift
            ;;
        --ncp-channel)
            NCP_CHANNEL=$2
            shift
            shift
            ;;
        --network-name)
            NETWORK_NAME=$2
            shift
            shift
            ;;
        --network-key)
            NETWORK_KEY=$2
            shift
            shift
            ;;
        --psck)
            NETWORK_PSKC=$2
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

[ -n "$NCP_PATH" ] || NCP_PATH="/dev/ttyACM0"
[ -n "$TUN_INTERFACE_NAME" ] || TUN_INTERFACE_NAME="wpan0"
[ -n "$AUTO_PREFIX_ROUTE" ] || AUTO_PREFIX_ROUTE=true
[ -n "$AUTO_PREFIX_SLAAC" ] || AUTO_PREFIX_SLAAC=true
[ -n "$NAT64_PREFIX" ] || NAT64_PREFIX="64:ff9b::/96"
[ -n "$NETWORK_NAME" ] || NETWORK_NAME="OTBR-MQTT-SN"
# Use same default network configuration as the Nordic Semiconductor Raspberry PI
# borderrouter (see /etc/border_router.conf on the RPI)
[ -n "$NETWORK_KEY" ] || NETWORK_KEY="00112233445566778899AABBCCDDEEFF"
[ -n "$NETWORK_PANID" ] || NETWORK_PANID="0xABCD"
[ -n "$NETWORK_XPANID" ] || NETWORK_XPANID="DEAD00BEEF00CAFE"
[ -n "$NCP_CHANNEL" ] || NCP_CHANNEL="11"
[ -n "$NETWORK_PSKC" ] || NETWORK_PSKC="E00F739803E92CB42DAA7CCE1D2A394D"
[ -n "$BROKER_NAME" ] || BROKER_NAME="mqtt.eclipse.org"

echo "NCP_PATH:" $NCP_PATH
echo "TUN_INTERFACE_NAME:" $TUN_INTERFACE_NAME
echo "NAT64_PREFIX:" $NAT64_PREFIX
echo "AUTO_PREFIX_ROUTE:" $AUTO_PREFIX_ROUTE
echo "AUTO_PREFIX_SLAAC:" $AUTO_PREFIX_SLAAC

NAT64_PREFIX=${NAT64_PREFIX/\//\\\/}

sed -i "s/^prefix.*$/prefix $NAT64_PREFIX/" /etc/tayga.conf
sed -i "s/dns64.*$/dns64 $NAT64_PREFIX {};/" /etc/bind/named.conf.options

sed -i "s/^BrokerName=.*$/BrokerName=$BROKER_NAME/" /app/borderrouter/gateway.conf

echo "Config:NCP:SocketPath \"$NCP_PATH\"" > /etc/wpantund.conf
echo "Config:TUN:InterfaceName $TUN_INTERFACE_NAME " >> /etc/wpantund.conf
echo "Daemon:SetDefaultRouteForAutoAddedPrefix $AUTO_PREFIX_ROUTE" >> /etc/wpantund.conf
echo "IPv6:SetSLAACForAutoAddedPrefix $AUTO_PREFIX_SLAAC" >> /etc/wpantund.conf

echo "OTBR_AGENT_OPTS=\"-I $TUN_INTERFACE_NAME\"" > /etc/default/otbr-agent
echo "OTBR_WEB_OPTS=\"-I $TUN_INTERFACE_NAME -p 80\"" > /etc/default/otbr-web

echo "net.ipv6.conf.all.disable_ipv6=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf

NAT64=1 DNS64=1 /app/borderrouter/script/server

echo "Starting MQTT-SN Gateway"
nohup 2>&1 /app/borderrouter/MQTT-SNGateway &

###############################################################################
# Atach to the Thread network.
###############################################################################

CNK=0
if !(wpanctl getprop Network:Key | grep -q "Network:Key = \[\"$NETWORK_KEY\"\]"); then
    CNK=1
fi

CNN=0
if !(wpanctl getprop Network:Name | grep -q "Network:Name = \"$NETWORK_NAME\""); then
    CNN=1
fi

CNP=0
if !(wpanctl getprop Network:PANID | grep -q "Network:PANID = \"$NETWORK_PANID\""); then
    CNP=1
fi

CNX=0
if !(wpanctl getprop Network:XPANID | grep -q "Network:XPANID = \"$NETWORK_XPANID\""); then
    CNX=1
fi

CNC=0
if !(wpanctl getprop NCP:Channel | grep -q "NCP:Channel = \"$NCP_CHANNEL\""); then
    CNC=1
fi

CNS=0
if !(wpanctl getprop Network:PSKc | grep -q "Network:PSKc = \[\"$NETWORK_PSKC\"\]"); then
    CNS=1
fi

if (( $CNK==1 )) || (( $CNN==1 )) || (( $CNP==1 )) || (( $CNX==1 )) || (( $CNC==1 )) || (( $CNS==1 )); then
    wpanctl leave
    sleep 1

    wpanctl reset
    sleep 2
fi

if (( $CNK==1 )); then
    wpanctl setprop Network:Key --data $NETWORK_KEY
fi

if (( $CNN==1 )); then
    wpanctl setprop Network:Name $NETWORK_NAME
fi

if (( $CNP==1 )); then
    wpanctl setprop Network:PANID $NETWORK_PANID
fi

if (( $CNX==1 )); then
    wpanctl setprop Network:XPANID $NETWORK_XPANID
fi

if (( $CNC==1 )); then
    wpanctl setprop NCP:Channel $NCP_CHANNEL
fi

if (( $CNS==1 )); then
    wpanctl setprop Network:PSKc $NETWORK_PSKC
fi

if (( $CNK==1 )) || (( $CNN==1 )) || (( $CNP==1 )) || (( $CNX==1 )) || (( $CNC==1 )) || (( $CNS==1 )); then
    wpanctl attach
    sleep 3
fi    

wpanctl status


while [ $? = 0 ]
do
    sleep 60
done
