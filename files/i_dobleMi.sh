#!/bin/bash
# - Script creado por dobleM
#Formatear texto con colores: https://unix.stackexchange.com/a/92568
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
magenta='\e[1;35m'
cyan='\e[1;36m'
end='\e[0m'

clear
echo Cargando...

# Detectando sistema operativo
	SYSTEM_DETECTOR="$(uname -a)"
	if [ "${SYSTEM_DETECTOR#*"synology"}" != "$SYSTEM_DETECTOR" ]; then
		SYSTEM_INFO="Synology/XPEnology"
	else 
		SYSTEM_INFO="$(sed -e '/PRETTY_NAME=/!d' -e 's/PRETTY_NAME=//g' /etc/*-release)"
	fi
	
# Sistema elegido: 1-Synology/XPEnology   2-LibreELEC/OpenELEC   3-Linux
	if [ "$1" = "Synology" ]; then
		SISTEMA_ELEGIDO="Synology/XPEnology"
		SYSTEM=1
	elif [ "$1" = "Libreelec" ]; then
		SISTEMA_ELEGIDO="LibreELEC/OpenELEC"
		SYSTEM=2
	elif [ "$1" = "Linux" ]; then
		SISTEMA_ELEGIDO="Linux"
		SYSTEM=3	
	fi	
	case $SYSTEM in
	1)
		TVHEADEND_SERVICE="$(synoservicecfg --list | grep tvheadend)" 2>>dobleM.log #"pkgctl-tvheadend-testing"
		if [ $? -ne 0 ]; then
			SERVICES_MANAGEMENT="OLD"
		else
			SERVICES_MANAGEMENT="NEW"
		fi
		TVHEADEND_USER="$(cut -d: -f1 /etc/passwd | grep tvheadend)" 2>>dobleM.log #"tvheadend-testing"
		TVHEADEND_GROUP="$(id -gn $TVHEADEND_USER)" 2>>dobleM.log #"users"
		TVHEADEND_PERMISSIONS="700" #"u=rwX,g=,o="
		TVHEADEND_CONFIG_DIR="/var/packages/$(ls /var/packages/ | grep tvheadend)/target/var" 2>>dobleM.log #"/var/packages/tvheadend-testing/target/var"
		TVHEADEND_GRABBER_DIR="/usr/local/bin";;
	2)
		TVHEADEND_SERVICE="$(systemctl list-unit-files --type=service | grep tvheadend | tr -s ' ' | cut -d' ' -f1)" 2>>dobleM.log #"service.tvheadend42.service"
		TVHEADEND_USER="root"
		TVHEADEND_GROUP="video"
		TVHEADEND_PERMISSIONS="700" #"u=rwX,g=,o="
		TVHEADEND_CONFIG_DIR="/storage/.kodi/userdata/addon_data/$(ls /storage/.kodi/userdata/addon_data/ | grep tvheadend)" 2>>dobleM.log #"/storage/.kodi/userdata/addon_data/service.tvheadend42"
		TVHEADEND_GRABBER_DIR="/storage/.kodi/addons/$(ls /storage/.kodi/addons/ | grep tvheadend)/bin" 2>>dobleM.log;; #"/storage/.kodi/addons/service.tvheadend42/bin"
	3)
		TVHEADEND_SERVICE="$(systemctl list-unit-files --type=service | grep tvheadend | tr -s ' ' | cut -d' ' -f1)" 2>>dobleM.log #"tvheadend.service"
		TVHEADEND_USER="$(cut -d: -f1 /etc/passwd | grep -E 'tvheadend|hts')" 2>>dobleM.log #"hts"
		TVHEADEND_GROUP="video" #"$(id -gn $TVHEADEND_USER)"
		TVHEADEND_PERMISSIONS="700" #"u=rwX,g=,o="
		TVHEADEND_CONFIG_DIR="/home/hts/.hts/tvheadend"
		TVHEADEND_GRABBER_DIR="/usr/bin";;
esac

# Parar/Iniciar tvheadend
PARAR_TVHEADEND()
{
	case $SYSTEM in
		1)
			if [ "$SERVICES_MANAGEMENT" = "OLD" ]; then
				"/var/packages/$(ls /var/packages/ | grep tvheadend)/scripts/start-stop-status" stop 1>dobleM.log 2>&1
			else
				stop -q $TVHEADEND_SERVICE 2>>dobleM.log
			fi;;
		2)
			systemctl stop $TVHEADEND_SERVICE 2>>dobleM.log;;
		3)
			service tvheadend stop 2>>dobleM.log;; #service tvheadend stop
	esac
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		SERVICE_ERROR=true
	fi
}
INICIAR_TVHEADEND()
{
	case $SYSTEM in
		1)
			if [ "$SERVICES_MANAGEMENT" = "OLD" ]; then
				"/var/packages/$(ls /var/packages/ | grep tvheadend)/scripts/start-stop-status" start 1>dobleM.log 2>&1
			else
				start -q $TVHEADEND_SERVICE 2>>dobleM.log
			fi;;
		2)
			systemctl start $TVHEADEND_SERVICE 2>>dobleM.log;;
		3)
			service tvheadend start 2>>dobleM.log;; #service tvheadend start
	esac
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		SERVICE_ERROR=true
	fi
}

