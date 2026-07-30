#!/bin/bash
# Simple Script en Bash Shell 1.0.x., desactiva modo x, modo grafico en Kali Linux,  en Linux Debian

echo "Desactiva modo x, modo grafico en Kali Linux"
sleep 3
echo
echo "Ctrol+C,  si no quieres deactivar el modo grafico X"
sleep 9

# systemctl set-default multi-user.target

echo
echo "desactivado modo grafico!!"
echo "si quieres revertir el modo X"
echo "sudo systemctl start graphical.target"
echo
