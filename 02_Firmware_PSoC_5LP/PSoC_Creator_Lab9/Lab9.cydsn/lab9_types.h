/* Tipos compartidos por adquisicion, control, seguridad y telemetria. */
#ifndef LAB9_TYPES_H
#define LAB9_TYPES_H

#include "project.h"

/* Registro de una iteracion de control. Los valores flotantes se almacenan
 * en unidades SI y solo se convierten a mV al transmitirlos por UART. */
typedef struct {
    float adc_V;
    float y_V;
    float y_rel_V;          /* Salida referida al cero estimado en pretrigger. */
    float referencia_V;
    float u_solicitada_V;
    float u_dac_nominal_V;  /* Mando realmente representado por ambos DAC. */
    float xhat1_V;
    float xhat2_V;
    float xi_V;
    float innovacion_V;
    int16 adc_cuentas;
    uint16 intervalo_us;    /* Tiempo entre inicios consecutivos de la ISR. */
    uint16 cpu_us;          /* Tiempo de ejecucion de la ISR actual. */
    uint8 dac_pos;
    uint8 dac_neg;
    uint8 banderas;
} lab9_muestra_t;

/* Mapa de bits de diagnostico. Los seis bits de LAB9_F_FATALES fuerzan
 * inmediatamente la salida a cero; saturacion y anti-windup son eventos
 * informativos que permiten evaluar el desempeno sin abortar el ensayo. */
#define LAB9_F_ADC             (1u)
#define LAB9_F_DAC_FISICO      (2u)
#define LAB9_F_NUM             (4u)
#define LAB9_F_CPU             (8u)
#define LAB9_F_TIEMPO         (16u)
#define LAB9_F_Y              (32u)
#define LAB9_F_SAT_CONTROL    (64u)
#define LAB9_F_ANTIWINDUP    (128u)
#define LAB9_F_FATALES (LAB9_F_ADC|LAB9_F_DAC_FISICO|LAB9_F_NUM| \
                        LAB9_F_CPU|LAB9_F_TIEMPO|LAB9_F_Y)

#endif