# Variables config tvheadend
if [ -d $TVHEADEND_CONFIG_DIR/bouquet ]; then
	TVHEADEND_BOUQUET_USER=$(stat -c %U $TVHEADEND_CONFIG_DIR/bouquet) 2>/dev/null
	TVHEADEND_BOUQUET_GROUP=$(stat -c %G $TVHEADEND_CONFIG_DIR/bouquet) 2>/dev/null
	TVHEADEND_BOUQUET_PERMISSIONS=$(stat -c %a $TVHEADEND_CONFIG_DIR/bouquet) 2>/dev/null
else
	TVHEADEND_BOUQUET_USER=$TVHEADEND_USER
	TVHEADEND_BOUQUET_GROUP=$TVHEADEND_GROUP
	TVHEADEND_BOUQUET_PERMISSIONS=$TVHEADEND_PERMISSIONS
fi

if [ -d $TVHEADEND_CONFIG_DIR/channel ]; then
	TVHEADEND_CHANNEL_USER=$(stat -c %U $TVHEADEND_CONFIG_DIR/channel) 2>/dev/null
	TVHEADEND_CHANNEL_GROUP=$(stat -c %G $TVHEADEND_CONFIG_DIR/channel) 2>/dev/null
	TVHEADEND_CHANNEL_PERMISSIONS=$(stat -c %a $TVHEADEND_CONFIG_DIR/channel) 2>/dev/null
else
	TVHEADEND_CHANNEL_USER=$TVHEADEND_USER
	TVHEADEND_CHANNEL_GROUP=$TVHEADEND_GROUP
	TVHEADEND_CHANNEL_PERMISSIONS=$TVHEADEND_PERMISSIONS
fi

if [ -d $TVHEADEND_CONFIG_DIR/epggrab ]; then
	TVHEADEND_EPGGRAB_USER=$(stat -c %U $TVHEADEND_CONFIG_DIR/epggrab) 2>/dev/null
	TVHEADEND_EPGGRAB_GROUP=$(stat -c %G $TVHEADEND_CONFIG_DIR/epggrab) 2>/dev/null
	TVHEADEND_EPGGRAB_PERMISSIONS=$(stat -c %a $TVHEADEND_CONFIG_DIR/epggrab) 2>/dev/null
else
	TVHEADEND_EPGGRAB_USER=$TVHEADEND_USER
	TVHEADEND_EPGGRAB_GROUP=$TVHEADEND_GROUP
	TVHEADEND_EPGGRAB_PERMISSIONS=$TVHEADEND_PERMISSIONS
fi

if [ -d $TVHEADEND_CONFIG_DIR/input ]; then
	TVHEADEND_INPUT_USER=$(stat -c %U $TVHEADEND_CONFIG_DIR/input) 2>/dev/null
	TVHEADEND_INPUT_GROUP=$(stat -c %G $TVHEADEND_CONFIG_DIR/input) 2>/dev/null
	TVHEADEND_INPUT_PERMISSIONS=$(stat -c %a $TVHEADEND_CONFIG_DIR/input) 2>/dev/null
else
	TVHEADEND_INPUT_USER=$TVHEADEND_USER
	TVHEADEND_INPUT_GROUP=$TVHEADEND_GROUP
	TVHEADEND_INPUT_PERMISSIONS=$TVHEADEND_PERMISSIONS
fi

if [ -d $TVHEADEND_CONFIG_DIR/picons ]; then
	TVHEADEND_PICONS_USER=$(stat -c %U $TVHEADEND_CONFIG_DIR/picons) 2>/dev/null
	TVHEADEND_PICONS_GROUP=$(stat -c %G $TVHEADEND_CONFIG_DIR/picons) 2>/dev/null
	TVHEADEND_PICONS_PERMISSIONS=$(stat -c %a $TVHEADEND_CONFIG_DIR/picons) 2>/dev/null
else
	TVHEADEND_PICONS_USER=$TVHEADEND_USER
	TVHEADEND_PICONS_GROUP=$TVHEADEND_GROUP
	TVHEADEND_PICONS_PERMISSIONS=$TVHEADEND_PERMISSIONS
fi

command -v curl >/dev/null 2>&1 || { printf "$red%s\n%s$end\n" "ERROR: Es necesario tener instalado 'curl'." "Por favor, ejecute el script de nuevo una vez haya sido instalado."; exit 1; }
command -v wget >/dev/null 2>&1 || { printf "$red%s\n%s$end\n" "ERROR: Es necesario tener instalado 'wget'." "Por favor, ejecute el script de nuevo una vez haya sido instalado."; exit 1; }

ver_local=`cat $TVHEADEND_CONFIG_DIR/dobleM.ver 2>/dev/null`
ver_web=`curl https://raw.githubusercontent.com/davidmuma/Canales_dobleM/master/files/dobleM.ver 2>/dev/null`
ver_local_IPTV=`cat $TVHEADEND_CONFIG_DIR/dobleM-IPTV.ver 2>/dev/null`
ver_web_IPTV=`curl https://raw.githubusercontent.com/davidmuma/Canales_dobleM/master/files/dobleM-IPTV.ver 2>/dev/null`

NOMBRE_APP="dobleM"
NOMBRE_APP_IPTV="dobleM-IPTV"
CARPETA_DOBLEM="$TVHEADEND_CONFIG_DIR/dobleM"
CARPETA_SCRIPT="$PWD"
LIST_ERROR=false
GRABBER_ERROR=false
SERVICE_ERROR=false

