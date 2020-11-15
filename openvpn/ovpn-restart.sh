#!/usr/bin/env bash

# Check vpn-tunnel "tun0" and ping cz.nic if internet connection work
if  [ "$(ping -I tun0 -q -c 1 -W 1 193.17.47.1 | grep '100% packet loss' )" != "" ]; then
        logger -t VPN_Reconnect VPN-Tunnel "tun0" has got no internet connectionection -> restart it
        /etc/init.d/openvpn stop
        sleep 3
        /etc/init.d/openvpn start
else
        logger -t VPN_Reconnect VPN-Tunnel "tun0" is working with internet connection
fi

