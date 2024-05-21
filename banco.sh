#!/bin/bash

# Función para agregar un nuevo cliente
add_client() {
    name=$(zenity --entry --title="Agregar Cliente" --text="Nombre del Cliente:")
    if [ -n "$name" ]; then
        echo "$name" >> usr.txt
        zenity --info --title="Cliente Agregado" --text="El cliente $name ha sido agregado correctamente."
    fi
}

# Función para mostrar la lista de clientes
show_clients() {
    if [ -f "usr.txt" ]; then
        clients=$(cat usr.txt)
        zenity --text-info --title="Lista de Clientes" --width=400 --height=300 --editable --text="$clients"
    else
        zenity --info --title="Lista de Clientes" --text="No hay clientes registrados."
    fi
}

# Menú principal
main_menu() {
    choice=$(zenity --list --title="Menú Principal" --column="Opción" "Agregar Cliente" "Ver Clientes" "Salir")

    case $choice in
        "Agregar Cliente")
            add_client
            main_menu
            ;;
        "Ver Clientes")
            show_clients
            main_menu
            ;;
        *)
            exit 0
            ;;
    esac
}

# Ejecutar el menú principal
main_menu

