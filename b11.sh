#!/bin/bash

ARCHIVO_CLIENTES="usr.txt"
ARCHIVO_SALDOS="saldo.txt"

menu_principal() {
    opcion=$(zenity --list --title="Menú Principal" --column="Opción" "Agregar Cliente" "Buscar Clientes" "Mostrar Lista de Clientes" "Salir")

    case $opcion in
        "Agregar Cliente")
            agregar_cliente
            menu_principal
            ;;
        "Buscar Clientes")
            buscar_clientes
            menu_principal
            ;;
        "Mostrar Lista de Clientes")
            mostrar_lista_clientes
            menu_principal
            ;;
        *)
            exit 0
            ;;
    esac
}

agregar_cliente() {
    nombre=$(zenity --entry --title="Agregar Cliente" --text="Nombre del Cliente:")
    if [ -n "$nombre" ]; then
        # Obtiene la última clave primaria y la incrementa en uno
        ultima_clave=$(awk -F"|" 'END {print $1}' "$ARCHIVO_CLIENTES")
        nueva_clave=$((ultima_clave + 1))
        
        # Agrega el nuevo cliente al archivo usr.txt
        echo "$nueva_clave|$nombre" >> "$ARCHIVO_CLIENTES"
        
        # Agrega el saldo inicial y la fecha actual del nuevo cliente al archivo saldo.txt
        echo "$nueva_clave|0|$(date +%Y-%m-%d)" >> "$ARCHIVO_SALDOS"
        
        zenity --info --title="Cliente Agregado" --text="El cliente $nombre ha sido agregado correctamente."
    fi
}

buscar_clientes() {
    tipo_busqueda=$(zenity --list --title="Buscar Clientes" --column="Opción" "Nombre o Apellido" "Saldo" "Fechas" "Cancelar")
    
    case $tipo_busqueda in
        "Nombre o Apellido")
            buscar_nombre
            ;;
        "Saldo")
            buscar_saldo
            ;;
        "Fechas")
            buscar_fechas
            ;;
        *)
            menu_principal
            ;;
    esac
}

buscar_nombre() {
    palabra_clave=$(zenity --entry --title="Buscar por Nombre o Apellido" --text="Introduce el nombre o apellido:")
    if [ -n "$palabra_clave" ]; then
        resultado=$(grep -i "$palabra_clave" "$ARCHIVO_CLIENTES")
        if [ -n "$resultado" ]; then
            zenity --info --title="Resultado de la Búsqueda" --text="Clientes encontrados:\n$resultado"
            seleccionar_accion
        else
            zenity --info --title="Resultado de la Búsqueda" --text="No se encontraron clientes con el nombre o apellido '$palabra_clave'."
        fi
    fi
}

buscar_saldo() {
    rango_saldo=$(zenity --forms --title="Buscar por Saldo" --text="Introduce el rango de saldo:" \
        --add-entry="Saldo mínimo:" \
        --add-entry="Saldo máximo:")

    saldo_minimo=$(echo "$rango_saldo" | cut -d'|' -f1)
    saldo_maximo=$(echo "$rango_saldo" | cut -d'|' -f2)

    if [[ -n "$saldo_minimo" && -n "$saldo_maximo" ]]; then
        resultado=$(awk -F"|" -v min="$saldo_minimo" -v max="$saldo_maximo" '$2 >= min && $2 <= max' "$ARCHIVO_SALDOS")
        if [ -n "$resultado" ]; then
            claves_clientes=$(awk -F"|" '{print $1}' <<< "$resultado")
            clientes=$(grep -F -f <(echo "$claves_clientes") "$ARCHIVO_CLIENTES")
            zenity --info --title="Resultado de la Búsqueda" --text="Clientes encontrados con saldo entre $saldo_minimo y $saldo_maximo:\n$clientes"
            seleccionar_accion
        else
            zenity --info --title="Resultado de la Búsqueda" --text="No se encontraron clientes con saldo entre $saldo_minimo y $saldo_maximo."
        fi
    fi
}

buscar_fechas() {
    fecha_elegida=$(zenity --calendar --title="Buscar por Fechas" --text="Selecciona una fecha:" --date-format="%Y-%m-%d")
    if [ -n "$fecha_elegida" ]; then
        resultado=$(grep "$fecha_elegida" "$ARCHIVO_SALDOS" | cut -d"|" -f1)
        if [ -n "$resultado" ]; then
            clientes=$(grep -F -f <(echo "$resultado") "$ARCHIVO_CLIENTES")
            zenity --info --title="Resultado de la Búsqueda" --text="Clientes con transacciones en la fecha $fecha_elegida:\n$clientes"
            seleccionar_accion
        else
            zenity --info --title="Resultado de la Búsqueda" --text="No se encontraron clientes con transacciones en la fecha $fecha_elegida."
        fi
    fi
}