if [ -f "i_manuelin.log" ]; then
	mv "i_manuelin.log" "i_manuelin.old.log" 2>>i_manuelin.log
fi

if [ -z "$COLUMNS" ]; then
	COLUMNS=80
fi

# COPIA DE SEGURIDAD
backup()
{
	echo -e "$blue ############################################################################# $end"
	echo -e "$blue ###                     Iniciando copia de seguridad                      ### $end" 
	echo -e "$blue ############################################################################# $end"
	echo
# Paramos tvheadend para evitar conflictos al copiar y/o borrar archivos	
	printf "%-$(($COLUMNS-10))s"  " 1. Deteniendo Tvheadend"
		cd $CARPETA_SCRIPT
		PARAR_TVHEADEND
# Hacemos la copia de seguridad
	printf "%-$(($COLUMNS-10+1))s"  " 2. Realizando copia de seguridad de la configuración actual"	
	cd $TVHEADEND_CONFIG_DIR
	if [ -f "$CARPETA_SCRIPT/Backup_tvheadend_$(date +"%Y-%m-%d").tar.xz" ]; then
		FILE="Backup_tvheadend_$(date +"%Y-%m-%d_%H.%M.%S").tar.xz"
		tar -cjf $CARPETA_SCRIPT/$FILE bouquet channel epggrab input input picons 2>>dobleM.log
	else
		FILE="Backup_tvheadend_$(date +"%Y-%m-%d").tar.xz"
		tar -cjf $CARPETA_SCRIPT/$FILE bouquet channel epggrab input input picons 2>>dobleM.log
	fi
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
		printf "%s$blue%s$end\n" "   Backup creado: " "$FILE"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
	fi	
# Reiniciamos tvheadend
	printf "%-$(($COLUMNS-10))s"  " 3. Iniciando Tvheadend"
		cd $CARPETA_SCRIPT
		INICIAR_TVHEADEND	
# Fin copia de seguridad
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " Pulsa intro para continuar..."
	read CAD
}

