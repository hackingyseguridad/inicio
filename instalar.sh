#!/bin/sh
echo 
# Actualizador de paguetes para distrubuciones basadas en Debian 
# Se instalara en la carperta /sbin/ para poder ser invocado y ejecutardo como un comando de Linux
echo
echo "(c) hackingyseguridad.com 2026"
echo
echo "Instalando ..."
echo
echo "Estableciendo hora"
timedatectl set-timezone Europe/Madrid
timedatectl set-local-rtc 1
timedatectl
echo
echo "Copiando ficheros ..."
chmod 777 apaga
cp apaga /sbin/
chmod 777 reinicia
cp reinicia /sbin/
chmod 777 apagar
cp apagar /sbin/
echo "Instalando ... "
chmod 777 *.sh
setxkbmap es sundeadkeys

sudo locale-gen es_ES.UTF-8
sudo localedef -i es_ES -f UTF-8 es_ES.UTF-8

locale-gen es_ES.UTF-8
cp keyboard /etc/default/
cp locale /etc/default/
echo "ñ"
echo "configurado el teclado a ES ! "
echo 
echo
echo "Instalado !!!"
echo

