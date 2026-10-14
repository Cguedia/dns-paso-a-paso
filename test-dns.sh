#!/bin/bash

echo "=== Prueba de DNS directo ==="
dig @127.0.0.1 cristobal.test
dig @127.0.0.1 ns1.cristobal.test

echo "=== Prueba de DNS inverso ==="
dig @127.0.0.1 -x 192.168.56.10

echo "=== Prueba CNAME ==="
dig @127.0.0.1 ftp.cristobal.test

echo "=== Prueba TXT ==="
dig @127.0.0.1 cristobal.test TXT
