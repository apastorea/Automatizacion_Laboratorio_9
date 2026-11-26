/* Operaciones de adquisicion y actuacion usadas por el lazo de control. */
#ifndef LAB9_HARDWARE_H
#define LAB9_HARDWARE_H

#include "project.h"

/* Inicializa ADC, DAC y amplificadores manteniendo la salida bipolar en cero. */
void lab9_hardware_inicializar(void);

/* Devuelve la salida de planta calibrada y, por referencia, la lectura cruda
 * y la tension presente en el pin ADC para conservar trazabilidad. */
float lab9_hardware_leer_planta(int16 *cuentas, float *adc_V);

/* Convierte el mando en codigos de las ramas positiva y negativa. El retorno
 * es la tension nominal reconstruida despues de la cuantizacion. */
float lab9_hardware_escribir_salida(float solicitada_V, uint8 *dac_pos,
                                    uint8 *dac_neg, uint8 *saturada);

/* Barrera independiente que desactiva simultaneamente las dos ramas DAC. */
void lab9_hardware_salida_cero(void);

/* Saturador reutilizado por la HAL y por la conversion de telemetria. */
float lab9_limitar_hardware(float valor, float inferior, float superior);

#endif