# INSTALADOR SATELITE
install()
{
	echo -e "$blue ############################################################################# $end"
	echo -e "$blue ###        Iniciando instalación de canales satélite y EPG dobleM         ### $end" 
	echo -e "$blue ############################################################################# $end"
	echo
	if [ ! -f $TVHEADEND_CONFIG_DIR/epggrab/config ]; then
		printf "$red%s$end\n\n" "¡No continúes hasta hacer lo siguiente!:"
		printf "%s\n\t%s$blue%s$end%s$blue%s$end%s$blue%s$end\n\t%s\n" "Es necesario que entres en la interfaz web del Tvheadend y te dirijas al apartado:" "- " "Configuración"  " >> " "Canal / EPG" " >> " "Módulos para Obtención de Guía" "  (en inglés: Configuration >> Channel / EPG >> EPG Grabber Modules)"
		printf "\n%s\n" "Una vez estés situado aquí, haz lo siguiente:"
		printf "\t%s$green%s$end\n" "1- Selecciona el grabber que esté en " "\"Verde\""""
		printf "\t%s$blue%s$end\n\t%s\n" "2- En el menú lateral desmarca la casilla " "\"Habilitado\"" "  (en inglés \"Enabled\")"
		printf "\t%s$blue%s$end\n\t%s\n" "3- Finalmente, pulsa sobre el botón superior " "\"Guardar\"" "  (en inglés \"Save\")"
		printf "\n%s\n\n" "Repite esta operación con todos los grabber que estén habilitados"
		CONTINUAR="n"
		while [ "$CONTINUAR" != "s" ] && [ "$CONTINUAR" != "S" ] && [ "$CONTINUAR" != "" ]; do
			read -p "Una vez haya realizado este proceso ya puedes continuar. ¿Desea continuar? [S/n]" CONTINUAR
		done
		echo
	fi
# Paramos tvheadend para evitar conflictos al copiar y/o borrar archivos	
	printf "%-$(($COLUMNS-10))s"  " 1. Deteniendo Tvheadend"
		cd $CARPETA_SCRIPT
		PARAR_TVHEADEND		
# Preparamos CARPETA_DOBLEM y descargamos el fichero dobleM.tar.xz	
	printf "%-$(($COLUMNS-10+1))s"  " 2. Descargando lista de canales satélite"
	rm -rf $CARPETA_DOBLEM	
	mkdir $CARPETA_DOBLEM
	cd $CARPETA_DOBLEM
	wget -q https://raw.githubusercontent.com/davidmuma/Canales_dobleM/master/files/dobleM.tar.xz 2>>dobleM.log
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		echo -e "\nLa lista de canales satélite no se ha podido descargar.\nPor favor, inténtalo más tarde."
		exit 1
	fi
	# Descomprimimos el tar y marcamos con dobleM al final todos los archivos de la carpeta /channel/config/ y /channel/tag/
	tar -xf "dobleM.tar.xz"
		sed -i '/^\}$/,$d' $CARPETA_DOBLEM/channel/config/*
		sed -i '/^\}$/,$d' $CARPETA_DOBLEM/channel/tag/*
		sed -i "\$a}\n$NOMBRE_APP" $CARPETA_DOBLEM/channel/config/*
		sed -i "\$a}\n$NOMBRE_APP" $CARPETA_DOBLEM/channel/tag/*
# Borramos configuración actual menos "channel" y "epggrab" de tvheadend
	printf "%-$(($COLUMNS-10+1))s"  " 3. Eliminando instalación anterior"
	rm -rf $TVHEADEND_CONFIG_DIR/bouquet/ $TVHEADEND_CONFIG_DIR/input/dvb/networks/b59c72f4642de11bd4cda3c62fe080a8/ $TVHEADEND_CONFIG_DIR/picons/ 2>>dobleM.log
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi	
		# Borramos channels y tags marcados, conservando redes y canales mapeados por los usuarios
		rm -f 
			if [ "$1" != "ALL" ];then
				# Recorremos los ficheros de estas carpetas para borrar solo los que tengan la marca dobleM
				for fichero in $TVHEADEND_CONFIG_DIR/channel/config/* $TVHEADEND_CONFIG_DIR/channel/tag/*
				do 
					if [ -f "$fichero" ]; then  
						ultima=$(tail -n 1 $fichero)
						if [ "$ultima" = $NOMBRE_APP ]; then
						rm -f $fichero 
						fi
					fi
				done
			else
				# Borramos todos los canales y tags
				rm -rf $TVHEADEND_CONFIG_DIR/channel/
			fi		
# Empezamos a copiar los archivos necesarios
	printf "%-$(($COLUMNS-10))s"  " 4. Instalando lista de canales"
	ERROR=false
	cp -r $CARPETA_DOBLEM/dobleM.ver $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/bouquet/ $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/channel/ $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/input/ $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/picons/ $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi
# Damos permisos a los directorios
	printf "%-$(($COLUMNS-10+1))s" " 5. Aplicando permisos a los ficheros de configuración"
	ERROR=false
	chown -R $TVHEADEND_BOUQUET_USER:$TVHEADEND_BOUQUET_GROUP $TVHEADEND_CONFIG_DIR/bouquet 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/bouquet -type d -exec chmod $TVHEADEND_BOUQUET_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/bouquet -type f -exec chmod $(($TVHEADEND_BOUQUET_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi	
	chown -R $TVHEADEND_CHANNEL_USER:$TVHEADEND_CHANNEL_GROUP $TVHEADEND_CONFIG_DIR/channel 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/channel -type d -exec chmod $TVHEADEND_CHANNEL_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/channel -type f -exec chmod $(($TVHEADEND_CHANNEL_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chown -R $TVHEADEND_INPUT_USER:$TVHEADEND_INPUT_GROUP $TVHEADEND_CONFIG_DIR/input 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/input -type d -exec chmod $TVHEADEND_INPUT_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/input -type f -exec chmod $(($TVHEADEND_INPUT_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chown -R $TVHEADEND_PICONS_USER:$TVHEADEND_PICONS_GROUP $TVHEADEND_CONFIG_DIR/picons 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/picons -type d -exec chmod $TVHEADEND_PICONS_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/picons -type f -exec chmod $(($TVHEADEND_PICONS_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi	
# Instalación de grabber. Borramos carpeta epggrab y grabber viejo. Copiamos carpeta epggrab y grabber nuevo. Damos permisos.			
	printf "%-$(($COLUMNS-10))s"  " 6. Instalando grabber"
	if [ -f /usr/bin/tv_grab_EPG_dobleM -a $SYSTEM -eq 1 ]; then
		rm /usr/bin/tv_grab_EPG_dobleM 2>>dobleM.log
	fi
	ERROR=false
	rm $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	rm -rf $TVHEADEND_CONFIG_DIR/epggrab/xmltv 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/epggrab/ $TVHEADEND_CONFIG_DIR/ 2>>dobleM.log
	if [ $? -ne 0 -a $SYSTEM -ne 2 ]; then
		ERROR=true
	fi
	if [ $SYSTEM -ne 1 ]; then
		sed -i -- "s,\"modid\":.*,\"modid\": \"$TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM\"\,,g" $TVHEADEND_CONFIG_DIR/epggrab/xmltv/channels/* 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
	fi
	chown -R $TVHEADEND_EPGGRAB_USER:$TVHEADEND_EPGGRAB_GROUP $TVHEADEND_CONFIG_DIR/epggrab 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/epggrab -type d -exec chmod $TVHEADEND_EPGGRAB_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/epggrab -type f -exec chmod $(($TVHEADEND_EPGGRAB_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	if [ ! -d $TVHEADEND_GRABBER_DIR ]; then
		mkdir -p $TVHEADEND_GRABBER_DIR 2>>dobleM.log
	fi
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp $CARPETA_DOBLEM/grabber/tv_grab_EPG_dobleM $TVHEADEND_GRABBER_DIR/ 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chown $TVHEADEND_USER:$TVHEADEND_GROUP $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chmod $(($TVHEADEND_PERMISSIONS-100)) $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chmod +rx $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM 2>>dobleM.log
	if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		GRABBER_ERROR=true
	fi	
while :	
do
	echo "  6a. Escoge que tipo de imágenes quieres que aparezcan en la guía:"
	echo "   1) Posters"
	echo "   2) Fanarts"
	echo -n "   Indica una opción: "
	read opcion
	case $opcion in
			1) sed -i 's/enable_fanart=.*/enable_fanart=false/g' $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM; break;;
			2) sed -i 's/enable_fanart=.*/enable_fanart=true/g' $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM; break;;	
			*) echo "$opcion es una opción inválida";
	esac
