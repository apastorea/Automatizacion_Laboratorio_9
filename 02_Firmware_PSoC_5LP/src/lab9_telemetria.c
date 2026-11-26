/*
 * Salida de datos del ensayo por UART.
 *
 * La transmision se realiza fuera de la interrupcion para no alterar el
 * periodo de muestreo. Cada captura incluye metadatos, variables del lazo y
 * banderas de diagnostico suficientes para comprobar su procedencia.
 */
#include "lab9_telemetria.h"
#include "lab9_config.h"
#include "lab9_hardware.h"
#include "lab9_version.h"
#include <float.h>
#include <stdio.h>

static uint8 lab9_es_finito_telemetria(float valor)
{
    return (uint8)(valor <= FLT_MAX && valor >= -FLT_MAX);
}

static int32 lab9_convertir_mV(float valor)
{
    /* La trama evita conversiones flotantes de printf: limita, escala a mV
     * y redondea de forma simetrica antes de imprimir como entero. */
    float mV;
    if (!lab9_es_finito_telemetria(valor)) return 0;
    mV = lab9_limitar_hardware(1000.0f*valor, -100000.0f, 100000.0f);
    return (int32)(mV+((mV >= 0.0f) ? 0.5f : -0.5f));
}

void lab9_volcar_uart(lab9_muestra_t *memoria, uint16 cantidad)
{
    char linea[320];
    uint16 k;
    uint32 t_us = 0u;

    /* Metadatos suficientes para vincular cada captura con la version del
     * firmware, modelo, estimador, modo y caso ensayado. */
    UART_Debug_PutString("# LAB9 version=" LAB9_VERSION_TEXTO
        " modelo=" LAB9_MODELO_TEXTO " estimador=" LAB9_ESTIMADOR_TEXTO
        " Ts_nominal_us=2000 modo=");
#if LAB9_MODO == LAB9_MODO_MONITOR
    UART_Debug_PutString("MONITOR");
#elif LAB9_MODO == LAB9_MODO_LAZO_ABIERTO
    UART_Debug_PutString("ABIERTO");
#else
    UART_Debug_PutString("LQR");
#endif
    (void)snprintf(linea, sizeof linea,
        " caso=%u referencia_mV=50 DAC_cuantizado=SI antiwindup=CONDICIONAL\r\n",
        (unsigned)LAB9_CASO);
    UART_Debug_PutString(linea);
    (void)snprintf(linea, sizeof linea,
        "# LAB9 escalon_abierto_mV=%d inicio_k=%u fin_k=%u duracion_ms=%lu\r\n",
        (int)LAB9_ESCALON_ABIERTO_MV, (unsigned)LAB9_PRETRIGGER,
        (unsigned)LAB9_FIN_ESCALON_ABIERTO,
        (unsigned long)(LAB9_FIN_ESCALON_ABIERTO-LAB9_PRETRIGGER)*
                       (unsigned long)LAB9_TS_US/1000ul);
    UART_Debug_PutString(linea);
    /* El encabezado CSV constituye el contrato de intercambio con MATLAB. */
    UART_Debug_PutString(
        "k,t_us,adc_counts,adc_mV,y_cal_mV,y_rel_mV,r_mV,"
        "u_solicitada_mV,u_nominal_mV,xhat1_mV,xhat2_mV,xi_mV,"
        "innovacion_mV,dac_pos,dac_neg,cpu_us,intervalo_us,flags\r\n");

    /* El primer intervalo vale cero; los restantes reconstruyen el tiempo
     * real medido entre interrupciones en vez de asumir k*Ts. */
    for (k = 0u; k < cantidad; ++k) {
        lab9_muestra_t *m = &memoria[k];
        t_us += m->intervalo_us;
        (void)snprintf(linea, sizeof linea,
            "%u,%lu,%d,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%u,%u,%u,%u,%u\r\n",
            (unsigned)k, (unsigned long)t_us, (int)m->adc_cuentas,
            (long)lab9_convertir_mV(m->adc_V),
            (long)lab9_convertir_mV(m->y_V),
            (long)lab9_convertir_mV(m->y_rel_V),
            (long)lab9_convertir_mV(m->referencia_V),
            (long)lab9_convertir_mV(m->u_solicitada_V),
            (long)lab9_convertir_mV(m->u_dac_nominal_V),
            (long)lab9_convertir_mV(m->xhat1_V),
            (long)lab9_convertir_mV(m->xhat2_V),
            (long)lab9_convertir_mV(m->xi_V),
            (long)lab9_convertir_mV(m->innovacion_V),
            (unsigned)m->dac_pos, (unsigned)m->dac_neg,
            (unsigned)m->cpu_us, (unsigned)m->intervalo_us,
            (unsigned)m->banderas);
        UART_Debug_PutString(linea);
    }
    UART_Debug_PutString("# LAB9 END; DAC=0; reiniciar para repetir\r\n");
}
