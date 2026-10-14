# Documentacion de la practica DNS 
En este documento se registraran los pasos de configuracion del servidor DNS y las capturas de pantalla de las pruebas realizadas. 


# Práctica: Configuración de un servidor DNS con BIND9

**Autor:** Cristóbal  
**Proyecto:** dns-paso-a-paso  
**Sistema operativo:** Debian  
**Servicio DNS:** BIND9  
**Virtualización:** Vagrant

---

## Índice

1. [Objetivo](#1-objetivo)
2. [Control de versiones con Git y GitHub](#2-control-de-versiones-con-git-y-github)
3. [Infraestructura como código con Vagrant](#3-infraestructura-como-código-con-vagrant)
4. [Instalación del servidor DNS](#4-instalación-del-servidor-dns)
5. [Configuración general de BIND9](#5-configuración-general-de-bind9)
6. [Configuración de la zona directa](#6-configuración-de-la-zona-directa)
7. [Configuración de la zona inversa](#7-configuración-de-la-zona-inversa)
8. [Comprobación de la configuración](#8-comprobación-de-la-configuración)
9. [Pruebas de resolución DNS](#9-pruebas-de-resolución-dns)
10. [Tareas de ampliación](#10-tareas-de-ampliación)
11. [Script de autocomprobación](#11-script-de-autocomprobación)
12. [Automatización y provisión](#12-automatización-y-provisión)
13. [Conclusiones](#13-conclusiones)

---

## 1. Objetivo

El objetivo de esta práctica es instalar, configurar y comprobar un servidor DNS autoritativo utilizando BIND9 en una máquina virtual Debian.

Se configurará una zona de resolución directa y otra de resolución inversa. También se realizarán pruebas con `dig` y `nslookup` para verificar el funcionamiento del servicio.

Finalmente, se automatizará el despliegue mediante Vagrant y se documentará el proceso utilizando Git, GitHub y Markdown.

## 2. Control de versiones con Git y GitHub

Se ha creado un repositorio privado en GitHub con el nombre `dns-paso-a-paso`.

El repositorio contiene los archivos de configuración, los archivos de zona, los scripts de pruebas, el fichero Vagrantfile y la documentación.

Se utiliza Git para registrar los cambios realizados durante el desarrollo de la práctica.

Comandos utilizados:

```bash
git status
git add .
git commit -m "Describir el cambio realizado"
git push origin main
```

El archivo `.gitignore` contiene:

```gitignore
.vagrant/
```

### Captura 1. Repositorio de GitHub

![Repositorio de GitHub](../doc/images/0.png)

*Se muestra el repositorio y su estructura de archivos.*

### Captura 2. Control de versiones

![Historial de commits](capturas/02-historial-git.png)

*Se muestra el historial de commits realizados durante la práctica.*

## 3. Infraestructura como código con Vagrant

Se utiliza Vagrant para desplegar una máquina virtual Debian en la que se instala y configura el servidor DNS.

La máquina dispone de una interfaz de red privada con una dirección IP de la red `192.168.X.0/24`.

La carpeta del proyecto se comparte con la máquina virtual mediante `/vagrant`.

### Configuración de red

- Red privada: `192.168.X.0/24`.
- Dirección IP del servidor DNS: `192.168.X.Y`.
- Dirección del cliente: `192.168.X.Z`.

Los valores anteriores deben sustituirse por las direcciones utilizadas realmente.

### Comandos de despliegue

```bash
vagrant up
vagrant ssh
```

Para comprobar el estado de la máquina:

```bash
vagrant status
```

### Captura 3. Despliegue de Vagrant

![Despliegue de Vagrant](capturas/03-vagrant-up.png)

*Se muestra el inicio correcto de la máquina virtual.*

## 4. Instalación del servidor DNS

Antes de realizar las pruebas, se comprueba que el cliente no tenga entradas locales que falseen la resolución DNS en el archivo `hosts`.

En Debian, se revisa `/etc/hosts`. En Windows, se revisa `C:\Windows\System32\drivers\etc\hosts`.

Se instalan los paquetes necesarios:

```bash
sudo apt update
sudo apt install bind9 bind9utils bind9-doc dnsutils
```

Se comprueba el estado del servicio:

```bash
sudo systemctl status bind9
```

### Captura 4. Instalación de BIND9

![Instalación de BIND9](capturas/04-instalacion-bind9.png)

*Se muestra la instalación de los paquetes y el estado del servicio.*

## 5. Configuración general de BIND9

### 5.1. Configuración de IPv4

Se modifica el archivo `/etc/default/named` para indicar que BIND9 debe trabajar con IPv4.

La opción de configuración es:

```bash
OPTIONS="-u bind -4"
```

Se conserva el resto del contenido necesario del archivo.

### 5.2. Archivo principal named.conf

El archivo `/etc/bind/named.conf` incluye los archivos principales de configuración:

```conf
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
```

### 5.3. Configuración de named.conf.options

Antes de modificar el archivo se crea una copia de seguridad:

```bash
sudo cp /etc/bind/named.conf.options \
  /etc/bind/named.conf.options.backup
```

Se configura una lista de acceso para permitir consultas recursivas únicamente a los equipos de confianza.

Ejemplo orientativo:

```conf
acl confiables {
    127.0.0.1;
    192.168.X.0/24;
};

options {
    directory "/var/cache/bind";

    allow-transfer { none; };

    listen-on port 53 {
        127.0.0.1;
        192.168.X.Y;
    };

    recursion yes;
    allow-recursion { confiables; };

    dnssec-validation yes;
};
```

Se sustituye `X` e `Y` por los valores de la red y del servidor. Se comprueba que no existan opciones duplicadas o incompatibles con el resto de la configuración.

### Captura 5. Configuración de BIND9

![Configuración de BIND9](capturas/05-configuracion-bind9.png)

*Se muestran las opciones de escucha, la ACL y la configuración de recursividad.*

## 6. Configuración de la zona directa

Se configura una zona DNS cuyo nombre sigue el formato `tunombre.test`, sustituyendo `tunombre` por el nombre elegido para la práctica.

En `/etc/bind/named.conf.local` se declara la zona:

```conf
zone "tunombre.test" {
    type master;
    file "/var/lib/bind/tunombre.test.dns";
};
```

Se crea el archivo de zona `/var/lib/bind/tunombre.test.dns`.

Ejemplo de contenido:

```dns
$TTL 86400

@ IN SOA debian.tunombre.test. admin.tunombre.test. (
    2026101401
    3600
    1800
    604800
    86400
)

@ IN NS debian.tunombre.test.
debian.tunombre.test. IN A 192.168.X.Y
```

El registro SOA contiene información administrativa de la zona. El registro NS identifica el servidor DNS y el registro A relaciona el nombre del servidor con su dirección IPv4.

El número de serie debe actualizarse cuando se modifica la zona.

### Captura 6. Zona directa

![Configuración de la zona directa](capturas/06-zona-directa.png)

*Se muestra el archivo de zona directa y sus registros DNS.*

## 7. Configuración de la zona inversa

La zona inversa permite obtener el nombre asociado a una dirección IPv4.

Para la red `192.168.X.0/24`, se declara la zona:

```conf
zone "X.168.192.in-addr.arpa" {
    type master;
    file "/var/lib/bind/tunombre.test.rev";
};
```

El archivo `/var/lib/bind/tunombre.test.rev` contiene los registros de resolución inversa.

Ejemplo:

```dns
$TTL 86400

@ IN SOA debian.tunombre.test. admin.tunombre.test. (
    2026101401
    3600
    1800
    604800
    86400
)

@ IN NS debian.tunombre.test.
Y IN PTR debian.tunombre.test.
```

Se sustituye `X` por el tercer octeto de la red e `Y` por el último octeto de la IP del servidor.

### Captura 7. Zona inversa

![Configuración de la zona inversa](capturas/07-zona-inversa.png)

*Se muestra la declaración de la zona inversa y su registro PTR.*

## 8. Comprobación de la configuración

Se comprueba la sintaxis general de BIND9:

```bash
sudo named-checkconf
```

También se valida el archivo de zona directa:

```bash
sudo named-checkzone tunombre.test \
  /var/lib/bind/tunombre.test.dns
```

Y la zona inversa:

```bash
sudo named-checkzone X.168.192.in-addr.arpa \
  /var/lib/bind/tunombre.test.rev
```

Si las comprobaciones son correctas, las herramientas deben indicar que las zonas se han cargado correctamente y devolver `OK` para cada zona.

Se reinicia el servicio:

```bash
sudo systemctl restart bind9
sudo systemctl status bind9
```

### Captura 8. Validación de las zonas

![Validación de BIND9](capturas/08-validacion-zonas.png)

*Se muestran los resultados reales de named-checkconf y named-checkzone.*

## 9. Pruebas de resolución DNS

Se realizan las consultas directamente al servidor DNS mediante `dig` y `nslookup`.

### 9.1. Resolución directa

```bash
dig @192.168.X.Y debian.tunombre.test
```

Con `nslookup`:

```bash
nslookup debian.tunombre.test 192.168.X.Y
```

La respuesta debe incluir la dirección IP configurada para el servidor.

### 9.2. Resolución inversa

```bash
dig @192.168.X.Y -x 192.168.X.Y
```

Con `nslookup`:

```bash
nslookup 192.168.X.Y 192.168.X.Y
```

La respuesta debe mostrar el nombre completo del servidor DNS.

### Captura 9. Pruebas de resolución

![Pruebas de resolución DNS](capturas/09-pruebas-dns.png)

*Se muestran las consultas directas e inversas realizadas al servidor.*

## 10. Tareas de ampliación

### 10.1. Registro CNAME

Se añade un alias `web` que apunta al nombre canónico del servidor.

En el archivo de zona directa:

```dns
web IN CNAME debian.tunombre.test.
```

Se incrementa el número de serie y se recarga BIND9.

Comprobación:

```bash
dig @192.168.X.Y web.tunombre.test CNAME +short
```

También se puede utilizar:

```bash
nslookup -type=CNAME web.tunombre.test 192.168.X.Y
```

### 10.2. Registro TXT

Se añade un registro TXT en la raíz de la zona para identificar al autor o usuario de GitHub.

Ejemplo:

```dns
@ IN TXT "Autor: Cristobal"
```

Comprobación:

```bash
dig @192.168.X.Y tunombre.test TXT +short
```

Y con `nslookup`:

```bash
nslookup -type=TXT tunombre.test 192.168.X.Y
```

### 10.3. Registro PTR

Se comprueba que la dirección IPv4 del servidor resuelva a su nombre completo:

```bash
dig @192.168.X.Y -x 192.168.X.Y +short
```

La respuesta esperada es el FQDN del servidor, siempre que el registro PTR y la zona inversa estén configurados correctamente.

### 10.4. Comprobación de autoridad DNS

Se consulta un nombre de la zona local:

```bash
dig @192.168.X.Y debian.tunombre.test
```

Después, se consulta un dominio externo:

```bash
dig @192.168.X.Y www.google.es
```

En la consulta autoritativa local debe aparecer la bandera `aa` si la respuesta procede de la zona autoritativa del servidor. En la consulta externa normalmente no aparecerá, porque el servidor está resolviendo el nombre mediante recursividad o caché.

### Captura 10. Registro CNAME

![Prueba CNAME](capturas/10-cname.png)

### Captura 11. Registro TXT

![Prueba TXT](capturas/11-txt.png)

### Captura 12. Resolución inversa PTR

![Prueba PTR](capturas/12-ptr.png)

### Captura 13. Bandera de autoridad AA

![Comprobación de autoridad DNS](capturas/13-autoridad-aa.png)

*Se comparan las respuestas de la zona local y del dominio externo.*

## 11. Script de autocomprobación

Se utiliza un script llamado `test.sh`, situado en la raíz del repositorio, para automatizar las comprobaciones principales.

El script debe verificar la sintaxis de BIND9, las zonas y las resoluciones DNS.

Se ejecuta mediante:

```bash
chmod +x test.sh
sudo ./test.sh
```

Las comprobaciones deben devolver resultados satisfactorios para considerar correcto el despliegue.

### Captura 14. Ejecución del script de pruebas

![Script de autocomprobación](capturas/14-test-script.png)

*Se muestra la ejecución de test.sh y los resultados obtenidos.*

## 12. Automatización y provisión

El fichero `Vagrantfile` define la máquina virtual, la red privada y los scripts de provisión necesarios.

Los archivos de configuración y de zona se almacenan en el repositorio y se copian a sus ubicaciones correspondientes dentro de la máquina virtual.

Después de copiar los archivos se valida la configuración, se reinicia BIND9 y se ejecuta el script de autocomprobación.

El objetivo es poder desplegar la práctica desde cero de forma reproducible.

### Captura 15. Despliegue automatizado

![Despliegue automatizado](capturas/15-despliegue-automatizado.png)

*Se muestra el despliegue de la máquina y la ejecución de las comprobaciones.*

## 13. Conclusiones

Durante esta práctica se ha trabajado con la instalación y configuración de BIND9 en Debian, la creación de zonas directas e inversas y la comprobación de registros DNS.

También se han realizado pruebas con `dig` y `nslookup`, se ha preparado un script de autocomprobación y se ha utilizado Vagrant para automatizar el despliegue.

La documentación en Markdown y el control de versiones con Git y GitHub permiten registrar los cambios y reproducir el proceso.

Los resultados finales deben corresponder con las pruebas ejecutadas realmente en el entorno de prácticas.