done	
# Configuramos tvheadend
	printf "%-$(($COLUMNS-10))s"  " 7. Configurando tvheadend"
	ERROR=false
		#Idiomas EPG config tvheadend
		sed -i 's/"language": \[/"language": \[\ndobleM/g' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/dobleM/,/],/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"language": \[/"language": \[\n\t\t"spa",\n\t\t"eng",\n\t\t"ger",\n\t\t"fre"\n\t\],/g' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		#picons config tvheadend
		sed -i '/"chiconscheme": .*,/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/"piconpath": .*,/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/"piconscheme": .*,/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"prefer_picon": .*,/"prefer_picon": false,\n\t"chiconscheme": 2,\n\t"piconpath": "file:\/\/TVHEADEND_CONFIG_DIR\/picons",\n\t"piconscheme": 0,/g' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i "s,TVHEADEND_CONFIG_DIR,$TVHEADEND_CONFIG_DIR,g" $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		#cron y grabber config epggrab
		sed -i 's/"cron": .*,/"cron": "# Se ejecuta todos los días a las 8:10\\n10 8 * * *",/g' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"enabled": .*,/"enabled": false,/g' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/tv_grab_EPG_dobleM/,/},/d' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/tv_grab_EPG_dobleM-IPTV/,/},/d' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"modules": {/"modules": {\n\t\t"TVHEADEND_GRABBER_DIR\/tv_grab_EPG_dobleM": {\n\t\t\t"class": "epggrab_mod_int_xmltv",\n\t\t\t"dn_chnum": 0,\n\t\t\t"name": "XMLTV: EPG_dobleM - Movistar+",\n\t\t\t"type": "Internal",\n\t\t\t"enabled": true,\n\t\t\t"priority": 3\n\t\t},\n\t\t"TVHEADEND_GRABBER_DIR\/tv_grab_EPG_dobleM-IPTV": {\n\t\t\t"class": "epggrab_mod_int_xmltv",\n\t\t\t"dn_chnum": 0,\n\t\t\t"name": "XMLTV: EPG_dobleM - IPTV",\n\t\t\t"type": "Internal",\n\t\t\t"enabled": true,\n\t\t\t"priority": 3\n\t\t},/g' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i "s,TVHEADEND_GRABBER_DIR,$TVHEADEND_GRABBER_DIR,g" $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
		else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
			LIST_ERROR=true
		fi	
# Borramos carpeta termporal dobleM
	printf "%-$(($COLUMNS-10))s"  " 8. Eliminando archivos temporales"
		rm -rf $CARPETA_DOBLEM 2>>dobleM.log
		if [ $? -eq 0 ]; then
			printf "%s$green%s$end%s\n" "[" "  OK  " "]"
		else
			printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		fi
# Reiniciamos tvheadend
	printf "%-$(($COLUMNS-10))s"  " 9. Iniciando Tvheadend"
		cd $CARPETA_SCRIPT
		INICIAR_TVHEADEND
# Fin instalación
if [ "$LIST_ERROR" = true -o "$GRABBER_ERROR" = true ]; then
	printf "\n$red%s$end\n" " ERROR: El proceso no se ha completado correctamente."
	printf "$red%s$end\n" " Revisa los errores anteriores para intentar solucionarlo."
	echo
	echo " Pulsa intro para continuar..."
	read CAD
elif [ "$SERVICE_ERROR" = true ]; then
	printf "\n$red%s$end\n" " ERROR: Tvheadend no se ha podido reiniciar de forma automática."
	printf "$red%s$end\n" " Es necesario reiniciar Tvheadend manualmente para aplicar los cambios."
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " Acuerdate de asignar en cada sintonizador \"Red DVB-S\" en la pestaña:"
	echo "   Configuración --- Entradas DVB --- Adaptadores de TV"
	echo
	echo " La primera captura de EPG tardará unos minutos hasta que todos"
	echo " los procesos de tvheadend se terminen de iniciar, ten paciencia."
	echo
	echo " tvheadend ha quedado configurado de la siguiente manera:"
	echo "  Spanish - Guía con etiquetas de colores"
	echo "  English - Guía sin etiquetas de colores"
	echo "  German - Guía con etiquetas de colores, título en una sola linea"
	echo "  French - Guía sin etiquetas de colores, título en una sola linea y sin caracteres especiales"
	echo
	echo " Pulsa intro para continuar..."
	read CAD
else
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " Acuerdate de asignar en cada sintonizador \"Red DVB-S\" en la pestaña:"
	echo "   Configuración --- Entradas DVB --- Adaptadores de TV"
	echo
	echo " La primera captura de EPG tardará unos minutos hasta que todos"
	echo " los procesos de tvheadend se terminen de iniciar, ten paciencia."
	echo
	echo " tvheadend ha quedado configurado de la siguiente manera:"
	echo "  Spanish - Guía con etiquetas de colores"
	echo "  English - Guía sin etiquetas de colores"
	echo "  German - Guía con etiquetas de colores, título en una sola linea"
	echo "  French - Guía sin etiquetas de colores, título en una sola linea y sin caracteres especiales"
	echo
	echo " Pulsa intro para continuar..."
	read CAD
fi
}

