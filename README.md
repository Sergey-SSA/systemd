# systemd

**Задача 1 - написать скрипт, который мониторит log-файл на наличие ключевого слова**

Файл [mydaemon.sh] (https://github.com/Sergey-SSA/systemd/blob/master/mydaemon.sh) запускается unit-ом [mydaemon.service] (https://github.com/Sergey-SSA/systemd/blob/master/mydaemon.service) каждые 30 секунд unit-ом [mydaemon.timer] (https://github.com/Sergey-SSA/systemd/blob/master/mydaemon.timer)

**Задача 2 - дополнить unit-файл сервиса httpd возможностью запустить несколько экземпляров сервиса с разными конфигурационными файлами.**

Создал unit для 1 сервиса.

`cat > /etc/systemd/system/httpd@first.service`

```
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Создал unit для 2 сервиса.

`cat /etc/systemd/system/httpd@second.service`

```
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target```

**Задача 3 - ограничить сервис.**

Проверил, какие ограницения установлены

`ulimit -a`

```
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 63684
max locked memory       (kbytes, -l) 16384
max memory size         (kbytes, -m) unlimited
open files                      (-n) 1024
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 63684
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited
```

Ограничил всех пользователей на терминале по памяти

`/etc/systemd/user.conf`

```
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# You can override the directives in this file by creating files in
# /etc/systemd/user.conf.d/*.conf.
#
# See systemd-user.conf(5) for details

[Manager]
#LogLevel=info
#LogTarget=console
#LogColor=yes
#LogLocation=no
#SystemCallArchitectures=
#TimerSlackNSec=
#DefaultTimerAccuracySec=1min
#DefaultStandardOutput=inherit
#DefaultStandardError=inherit
#DefaultTimeoutStartSec=90s
#DefaultTimeoutStopSec=90s
#DefaultRestartSec=100ms
#DefaultStartLimitIntervalSec=10s
#DefaultStartLimitBurst=5
#DefaultEnvironment=
#DefaultLimitCPU=
#DefaultLimitFSIZE=
#DefaultLimitDATA=
#DefaultLimitSTACK=
#DefaultLimitCORE=
#DefaultLimitRSS=
#DefaultLimitNOFILE=
#DefaultLimitAS=
#DefaultLimitNPROC=
DefaultLimitMEMLOCK=250Mb
#DefaultLimitLOCKS=
#DefaultLimitSIGPENDING=
#DefaultLimitMSGQUEUE=
#DefaultLimitNICE=
#DefaultLimitRTPRIO=
#DefaultLimitRTTIME=
```

Далее ограничил сервис apache

`systemctl status apache2`

```
● apache2.service - The Apache HTTP Server
   Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
  Drop-In: /lib/systemd/system/apache2.service.d
           └─apache2-systemd.conf
   Active: active (running) since Thu 2020-05-28 19:21:32 MSK; 3h 45min ago
  Process: 4232 ExecReload=/usr/sbin/apachectl graceful (code=exited, status=0/SUCCESS)
  Process: 992 ExecStart=/usr/sbin/apachectl start (code=exited, status=0/SUCCESS)
 Main PID: 1118 (apache2)
       IP: 0B in, 0B out
    Tasks: 55 (limit: 4915)
   Memory: 7.6M
      CPU: 395ms
   CGroup: /system.slice/apache2.service
           ├─1118 /usr/sbin/apache2 -k start
           ├─4236 /usr/sbin/apache2 -k start
           └─4237 /usr/sbin/apache2 -k start
```

*выше видно расход памяти 7.6M*

Прописал секцию [Service] с параметром memoryLimit=7M в файле /lib/systemd/system/apache2.service.d/apache2-systemd.conf и проверил результат

`/lib/systemd/system/apache2.service.d/apache2-systemd.conf`


>systemctl cat apache2.service

```
# /lib/systemd/system/apache2.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
Environment=APACHE_STARTED_BY_SYSTEMD=true
ExecStart=/usr/sbin/apachectl start
ExecStop=/usr/sbin/apachectl stop
ExecReload=/usr/sbin/apachectl graceful
PrivateTmp=true
Restart=on-abort

[Install]
WantedBy=multi-user.target

# /lib/systemd/system/apache2.service.d/apache2-systemd.conf
[Service]
Type=forking
RemainAfterExit=no
memoryLimit=7M
```

>systemctl status apache2.service

```
● apache2.service - The Apache HTTP Server
   Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
  Drop-In: /lib/systemd/system/apache2.service.d
           └─apache2-systemd.conf
   Active: active (running) since Thu 2020-05-28 23:17:31 MSK; 3min 25s ago
  Process: 6745 ExecStop=/usr/sbin/apachectl stop (code=exited, status=0/SUCCESS)
  Process: 4232 ExecReload=/usr/sbin/apachectl graceful (code=exited, status=0/SUCCESS)
  Process: 6750 ExecStart=/usr/sbin/apachectl start (code=exited, status=0/SUCCESS)
 Main PID: 6775 (apache2)
       IP: 0B in, 0B out
    Tasks: 55 (limit: 4915)
   Memory: 6.1M
      CPU: 41ms
   CGroup: /system.slice/apache2.service
           ├─6775 /usr/sbin/apache2 -k start
           ├─6777 /usr/sbin/apache2 -k start
           └─6778 /usr/sbin/apache2 -k start
```
