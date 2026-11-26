/* Interfaz de exportacion UART de las muestras almacenadas en memoria. */
#ifndef LAB9_TELEMETRIA_H
#define LAB9_TELEMETRIA_H

#include "lab9_types.h"

/* Transmite metadatos y muestras como CSV al terminar el ensayo. No debe
 * llamarse dentro de la ISR porque el UART introduciria jitter de muestreo. */
void lab9_volcar_uart(lab9_muestra_t *memoria, uint16 cantidad);

#endif