# INSTALADOR IPTV
installIPTV()
{
	echo -e "$blue ############################################################################# $end"
	echo -e "$blue ###          Iniciando instalación de canales IPTV y EPG dobleM           ### $end" 
	echo -e "$blue ############################################################################# $end" 
	echo
	if [ ! -f $TVHEADEND_CONFIG_DIR/epggrab/config ]; then
		printf "$red%s$end\n\n" "¡No continúes hasta hacer lo siguiente!:"
		printf "%s\n\t%s$blue%s$end%s$blue%s$end%s$blue%s$end\n\t%s\n" "Es necesario que entres en la interfaz web del Tvheadend y te dirijas al apartado:" "- " "Configuración"  " >> " "Canal / EPG" " >> " "Módulos para Obtención de Guía" "  (en inglés: Configuration >> Channel / EPG >> EPG Grabber Modules)"
		printf "\n%s\n" "Una vez estés situado aquí, haz lo siguiente:"
		printf "\t%s$green%s$end\n" "1- Selecciona el grabber que esté en " "\"Verde\""""
		printf "\t%s$blue%s$end\n\t%s\n" "2- En el menú lateral desmarca la casilla " "\"Habilitado\"" "  (en inglés \"Enabled\")"
		printf "\t%s$blue%s$end\n\t%s\n" "3- Finalmente, pulsa sobre el botón superior " "\"Guardar\"" "  (en inglés \"Save\")"
		printf "\n%s\n\n" "Repite esta operación con todos los grabber que estén habilitados"
		CONTINUAR="n"
		while [ "$CONTINUAR" != "s" ] && [ "$CONTINUAR" != "S" ] && [ "$CONTINUAR" != "" ]; do
			read -p "Una vez haya realizado este proceso ya puedes continuar. ¿Desea continuar? [S/n]" CONTINUAR
		done
		echo
	fi
# Paramos tvheadend para evitar conflictos al copiar y/o borrar archivos	
	printf "%-$(($COLUMNS-10))s"  " 1. Deteniendo Tvheadend"
		cd $CARPETA_SCRIPT
		PARAR_TVHEADEND
# Preparamos CARPETA_DOBLEM y descargamos el fichero dobleM.tar.xz	
	printf "%-$(($COLUMNS-10))s"  " 2. Descargando lista de canales IPTV"
	rm -rf $CARPETA_DOBLEM	
	mkdir $CARPETA_DOBLEM
	cd $CARPETA_DOBLEM
	wget -q https://raw.githubusercontent.com/davidmuma/Canales_dobleM/master/files/dobleM-IPTV.tar.xz 2>>dobleM.log
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		echo -e "\nLa lista de canales IPTV no se ha podido descargar.\nPor favor, inténtalo más tarde."
		exit 1
	fi
	# Descomprimimos el tar y marcamos con dobleM al final todos los archivos de la carpeta /channel/config/ y /channel/tag/
	tar -xf "dobleM-IPTV.tar.xz"
		sed -i '/^\}$/,$d' $CARPETA_DOBLEM/channel/config/*
		sed -i '/^\}$/,$d' $CARPETA_DOBLEM/channel/tag/*
		sed -i "\$a}\n$NOMBRE_APP_IPTV" $CARPETA_DOBLEM/channel/config/*
		sed -i "\$a}\n$NOMBRE_APP_IPTV" $CARPETA_DOBLEM/channel/tag/*		
# Borramos configuración actual menos "channel" y "epggrab" de tvheadend
	printf "%-$(($COLUMNS-10+1))s"  " 3. Eliminando instalación anterior"
	rm -rf $TVHEADEND_CONFIG_DIR/input/iptv/networks/d040f9ac2f2bfe2df2af82722cf1a7b6/ 2>>dobleM.log
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi	
		# Borramos channels y tags marcados, conservando redes y canales mapeados por los usuarios
		rm -f 
			if [ "$1" != "ALL" ];then
				# Recorremos los ficheros de estas carpetas para borrar solo los que tengan la marca dobleM
				for fichero in $TVHEADEND_CONFIG_DIR/channel/config/* $TVHEADEND_CONFIG_DIR/channel/tag/*
				do 
					if [ -f "$fichero" ]; then  
						ultima=$(tail -n 1 $fichero)
						if [ "$ultima" = $NOMBRE_APP_IPTV ]; then
						rm -f $fichero 
						fi
					fi
				done
			else
				# Borramos todos los canales y tags
				rm -rf $TVHEADEND_CONFIG_DIR/channel/
			fi					
# Empezamos a copiar los archivos necesarios
	printf "%-$(($COLUMNS-10))s"  " 4. Instalando lista de canales"
	ERROR=false
	cp -r $CARPETA_DOBLEM/dobleM-IPTV.ver $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/channel/ $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp -r $CARPETA_DOBLEM/input/ $TVHEADEND_CONFIG_DIR 2>>dobleM.log
	if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi			
# Damos permisos a los directorios
	printf "%-$(($COLUMNS-10+1))s" " 5. Aplicando permisos a los ficheros de configuración"
	ERROR=false
	chown -R $TVHEADEND_CHANNEL_USER:$TVHEADEND_CHANNEL_GROUP $TVHEADEND_CONFIG_DIR/channel 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/channel -type d -exec chmod $TVHEADEND_CHANNEL_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/channel -type f -exec chmod $(($TVHEADEND_CHANNEL_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chown -R $TVHEADEND_INPUT_USER:$TVHEADEND_INPUT_GROUP $TVHEADEND_CONFIG_DIR/input 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/input -type d -exec chmod $TVHEADEND_INPUT_PERMISSIONS 2>>dobleM.log {} \;
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	find $TVHEADEND_CONFIG_DIR/input -type f -exec chmod $(($TVHEADEND_INPUT_PERMISSIONS-100)) 2>>dobleM.log {} \;
	if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi	
# Instalación de grabber. Borramos grabber viejo. Copiamos grabber nuevo. Damos permisos.			
	printf "%-$(($COLUMNS-10))s"  " 6. Instalando grabber"
	if [ -f /usr/bin/tv_grab_EPG_dobleM-IPTV -a $SYSTEM -eq 1 ]; then
		rm /usr/bin/tv_grab_EPG_dobleM-IPTV 2>>dobleM.log
	fi
	ERROR=false
	rm $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM-IPTV 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	cp $CARPETA_DOBLEM/grabber/tv_grab_EPG_dobleM-IPTV $TVHEADEND_GRABBER_DIR/ 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chown $TVHEADEND_USER:$TVHEADEND_GROUP $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM-IPTV 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chmod $(($TVHEADEND_PERMISSIONS-100)) $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM-IPTV 2>>dobleM.log
	if [ $? -ne 0 ]; then
		ERROR=true
	fi
	chmod +rx $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM-IPTV 2>>dobleM.log
	if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		GRABBER_ERROR=true
	fi
# Configuramos tvheadend
	printf "%-$(($COLUMNS-10))s"  " 7. Configurando tvheadend"
	ERROR=false
		#Idiomas EPG config tvheadend
		sed -i 's/"language": \[/"language": \[\ndobleM/g' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/dobleM/,/],/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"language": \[/"language": \[\n\t\t"spa",\n\t\t"eng",\n\t\t"ger",\n\t\t"fre"\n\t\],/g' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		#picons config tvheadend
		sed -i '/"chiconscheme": .*,/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/"piconpath": .*,/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/"piconscheme": .*,/d' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"prefer_picon": .*,/"prefer_picon": false,\n\t"chiconscheme": 2,\n\t"piconpath": "file:\/\/TVHEADEND_CONFIG_DIR\/picons",\n\t"piconscheme": 0,/g' $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i "s,TVHEADEND_CONFIG_DIR,$TVHEADEND_CONFIG_DIR,g" $TVHEADEND_CONFIG_DIR/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		#cron y grabber config epggrab
		sed -i 's/"cron": .*,/"cron": "# Se ejecuta todos los días a las 8:10\\n10 8 * * *",/g' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"enabled": .*,/"enabled": false,/g' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/tv_grab_EPG_dobleM/,/},/d' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i '/tv_grab_EPG_dobleM-IPTV/,/},/d' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i 's/"modules": {/"modules": {\n\t\t"TVHEADEND_GRABBER_DIR\/tv_grab_EPG_dobleM": {\n\t\t\t"class": "epggrab_mod_int_xmltv",\n\t\t\t"dn_chnum": 0,\n\t\t\t"name": "XMLTV: EPG_dobleM - Movistar+",\n\t\t\t"type": "Internal",\n\t\t\t"enabled": true,\n\t\t\t"priority": 3\n\t\t},\n\t\t"TVHEADEND_GRABBER_DIR\/tv_grab_EPG_dobleM-IPTV": {\n\t\t\t"class": "epggrab_mod_int_xmltv",\n\t\t\t"dn_chnum": 0,\n\t\t\t"name": "XMLTV: EPG_dobleM - IPTV",\n\t\t\t"type": "Internal",\n\t\t\t"enabled": true,\n\t\t\t"priority": 3\n\t\t},/g' $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -ne 0 ]; then
			ERROR=true
		fi
		sed -i "s,TVHEADEND_GRABBER_DIR,$TVHEADEND_GRABBER_DIR,g" $TVHEADEND_CONFIG_DIR/epggrab/config 2>>dobleM.log
		if [ $? -eq 0 -a $ERROR = "false" ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
		else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
			LIST_ERROR=true
		fi	
# Borramos carpeta termporal dobleM
	printf "%-$(($COLUMNS-10))s"  " 8. Eliminando archivos temporales"
		rm -rf $CARPETA_DOBLEM 2>>dobleM.log
		if [ $? -eq 0 ]; then
			printf "%s$green%s$end%s\n" "[" "  OK  " "]"
		else
			printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		fi
# Reiniciamos tvheadend
	printf "%-$(($COLUMNS-10))s"  " 9. Iniciando Tvheadend"
		cd $CARPETA_SCRIPT
		INICIAR_TVHEADEND
# Fin instalación
if [ "$LIST_ERROR" = true -o "$GRABBER_ERROR" = true ]; then
	printf "\n$red%s$end\n" " ERROR: El proceso no se ha completado correctamente."
	printf "$red%s$end\n" " Revisa los errores anteriores para intentar solucionarlo."
	echo
	echo " Pulsa intro para continuar..."
	read CAD
elif [ "$SERVICE_ERROR" = true ]; then
	printf "\n$red%s$end\n" " ERROR: Tvheadend no se ha podido reiniciar de forma automática."
	printf "$red%s$end\n" " Es necesario reiniciar Tvheadend manualmente para aplicar los cambios."
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " La primera captura de EPG tardará unos minutos hasta que todos"
	echo " los procesos de tvheadend se terminen de iniciar, ten paciencia."
	echo
	echo " Pulsa intro para continuar..."
	read CAD
else
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " La primera captura de EPG tardará unos minutos hasta que todos"
	echo " los procesos de tvheadend se terminen de iniciar, ten paciencia."
	echo
	echo " Pulsa intro para continuar..."
	read CAD
fi
}

# CAMBIAR IMAGENES GRABBER
imagenesgrabber()
{
	echo -e "$blue ############################################################################# $end"
	echo -e "$blue ###            Iniciando cambio de tipo de imágenes en grabber            ### $end" 
	echo -e "$blue ############################################################################# $end"
	echo
while :	
do
	echo -e " Escoge que tipo de imágenes quieres que aparezcan en la guía:"
	echo -e " 1) Posters"
	echo -e " 2) Fanarts"
	echo -n " Indica una opción: "
	read opcion
	case $opcion in
			1) sed -i 's/enable_fanart=.*/enable_fanart=false/g' $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM; break;;
			2) sed -i 's/enable_fanart=.*/enable_fanart=true/g' $TVHEADEND_GRABBER_DIR/tv_grab_EPG_dobleM; break;;	
			*) echo "$opcion es una opción inválida";
	esac
