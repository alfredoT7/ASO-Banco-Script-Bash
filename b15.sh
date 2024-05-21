#!/bin/bash

ARCHIVO_CLIENTES="usr.txt"
ARCHIVO_SALDOS="saldo.txt"
ARCHIVO_SERVICIOS="servicios.txt"
ARCHIVO_MOVIMIENTOS="movimientos.txt"
umbral_sorteo=1000  # Definir el umbral de cantidad de dinero para participar en el sorteo

menu_principal() {
    opcion=$(zenity --list --title="Menú Principal" --column="Opción" "Agregar Cliente" "Buscar Clientes" "Mostrar Lista de Clientes" "Lista de Movimientos Bancarios" "Realizar Sorteo" "Salir")

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
        "Lista de Movimientos Bancarios")
            lista_movimientos
            menu_principal
            ;;
        "Realizar Sorteo")
            realizar_sorteo
            menu_principal
            ;;
        *)
            exit 0
            ;;
    esac
}

agregar_cliente() {
    formulario=$(zenity --forms --title="Agregar Cliente" --text="Completa los datos del cliente" \
        --add-entry="Nombre del Cliente" \
        --add-entry="Correo Electrónico" \
        --add-password="Contraseña")

    nombre=$(echo "$formulario" | cut -d'|' -f1)
    correo=$(echo "$formulario" | cut -d'|' -f2)
    contrasena=$(echo "$formulario" | cut -d'|' -f3)

    if [ -n "$nombre" ] && [ -n "$correo" ] && [ -n "$contrasena" ]; then
        ultimo_numero=$(awk -F"|" 'END {print $1}' "$ARCHIVO_CLIENTES")
        nuevo_numero=$((ultimo_numero + 1))
        
        echo "$nuevo_numero|$nombre|$correo|$contrasena" >> "$ARCHIVO_CLIENTES"
        echo "$nuevo_numero|0|$(date +%Y-%m-%d)" >> "$ARCHIVO_SALDOS"
        
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
            numeros_clientes=$(awk -F"|" '{print $1}' <<< "$resultado")
            clientes=$(grep -F -f <(echo "$numeros_clientes") "$ARCHIVO_CLIENTES")
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
    numero_cliente=$(zenity --entry --title="Ver Saldo" --text="Ingrese el número de cliente:")
    if [ -n "$numero_cliente" ]; then
        if grep -q "^$numero_cliente|" "$ARCHIVO_CLIENTES"; then
            saldo=$(grep "^$numero_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
            zenity --info --title="Saldo del Cliente" --text="El saldo del cliente con número de cliente $numero_cliente es: $saldo"
        else
            zenity --info --title="Error" --text="El número de cliente $numero_cliente no fue encontrado."
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
                    saldo_destinatario=$(grep "^$destinatario|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                    if [ "$saldo_remitente" -ge "$cantidad" ]; then
                        nuevo_saldo_remitente=$((saldo_remitente - cantidad))
                        nuevo_saldo_destinatario=$((saldo_destinatario + cantidad))
                        sed -i "s/^$remitente|.*$/$remitente|$nuevo_saldo_remitente|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                        sed -i "s/^$destinatario|.*$/$destinatario|$nuevo_saldo_destinatario|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                        
                        echo "$remitente|Transacción|$cantidad|$(date +%Y-%m-%d)" >> "$ARCHIVO_MOVIMIENTOS"
                        echo "$destinatario|Transacción|$cantidad|$(date +%Y-%m-%d)" >> "$ARCHIVO_MOVIMIENTOS"
                        
                        zenity --info --title="Transacción Realizada" --text="Transacción de $cantidad realizada correctamente de $remitente a $destinatario."
                    else
                        zenity --info --title="Error" --text="El cliente remitente con número de cliente $remitente no tiene saldo suficiente para realizar la transacción."
                    fi
                else
                    zenity --info --title="Error" --text="El número de cliente remitente o destinatario no fue encontrado."
                fi
            fi
        fi
    fi
    menu_principal
}

pagar_servicio() {
    numero_cliente=$(zenity --entry --title="Pagar Servicio" --text="Ingrese el número de cliente:")
    if [ -n "$numero_cliente" ]; then
        if grep -q "^$numero_cliente|" "$ARCHIVO_CLIENTES"; then
            servicio=$(zenity --list --title="Seleccionar Servicio" --column="Servicio" $(cut -d"|" -f1 "$ARCHIVO_SERVICIOS"))
            if [ -n "$servicio" ]; then
                precio_servicio=$(grep "^$servicio|" "$ARCHIVO_SERVICIOS" | cut -d"|" -f2)
                saldo_actual=$(grep "^$numero_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                if [ "$saldo_actual" -ge "$precio_servicio" ]; then
                    nuevo_saldo=$((saldo_actual - precio_servicio))
                    sed -i "s/^$numero_cliente|.*$/$numero_cliente|$nuevo_saldo|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                    echo "$numero_cliente|Pago de Servicio|$precio_servicio|$(date +%Y-%m-%d)|$servicio" >> "$ARCHIVO_MOVIMIENTOS"
                    zenity --info --title="Pago Realizado" --text="El pago del servicio '$servicio' por $precio_servicio ha sido realizado correctamente para el cliente con número de cliente $numero_cliente."
                else
                    zenity --info --title="Error" --text="El cliente con número de cliente $numero_cliente no tiene saldo suficiente para realizar el pago del servicio."
                fi
            fi
        else
            zenity --info --title="Error" --text="El número de cliente $numero_cliente no fue encontrado."
        fi
    fi
    menu_principal
}

lista_movimientos() {
    numero_cliente=$(zenity --entry --title="Lista de Movimientos Bancarios" --text="Ingrese el número de cliente:")
    if [ -n "$numero_cliente" ]; then
        if grep -q "^$numero_cliente|" "$ARCHIVO_CLIENTES"; then
            movimientos=$(grep "^$numero_cliente|" "$ARCHIVO_MOVIMIENTOS")
            if [ -n "$movimientos" ]; then
                zenity --info --title="Movimientos Bancarios" --text="Movimientos bancarios del cliente con número de cliente $numero_cliente:\n$movimientos"
                
                cliente_info=$(grep "^$numero_cliente|" "$ARCHIVO_CLIENTES")
                correo_cliente=$(echo "$cliente_info" | cut -d"|" -f3)
                contrasena_cliente=$(echo "$cliente_info" | cut -d"|" -f4)
                
                echo "$movimientos" > "movimientos_$numero_cliente.txt"
                zip -P "$contrasena_cliente" "movimientos_$numero_cliente.zip" "movimientos_$numero_cliente.txt"
                
                echo "Adjunto encontrará el archivo con los movimientos bancarios." | ssmtp "$correo_cliente" -s "Movimientos Bancarios" -a "movimientos_$numero_cliente.zip"
                
                rm "movimientos_$numero_cliente.txt" "movimientos_$numero_cliente.zip"
                
                zenity --info --title="Correo Enviado" --text="La lista de movimientos bancarios ha sido enviada al correo del cliente."
            else
                zenity --info --title="Movimientos Bancarios" --text="No se encontraron movimientos bancarios para el cliente con número de cliente $numero_cliente."
            fi
        else
            zenity --info --title="Error" --text="El número de cliente $numero_cliente no fue encontrado."
        fi
    fi
    menu_principal
}

seleccionar_accion() {
    accion=$(zenity --list --title="Seleccionar Acción" --column="Opción" "Depósito" "Retiro" "Ver Saldo" "Realizar Transacción" "Pagar Servicio" "Cancelar")

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
        "Pagar Servicio")
            pagar_servicio
            ;;
        *)
            menu_principal
            ;;
    esac
}

deposito() {
    numero_cliente=$(zenity --entry --title="Depósito" --text="Ingrese el número de cliente:")
    if [ -n "$numero_cliente" ]; then
        cantidad=$(zenity --entry --title="Depósito" --text="Ingrese la cantidad a depositar:")
        if [ -n "$cantidad" ]; then
            if grep -q "^$numero_cliente|" "$ARCHIVO_CLIENTES"; then
                saldo_actual=$(grep "^$numero_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                nuevo_saldo=$((saldo_actual + cantidad))
                sed -i "s/^$numero_cliente|.*$/$numero_cliente|$nuevo_saldo|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                echo "$numero_cliente|Depósito|$cantidad|$(date +%Y-%m-%d)" >> "$ARCHIVO_MOVIMIENTOS"
                zenity --info --title="Depósito Realizado" --text="Depósito de $cantidad realizado correctamente para el cliente con número de cliente $numero_cliente."
            else
                zenity --info --title="Error" --text="El número de cliente $numero_cliente no fue encontrado."
            fi
        fi
    fi
    menu_principal
}

retiro() {
    numero_cliente=$(zenity --entry --title="Retiro" --text="Ingrese el número de cliente:")
    if [ -n "$numero_cliente" ]; then
        cantidad=$(zenity --entry --title="Retiro" --text="Ingrese la cantidad a retirar:")
        if [ -n "$cantidad" ]; then
            if grep -q "^$numero_cliente|" "$ARCHIVO_CLIENTES"; then
                saldo_actual=$(grep "^$numero_cliente|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
                if [ "$saldo_actual" -ge "$cantidad" ]; then
                    nuevo_saldo=$((saldo_actual - cantidad))
                    sed -i "s/^$numero_cliente|.*$/$numero_cliente|$nuevo_saldo|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
                    echo "$numero_cliente|Retiro|$cantidad|$(date +%Y-%m-%d)" >> "$ARCHIVO_MOVIMIENTOS"
                    zenity --info --title="Retiro Realizado" --text="Retiro de $cantidad realizado correctamente para el cliente con número de cliente $numero_cliente."
                else
                    zenity --info --title="Error" --text="El cliente con número de cliente $numero_cliente no tiene saldo suficiente para realizar el retiro."
                fi
            else
                zenity --info --title="Error" --text="El número de cliente $numero_cliente no fue encontrado."
            fi
        fi
    fi
    menu_principal
}
realizar_sorteo() {
    clientes_participantes=$(awk -F"|" -v umbral="$umbral_sorteo" '$2 >= umbral' "$ARCHIVO_SALDOS" | cut -d"|" -f1)
    cantidad_participantes=$(echo "$clientes_participantes" | wc -l)

    if [ "$cantidad_participantes" -gt 0 ]; then
        ganador=$(shuf -n 1 <<< "$clientes_participantes")
        saldo_actual=$(grep "^$ganador|" "$ARCHIVO_SALDOS" | cut -d"|" -f2)
        nuevo_saldo=$((saldo_actual + monto_sorteo))
        sed -i "s/^$ganador|.*$/$ganador|$nuevo_saldo|$(date +%Y-%m-%d)/" "$ARCHIVO_SALDOS"
        enviar_correo_ganador "$ganador" "$monto_sorteo" "$nuevo_saldo"
        zenity --info --title="Sorteo Realizado" --text="El cliente $ganador ha ganado $monto_sorteo. Se le ha enviado un correo electrónico con los detalles del premio."
    else
        zenity --info --title="Sorteo Realizado" --text="No hay clientes elegibles para el sorteo en este momento."
    fi
}
enviar_correo_ganador() {
    cliente="$1"
    monto="$2"
    nuevo_saldo="$3"
    correo_cliente=$(grep "^$cliente|" "$ARCHIVO_CLIENTES" | cut -d"|" -f3)
    
    echo "¡Felicidades!\n\nHas ganado un premio de $monto. Tu nuevo saldo es $nuevo_saldo." | mail -s "¡Felicidades! Has Ganado" "$correo_cliente"
}

menu_principal