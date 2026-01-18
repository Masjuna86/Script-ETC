===============================
FIREWALL INPUT FINAL PRODUKSI
LAN + OpenVPN + L2TP + TELEGRAM
RouterOS v7.x
===============================
===============================
1. ADDRESS-LIST ADMIN (LAN + VPN)
===============================

/ip firewall address-list
add list=ADMIN address=192.168.0.0/16 comment="ADMIN LAN"
add list=ADMIN address=10.0.0.0/8 comment="ADMIN LAN"
add list=ADMIN address=172.16.0.0/12 comment="ADMIN LAN"

OpenVPN (default common pool, sesuaikan bila beda)

add list=ADMIN address=10.8.0.0/24 comment="ADMIN OpenVPN"

L2TP (sesuaikan dengan IP Pool L2TP Anda)

add list=ADMIN address=172.16.100.0/24 comment="ADMIN L2TP"

===============================
2. FIREWALL INPUT – CORE
===============================

/ip firewall filter
add chain=input action=accept connection-state=established,related comment="ALLOW ESTABLISHED RELATED"
add chain=input action=drop connection-state=invalid comment="DROP INVALID"

FULL ACCESS UNTUK LAN + VPN

add chain=input action=accept src-address-list=ADMIN comment="ALLOW ADMIN LAN + VPN"

ICMP TERBATAS (PING AMAN)

add chain=input action=accept protocol=icmp limit=10,20:packet comment="ALLOW ICMP LIMITED"

===============================
3. BRUTE FORCE PROTECTION (WAN ONLY)
===============================
SSH & TELNET

add chain=input action=drop protocol=tcp dst-port=22,23 src-address-list=SSH_BLACKLIST log=yes log-prefix="ALERT_SSH_BRUTE"
add chain=input action=add-src-to-address-list address-list=SSH_STAGE_1 address-list-timeout=1m protocol=tcp dst-port=22,23 connection-state=new in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=SSH_STAGE_2 address-list-timeout=1m protocol=tcp dst-port=22,23 connection-state=new src-address-list=SSH_STAGE_1 in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=SSH_BLACKLIST address-list-timeout=1d protocol=tcp dst-port=22,23 connection-state=new src-address-list=SSH_STAGE_2 in-interface-list=WAN

WINBOX

add chain=input action=drop protocol=tcp dst-port=8291 src-address-list=WINBOX_BLACKLIST log=yes log-prefix="ALERT_WINBOX_BRUTE"
add chain=input action=add-src-to-address-list address-list=WINBOX_STAGE_1 address-list-timeout=1m protocol=tcp dst-port=8291 connection-state=new in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=WINBOX_STAGE_2 address-list-timeout=1m protocol=tcp dst-port=8291 connection-state=new src-address-list=WINBOX_STAGE_1 in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=WINBOX_BLACKLIST address-list-timeout=1d protocol=tcp dst-port=8291 connection-state=new src-address-list=WINBOX_STAGE_2 in-interface-list=WAN

FTP

add chain=input action=drop protocol=tcp dst-port=21 src-address-list=FTP_BLACKLIST log=yes log-prefix="ALERT_FTP_BRUTE"
add chain=input action=add-src-to-address-list address-list=FTP_BLACKLIST address-list-timeout=1d protocol=tcp dst-port=21 connection-state=new in-interface-list=WAN

===============================
4. PORT SCANNER PROTECTION
===============================

add chain=input action=add-src-to-address-list address-list=PORT_SCANNER address-list-timeout=2w protocol=tcp tcp-flags=fin,!syn,!rst,!psh,!ack,!urg in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=PORT_SCANNER address-list-timeout=2w protocol=tcp tcp-flags=fin,syn in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=PORT_SCANNER address-list-timeout=2w protocol=tcp tcp-flags=syn,rst in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=PORT_SCANNER address-list-timeout=2w protocol=tcp tcp-flags=fin,psh,urg,!syn,!rst,!ack in-interface-list=WAN
add chain=input action=add-src-to-address-list address-list=PORT_SCANNER address-list-timeout=2w protocol=tcp tcp-flags=!fin,!syn,!rst,!psh,!ack,!urg in-interface-list=WAN
add chain=input action=drop src-address-list=PORT_SCANNER log=yes log-prefix="ALERT_PORT_SCANNER"

===============================
5. FINAL LOCK – BLOK SEMUA DARI WAN
===============================

add chain=input action=drop in-interface-list=WAN comment="DROP ALL INPUT FROM WAN"

===============================
6. TELEGRAM ALERT SCRIPT
===============================

/system script
add name=Telegram-Firewall-Alert policy=read,write,test source="
:local BOT "ISI_BOT_TOKEN"
:local CHAT "ISI_CHAT_ID"
:local router [/system identity get name]

:local logs [/log find where message~"ALERT_"]

:if ([:len $logs] = 0) do={ :return }

:local msg "🚨 FIREWALL ALERT 🚨%0A"
:set msg ($msg . "Router : $router%0A%0A")

:foreach i in=$logs do={
:local time [/log get $i time]
:local text [/log get $i message]
:set msg ($msg . "🕒 $time%0A⚠ $text%0A%0A")
}

/tool fetch url=("https://api.telegram.org/bot\".\$BOT.\"/sendMessage?chat_id=\".\$CHAT.\"&text=\".\$msg
) keep-result=no
/log remove $logs
"

===============================
7. SCHEDULER TELEGRAM
===============================

/system scheduler
add name=Firewall-Telegram interval=1m on-event=Telegram-Firewall-Alert

===== END OF FILE =====

✅ SEBELUM & SESUDAH IMPORT (WAJIB CEK)
🔧 SEBELUM IMPORT

✔ Interface WAN sudah masuk interface-list=WAN
✔ OpenVPN & L2TP SUDAH CONNECT NORMAL
✔ IP pool VPN sesuai (jika beda, ubah subnet ADMIN)

🔐 SESUDAH IMPORT

✔ Winbox dari LAN → ✅
✔ Winbox dari OpenVPN → ✅
✔ Winbox dari L2TP → ✅
✔ Winbox dari Internet → ❌ (AMAN)
✔ Telegram alert masuk → ✅