done
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " Pulsa intro para continuar..."
	read CAD
}

# LIMPIEZA TOTAL DE CANALES
limpiezatotal()
{
	echo -e "$blue ############################################################################# $end"
	echo -e "$blue ###                 Iniciando limpieza total de tvheadend                 ### $end" 
	echo -e "$blue ############################################################################# $end" 	
	echo
# Paramos tvheadend para evitar conflictos al copiar y/o borrar archivos	
	printf "%-$(($COLUMNS-10))s"  " 1. Deteniendo Tvheadend"
		cd $CARPETA_SCRIPT
		PARAR_TVHEADEND				
# Borramos carpeta "channel" de tvheadend
	printf "%-$(($COLUMNS-10+1))s"  " 2. Borrando toda la configuración de tvheadend"	
	cd $TVHEADEND_CONFIG_DIR
	rm -rf $TVHEADEND_CONFIG_DIR/bouquet/ $TVHEADEND_CONFIG_DIR/channel/ $TVHEADEND_CONFIG_DIR/epggrab/ $TVHEADEND_CONFIG_DIR/input/ $TVHEADEND_CONFIG_DIR/picons/ 2>>dobleM.log
	if [ $? -eq 0 ]; then
		printf "%s$green%s$end%s\n" "[" "  OK  " "]"
	else
		printf "%s$red%s$end%s\n" "[" "FAILED" "]"
		LIST_ERROR=true
	fi	
# Reiniciamos tvheadend
	printf "%-$(($COLUMNS-10))s"  " 3. Iniciando Tvheadend"
		cd $CARPETA_SCRIPT
		INICIAR_TVHEADEND		
# Fin limpieza
	printf "\n$green%s$end\n" " ¡Proceso completado!"
	echo
	echo " Pulsa intro para continuar..."
	read CAD
}

