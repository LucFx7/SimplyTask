#!/bin/bash

# Archivo donde se guardan las tareas
TASKS_FILE="tasks.json"

# Verificar si el archivo de tareas existe
if [ ! -f "$TASKS_FILE" ]; then
    echo "[]" > "$TASKS_FILE" # Crear un archivo vacío si no existe
fi

# Función para obtener el próximo ID disponible
function get_next_id() {
    if [ ! -s "$TASKS_FILE" ] || [ "$(jq length "$TASKS_FILE")" -eq 0 ]; then
        echo 1
    else
        jq 'map(.id | tonumber) | max + 1' "$TASKS_FILE"
    fi
}

# Función para mostrar todas las tareas
function show_tasks() {
    cat "$TASKS_FILE" | jq '.'
}

# Función para agregar una tarea
function add_task() {
    echo "Título de la tarea:"
    read title
    echo "Descripción de la tarea:"
    read description
    echo "Fecha de vencimiento (YYYY-MM-DD):"
    read date

    # Preguntar prioridad y mapear abreviaturas
    echo "Prioridad (high, medium, low):"
    read priority_input
    case "$priority_input" in
        h|H) priority="high" ;;
        m|M) priority="medium" ;;
        l|L) priority="low" ;;
        high|medium|low) priority="$priority_input" ;;
        *) echo "Prioridad no válida, usando 'low' por defecto"; priority="low" ;;
    esac

    # Preguntar categoría y mapear abreviaturas
    echo "Categoría (work, personal, shopping):"
    read category_input
    case "$category_input" in
        w|W) category="work" ;;
        p|P) category="personal" ;;
        s|S) category="shopping" ;;
        work|personal|shopping) category="$category_input" ;;
        *) echo "Categoría no válida, usando 'personal' por defecto"; category="personal" ;;
    esac

    id=$(get_next_id)

    new_task=$(jq -n \
        --arg id "$id" \
        --arg title "$title" \
        --arg description "$description" \
        --arg date "$date" \
        --arg priority "$priority" \
        --arg category "$category" \
        '{id: ($id | tonumber), title: $title, description: $description, date: $date, priority: $priority, category: $category, completed: false}')
    
    jq ". += [$new_task]" "$TASKS_FILE" > tmp.json && mv tmp.json "$TASKS_FILE"
}


# Función para eliminar una tarea
function delete_task() {
    echo "Ingrese el ID de la tarea a eliminar:"
    read task_id

    jq "del(.[] | select(.id == $task_id))" "$TASKS_FILE" > tmp.json && mv tmp.json "$TASKS_FILE"
}

# Función para marcar tarea como completada
function mark_completed() {
    echo "Ingrese el ID de la tarea a marcar como completada:"
    read task_id

    jq "map(if .id == $task_id then . + {completed: true} else . end)" "$TASKS_FILE" > tmp.json && mv tmp.json "$TASKS_FILE"
}

# Función para mostrar tareas filtradas por categoría
function filter_by_category() {
    echo "Ingrese la categoría para filtrar (work/personal/shopping):"
    read category
    jq ".[] | select(.category == \"$category\")" "$TASKS_FILE"
}

# Función para contar tareas por estado
function count_tasks() {
    total_tasks=$(jq length "$TASKS_FILE")
    completed_tasks=$(jq '[.[] | select(.completed == true)] | length' "$TASKS_FILE")
    echo "Total de tareas: $total_tasks"
    echo "Tareas completadas: $completed_tasks"
}
# Función de ayuda
function show_help() {
    echo ""
    echo "===== AYUDA - SIMPLY TASK ====="
    echo "Opciones disponibles:"
    echo "1. Ver todas las tareas                -> Muestra todas las tareas registradas"
    echo "2. Agregar tarea                       -> Permite agregar una nueva tarea"
    echo "3. Eliminar tarea                      -> Elimina una tarea por su ID"
    echo "4. Marcar tarea como completada       -> Cambia el estado de una tarea a completada"
    echo "5. Filtrar tareas por categoría       -> Muestra tareas de una categoría específica"
    echo "6. Contar tareas                      -> Muestra el total y completadas"
    echo "7. Salir                              -> Cierra el gestor"
    echo ""
    echo "También puedes ejecutar:"
    echo "./task.sh --help  o  ./task.sh -h    -> Muestra esta ayuda"
    echo ""
}
# Mostrar ayuda si se pasa --help o -h
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi



# Menú de opciones
while true; do
    echo ""
    echo "===== SIMPLY TASK ====="
	echo "1. Ver todas las tareas"
	echo "2. Agregar tarea"
	echo "3. Eliminar tarea"
	echo "4. Marcar tarea como completada"
	echo "5. Filtrar tareas por categoría"
	echo "6. Contar tareas"
	echo "7. Mostrar ayuda"
	echo "8. Salir"

    echo "Seleccione una opción:"
    read option

    case $option in
    1) show_tasks ;;
    2) add_task ;;
    3) delete_task ;;
    4) mark_completed ;;
    5) filter_by_category ;;
    6) count_tasks ;;
    7) show_help ;;     # Nueva opción
    8) exit ;;
    *) echo "Opción no válida" ;;
esac

done
