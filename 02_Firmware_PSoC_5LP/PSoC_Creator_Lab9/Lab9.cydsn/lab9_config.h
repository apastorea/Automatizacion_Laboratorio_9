#ifndef LAB9_CONFIG_H
#define LAB9_CONFIG_H

/* Laboratorio 9: control optimo con accion integral.
 * La configuracion entregada queda deliberadamente en MONITOR y con todos
 * los enclavamientos de actuacion deshabilitados.
 */

/* Modos mutuamente excluyentes compilados en el firmware. MONITOR conserva
 * ambos DAC en cero; LAZO_ABIERTO aplica un pulso acotado; LQR ejecuta el
 * estimador de estado y la realimentacion optima con accion integral. */
#define LAB9_MODO_MONITOR          (0u)
#define LAB9_MODO_LAZO_ABIERTO     (1u)
#define LAB9_MODO_LQR              (2u)

#define LAB9_CASO_1                (1u)
#define LAB9_CASO_2                (2u)
#define LAB9_CASO_3                (3u)

#define LAB9_MODO                  LAB9_MODO_MONITOR
#define LAB9_CASO                  LAB9_CASO_1

/* Enclavamientos de compilacion: un modo que pueda actuar sobre la planta no
 * se genera mientras no exista una autorizacion explicita para esa etapa. */
#define LAB9_AUTORIZAR_ESCALON         (0u)
#define LAB9_PLANTA_VERIFICADA         (0u)
#define LAB9_ADC_DAC_REVALIDADOS       (0u)
#define LAB9_AUTORIZAR_LAZO_CERRADO   (0u)

#if LAB9_MODO > LAB9_MODO_LQR
#error Modo del Laboratorio 9 invalido.
#endif

#if LAB9_CASO < LAB9_CASO_1 || LAB9_CASO > LAB9_CASO_3
#error Caso LQR invalido.
#endif

#if LAB9_MODO == LAB9_MODO_LAZO_ABIERTO && LAB9_AUTORIZAR_ESCALON != 1u
#error Escalon abierto bloqueado hasta completar la revalidacion.
#endif

#if LAB9_MODO == LAB9_MODO_LQR && \
   (LAB9_PLANTA_VERIFICADA != 1u || LAB9_ADC_DAC_REVALIDADOS != 1u || \
    LAB9_AUTORIZAR_LAZO_CERRADO != 1u)
#error LAZO LQR BLOQUEADO: validar planta, ADC/DAC y autorizar explicitamente.
#endif

/* Base temporal: el Timer_TS recibe 100 kHz (10 us/cuenta). En PSoC Creator
 * el periodo se programa como N-1, por eso 200 cuentas producen Ts = 2 ms. */
#define LAB9_TS_CUENTAS              (200u)
#define LAB9_TS_US                   (LAB9_TS_CUENTAS*10u)
#define LAB9_TOLERANCIA_US           (LAB9_TS_US/10u)
#define LAB9_N_MUESTRAS              (600u)
#define LAB9_PRETRIGGER              (32u)  /* 64 ms para estimar el cero. */
#define LAB9_FIN_REFERENCIA          (333u)
#define LAB9_FIN_ESCALON_ABIERTO     (128u)
#define LAB9_INICIO_MS               (3000u) /* Ventana para observar salidas seguras. */
#define LAB9_REFERENCIA_V            (0.050f)
#define LAB9_ESCALON_ABIERTO_MV      (50)
#define LAB9_ESCALON_ABIERTO_V       ((float)LAB9_ESCALON_ABIERTO_MV/1000.0f)

#if LAB9_ESCALON_ABIERTO_MV == 0 || \
    LAB9_ESCALON_ABIERTO_MV > 50 || LAB9_ESCALON_ABIERTO_MV < -50
#error El escalon abierto debe estar entre -50 mV y +50 mV y ser no nulo.
#endif

#if LAB9_FIN_ESCALON_ABIERTO <= LAB9_PRETRIGGER
#error La ventana del escalon abierto es invalida.
#endif

/* Limites del mando definidos a partir del rango util validado. Son mas
 * restrictivos que el limite fisico absoluto y se usan dentro del LQR. */
#define LAB9_U_MIN_V                 (-0.115f)
#define LAB9_U_MAX_V                 (0.107f)
#define LAB9_U_LIMITE_FISICO_V       (0.120f)
#define LAB9_Y_FALLO_V               (0.500f)

/* Calibracion del canal de medida: y=(V_ADC-offset)/ganancia. La salida
 * bipolar usa dos DAC unipolares y reconstruye u=Gp*Vp-Gn*Vn. */
#define LAB9_ADC_OFFSET_V             (2.353802067f)
#define LAB9_ADC_V_POR_V_PLANTA       (0.210251951f)
#define LAB9_DAC_GANANCIA_POS         (3.842612000f)
#define LAB9_DAC_GANANCIA_NEG         (2.640105691f)
#define LAB9_DAC_V_POR_CUENTA         (0.004f)
#define LAB9_SALIDA_FISICA_MAX_V      (1.0f)
#define LAB9_SALIDA_FISICA_MIN_V      (-1.0f)

#endif