# MENU INSTALACION
while :	
do
clear
	echo -e "$blue ############################################################################# $end" 
	echo -e "$blue ###                           $green -= dobleM =- $end                             $blue ### $end" 
	echo -e "$blue ###                     Telegram: $cyan t.me/EPG_dobleM $end                      $blue ### $end"
	echo -e "$blue ### --------------------------------------------------------------------- ###$end"
	echo -e "$blue ###      $red¡ PRECAUCION! $end  $blue Comprueba que el sistema y los directorios      ### $end" 
	echo -e "$blue ###      de instalación sean correctos, en caso de duda no continues      ### $end" 
	echo -e "$blue ############################################################################# $end" 
	echo
	echo -e " Sistema seleccionado:$magenta $SISTEMA_ELEGIDO $end"
	echo
	echo -e " Sistema    detectado:$yellow $SYSTEM_INFO $end"
	echo -e " Directorio tvheadend:$yellow $TVHEADEND_CONFIG_DIR $end"
	echo -e " Directorio   grabber:$yellow $TVHEADEND_GRABBER_DIR $end"
	echo
	echo -e " Versión SATELITE instalada:$red $ver_local $end --->  Nueva versión:$green $ver_web $end"
	echo -e " Versión   IPTV   instalada:$red $ver_local_IPTV $end --->  Nueva versión:$green $ver_web_IPTV $end"
	echo _________________________________________________________________________________
	echo
	echo -e " 1)$green Hacer copia de seguridad de tvheadend $end"
	echo -e " 2)$cyan Instalar lista de canales$yellow SATELITE $end+ picons, grabber y configurar tvheadend $end"
	echo -e " 3)$cyan Instalar lista de canales$yellow IPTV $end+ picons, grabber y configurar tvheadend $end"
	echo -e " 4)$cyan Cambiar tipo de imágenes que aparecen en la guía $end"
	echo -e " 5)$cyan Hacer una limpieza$red TOTAL$end de$cyan tvheadend $end"
    echo -e " 6)$magenta Volver $end"
    echo -e " 7)$red Salir $end"
	echo
	echo -n " Indica una opción: "
	read opcion
	case $opcion in
		1) clear && backup;;
		2) clear && install;;
		3) clear && installIPTV;;
		4) clear && imagenesgrabber;;
		5) clear && limpiezatotal;;
		6) rm -rf $CARPETA_SCRIPT/i_dobleMi.sh && clear && sh $CARPETA_SCRIPT/i_dobleM.sh; break;;
		7) rm -rf $CARPETA_SCRIPT/i_*.sh; exit;;		
		*) echo "$opcion es una opción inválida\n";
	esac
done