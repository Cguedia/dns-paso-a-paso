# Práctica: Configuración de un servidor DNS con BIND9

En este documento se registran los pasos de configuración del servidor DNS y las capturas de pantalla de las pruebas realizadas.

**Autor:** Cristóbal  
**Proyecto:** dns-paso-a-paso

## 1. Objetivo

Instalar, configurar y validar un servidor DNS autoritativo con BIND9 en una máquina virtual Debian, incluyendo resolución directa e inversa.

## 2. Requisitos

- Vagrant y un proveedor de virtualización compatible (por ejemplo, VirtualBox).
- Acceso a una máquina Debian desplegada con Vagrant.
- Paquetes DNS: `bind9`, `bind9utils`, `bind9-doc` y `dnsutils`.

## 3. Repositorio y control de versiones

El repositorio utilizado es `dns-paso-a-paso` en GitHub.

### Captura 1. Repositorio de GitHub

![Repositorio de GitHub](images/0.png)

*Se muestra el repositorio y su estructura de archivos.*

![Repositorio de GitHub](images/1.png)

## 4. Infraestructura con Vagrant

Se utiliza Vagrant para desplegar una máquina virtual Debian donde se instala y configura el servidor DNS.

La máquina dispone de una interfaz de red privada en `192.168.56.10/24`.

### 4.1. Comandos de despliegue

```bash
vagrant up
vagrant ssh
```

- `vagrant up`: crea e inicia la máquina virtual.
- `vagrant ssh`: abre una sesión SSH dentro de la máquina.

```bash
vagrant status
```

- `vagrant status`: muestra el estado actual de la máquina virtual.

## 5. Instalación de BIND9

Antes de las pruebas, conviene verificar que no existan entradas en `hosts` que falseen la resolución DNS.

- En Debian: `/etc/hosts`
- En Windows: `C:\Windows\System32\drivers\etc\hosts`

Instalación de paquetes:

```bash
sudo apt update
sudo apt install bind9 bind9utils bind9-doc dnsutils
```

Comprobación inicial del servicio:

```bash
sudo systemctl status bind9
```

Resultado esperado: servicio `bind9` activo (o al menos instalado correctamente y listo para iniciarse).

### Captura 4. Instalación de BIND9

![Instalación de BIND9](images/5.png)

*Se muestra la instalación de los paquetes y el estado del servicio.*

![Instalación de BIND9](images/6.png)

## 6. Configuración general de BIND9

### 6.1. Forzar funcionamiento en IPv4 (`/etc/default/named`)

Se modifica `/etc/default/named` para indicar que BIND9 trabaje con IPv4 (opción `-4`).

Antes de editar, se crea copia de seguridad:

```bash
sudo cp /etc/default/named /etc/default/named.backup
```

![Configuración IPv4 en named](images/7.png)

![Configuración IPv4 en named](images/8.png)

### 6.2. Archivo principal `named.conf` (`/etc/bind/named.conf`)

El archivo principal incluye los ficheros de configuración de opciones, zonas locales y zonas por defecto.

Antes de editar, se crea copia de seguridad correcta del archivo principal:

```bash
sudo cp /etc/bind/named.conf /etc/bind/named.conf.backup
```

![Archivo principal named.conf](images/10.png)

```conf
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
```

![Archivo principal named.conf](images/9.png)

### 6.3. Opciones globales (`/etc/bind/named.conf.options`)

Antes de modificar el archivo, se crea copia de seguridad:

```bash
sudo cp /etc/bind/named.conf.options \
  /etc/bind/named.conf.options.backup
```

![Opciones globales de BIND9](images/12.png)

## 7. Configuración de la zona directa

En `/etc/bind/named.conf.local` se declara la zona directa principal.

![Configuración de zona directa](images/14.png)

*Se muestra el archivo de zona directa y sus registros DNS.*

## 8. Configuración de la zona inversa

La zona inversa permite obtener el nombre de dominio a partir de una dirección IPv4.

Para la red `192.168.56.0/24`, se declara:

```conf
zone "56.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/cristobal.test.rev";
};
```

![Configuración de zona inversa](images/17.png)

El archivo de zona inversa contiene los registros PTR asociados.

![Registros de zona inversa](images/18.png)

## 9. Validación de configuración

Comprobación de sintaxis global:

```bash
sudo named-checkconf
```

Comprobación de zonas (ejemplo habitual):

```bash
sudo named-checkzone cristobal.test /etc/bind/db.cristobal.test
sudo named-checkzone 56.168.192.in-addr.arpa /etc/bind/cristobal.test.rev
```

Resultado esperado: comprobaciones correctas, sin errores de sintaxis ni de carga de zonas.

Reinicio y verificación del servicio:

```bash
sudo systemctl restart bind9
sudo systemctl status bind9
```

Resultado esperado: servicio `bind9` activo después del reinicio.

### Captura 8. Validación de las zonas

## 10. Pruebas de resolución DNS

Se realizan consultas directas e inversas contra el servidor DNS con `dig` y `nslookup`.

![Pruebas de resolución DNS](images/20.png)

*Se muestran consultas de resolución directa e inversa realizadas al servidor.*

## 11. Tareas de ampliación

### 11.1. Registro CNAME y TXT

Se añade un alias `web` (CNAME) que apunta al nombre canónico del servidor, y un registro TXT para validación adicional.

![Ampliación con CNAME/TXT](images/1-anplificacion.png)

## 12. Script de autocomprobación

Se utiliza el script `config/test-dns.sh` para automatizar consultas DNS de validación.

El script ejecuta pruebas de:

- Resolución directa (`A`).
- Resolución inversa (`PTR`).
- Alias (`CNAME`).
- Registro de texto (`TXT`).

Ejecución del script:

```bash
chmod +x config/test-dns.sh
sudo ./config/test-dns.sh
```

Resultado esperado: obtención de respuestas DNS para cada bloque de prueba (`DNS directo`, `DNS inverso`, `CNAME` y `TXT`) sin errores de ejecución.

![Script de autocomprobación](images/3am.png)

### Captura 14. Ejecución del script de pruebas

![Ejecución del script de pruebas](images/Amplificacion4.png)

*Se muestra la ejecución de `test-dns.sh` y los resultados obtenidos.*

## 13. Resultado y conclusiones

Al finalizar la práctica, debe quedar funcionando:

- Un servidor BIND9 operativo en la máquina Debian.
- La resolución directa para la zona configurada (`cristobal.test`).
- La resolución inversa para la red `192.168.56.0/24`.
- Las ampliaciones de pruebas (`CNAME` y `TXT`).
- Un flujo de verificación reproducible mediante `named-checkconf`, `named-checkzone`, `dig`, `nslookup` y `config/test-dns.sh`.

Con ello, la infraestructura DNS queda documentada y validada con evidencias de ejecución (capturas incluidas en este documento).