mostrar_lista_clientes() {
    lista_clientes=$(cat "$ARCHIVO_CLIENTES")
    zenity --info --title="Lista de Clientes" --text="Clientes Registrados:\n$lista_clientes"
}

ver_saldo() {
    clave_cliente=$(zenity --entry --title="Ver Saldo" --text="Ingrese la clave primaria del cliente:")
    if [ -n "$clave_cliente" ]; then
        if grep -q "^$clave_cliente|" "$ARCHIVO_CLIENTES"; then
            saldo=$(grep "^$clave_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
            zenity --info --title="Saldo del Cliente" --text="El saldo del cliente con numero cliente $clave_cliente es: $saldo"
        else
            zenity --info --title="Error" --text="El numero de cliente $clave_cliente no fue encontrado."
        fi
    fi
    menu_principal
}

transaccion() {
    remitente=$(zenity --entry --title="Realizar Transacción" --text="Ingrese el número del cliente remitente:")
    if [ -n "$remitente" ]; then
        destinatario=$(zenity --entry --title="Realizar Transacción" --text="Ingrese el número del cliente destinatario:")
        if [ -n "$destinatario" ]; then
            cantidad=$(zenity --entry --title="Realizar Transacción" --text="Ingrese la cantidad a transferir:")
            if [ -n "$cantidad" ]; then
                if grep -q "^$remitente|" "$ARCHIVO_CLIENTES" && grep -q "^$destinatario|" "$ARCHIVO_CLIENTES"; then
                    saldo_remitente=$(grep "^$remitente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                    if [ "$saldo_remitente" -ge "$cantidad" ]; then
                        nuevo_saldo_remitente=$((saldo_remitente - cantidad))
                        nuevo_saldo_destinatario=$((saldo_destinatario + cantidad))
                        sed -i "s/^$remitente|.*$/$remitente|$nuevo_saldo_remitente|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                        sed -i "s/^$destinatario|.*$/$destinatario|$nuevo_saldo_destinatario|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                        zenity --info --title="Transacción Realizada" --text="Transacción de $cantidad realizada correctamente de $remitente a $destinatario."
                    else
                        zenity --info --title="Error" --text="El cliente remitente no tiene saldo suficiente para realizar la transacción."
                    fi
                else
                    zenity --info --title="Error" --text="Uno o ambos números de cliente no fueron encontrados."
                fi
            fi
        fi
    fi
    menu_principal
}

seleccionar_accion() {
    accion=$(zenity --list --title="Seleccionar Acción" --column="Opción" "Depósito" "Retiro" "Ver Saldo" "Realizar Transacción" "Cancelar")

    case $accion in
        "Depósito")
            deposito
            ;;
        "Retiro")
            retiro
            ;;
        "Ver Saldo")
            ver_saldo
            ;;
        "Realizar Transacción")
            transaccion
            ;;
        *)
            menu_principal
            ;;
    esac
}

deposito() {
    clave_cliente=$(zenity --entry --title="Depósito" --text="Ingrese el numero del cliente:")
    if [ -n "$clave_cliente" ]; then
        cantidad=$(zenity --entry --title="Depósito" --text="Ingrese la cantidad a depositar:")
        if [ -n "$cantidad" ]; then
            if grep -q "^$clave_cliente|" "$ARCHIVO_CLIENTES"; then
                saldo_actual=$(grep "^$clave_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                nuevo_saldo=$((saldo_actual + cantidad))
                sed -i "s/^$clave_cliente|.*$/$clave_cliente|$nuevo_saldo|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                zenity --info --title="Depósito Realizado" --text="Depósito de $cantidad realizado correctamente para el cliente con numero de cliente $clave_cliente."
            else
                zenity --info --title="Error" --text="El numero de cliente $clave_cliente no fue encontrado."
            fi
        fi
    fi
    menu_principal
}

retiro() {
    clave_cliente=$(zenity --entry --title="Retiro" --text="Ingrese el numero del cliente:")
    if [ -n "$clave_cliente" ]; then
        cantidad=$(zenity --entry --title="Retiro" --text="Ingrese la cantidad a retirar:")
        if [ -n "$cantidad" ]; then
            if grep -q "^$clave_cliente|" "$ARCHIVO_CLIENTES"; then
                saldo_actual=$(grep "^$clave_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                if [ "$saldo_actual" -ge "$cantidad" ]; then
                    nuevo_saldo=$((saldo_actual - cantidad))
                    sed -i "s/^$clave_cliente|.*$/$clave_cliente|$nuevo_saldo|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                    zenity --info --title="Retiro Realizado" --text="Retiro de $cantidad realizado correctamente para el cliente con numero de cliente $clave_cliente."
                else
                    zenity --info --title="Error" --text="El cliente con numero de cliente $clave_cliente no tiene saldo suficiente para realizar el retiro."
                fi
            else
                zenity --info --title="Error" --text="El numero de cliente $clave_cliente no fue encontrado."
            fi
        fi
    fi
    menu_principal
}

menu_principal

