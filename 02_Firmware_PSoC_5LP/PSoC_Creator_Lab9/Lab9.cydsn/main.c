/*
 * Laboratorio 9 - Programa principal del PSoC 5LP.
 *
 * Configura el muestreo a 2 ms, ejecuta el modo elegido en lab9_config.h y
 * guarda cada muestra para transmitirla por UART al finalizar el ensayo. La
 * entrega permanece en MONITOR, con los DAC en cero y la actuacion bloqueada.
 */
#include "project.h"
#include "lab9_config.h"
#include "lab9_control_optimo.h"
#include "lab9_hardware.h"
#include "lab9_telemetria.h"
#include "lab9_types.h"
#include <float.h>

/* Contratos de integracion con TopDesign. Un cambio accidental de resolucion,
 * disparo, rango o ancho de temporizador detiene la compilacion. */
#if ADC_DEFAULT_RESOLUTION != 12u || ADC_DEFAULT_CONV_MODE != ADC__HARDWARE_TRIGGER
#error TopDesign requiere ADC SAR de 12 bits con disparo por hardware.
#endif
#if ADC_DEFAULT_RANGE != ADC__VSSA_TO_VDDA
#error El rango ADC no coincide con la conversion de cuentas configurada.
#endif
#if Timer_TS_Resolution != 16u || Timer_Medicion_Resolution != 16u
#error Se requieren temporizadores de 16 bits.
#endif

/* Buffer fijo para que la ISR no use memoria dinamica. A 600 muestras permite
 * registrar 1.2 s sin transmitir durante el control, evitando jitter UART. */
static lab9_muestra_t memoria[LAB9_N_MUESTRAS];
static volatile uint16 cuenta = 0u;
static volatile uint8 captura_finalizada = 0u;
static uint16 tick_anterior = 0u;
static float acumulado_cero_V = 0.0f;
static float cero_V = 0.0f;
static lab9_estado_t estado;
static lab9_parametros_t parametros;

CY_ISR_PROTO(Lab9MuestreoISR);

static uint8 lab9_es_finito(float valor)
{
    return (uint8)(valor <= FLT_MAX && valor >= -FLT_MAX);
}

static uint16 lab9_leer_timer_us(void)
{
    /* Timer_Medicion es descendente y corre a 1 MHz; su captura software
     * permite medir intervalo y tiempo de CPU con resolucion de 1 us. */
    Timer_Medicion_SoftwareCapture();
    return Timer_Medicion_ReadCapture();
}

static void lab9_detener_seguro(void)
{
    /* Punto unico de parada: primero cesa el muestreo y luego ambos DAC se
     * llevan a cero antes de marcar la captura como finalizada. */
    Timer_TS_Stop();
    lab9_hardware_salida_cero();
    captura_finalizada = 1u;
}

CY_ISR(Lab9MuestreoISR)
{
    /* La ISR realiza una transaccion completa medir-estimar-controlar-actuar.
     * El pin registro permanece alto durante la ejecucion para observarla
     * externamente con osciloscopio o analizador logico. */
    uint16 k = cuenta;
    uint16 tic_ini;
    uint16 intervalo = 0u;
    uint16 cpu_us;
    uint8 banderas = 0u;
    uint8 positivo = 0u;
    uint8 negativo = 0u;
    uint8 saturado = 0u;
    int16 adc_bruto = 0;
    float adc_V = 0.0f;
    float salida_V;
    float salida_rel_V;
    float referencia_V = 0.0f;
    float u_solicitada_V = 0.0f;
    float u_nominal_V;
    lab9_muestra_t *muestra;
#if LAB9_MODO == LAB9_MODO_LQR
    unsigned int saturaciones_antes = estado.saturaciones;
    unsigned int antiwindup_antes = estado.antiwindup_bloqueos;
#endif

    registro_Write(1u);
    if (captura_finalizada || k >= LAB9_N_MUESTRAS) {
        lab9_detener_seguro();
        registro_Write(0u);
        return;
    }

    /* Verificacion temporal respecto del inicio de la muestra anterior. */
    tic_ini = lab9_leer_timer_us();
    if (k > 0u) {
        intervalo = (uint16)(tick_anterior-tic_ini);
        if (intervalo < (LAB9_TS_US-LAB9_TOLERANCIA_US) ||
            intervalo > (LAB9_TS_US+LAB9_TOLERANCIA_US))
            banderas |= LAB9_F_TIEMPO;
    }
    tick_anterior = tic_ini;

    /* Adquisicion y comprobaciones numericas y de rango del ADC. */
    salida_V = lab9_hardware_leer_planta(&adc_bruto, &adc_V);
    if (!lab9_es_finito(salida_V) || !lab9_es_finito(adc_V)) {
        salida_V = 0.0f;
        banderas |= LAB9_F_NUM;
    }
    if (adc_bruto <= 2 || adc_bruto >= 4093) banderas |= LAB9_F_ADC;

    /* El promedio de pretrigger elimina el sesgo estatico residual antes de
     * evaluar seguimiento, sobreimpulso y error estacionario. */
    if (k < LAB9_PRETRIGGER) {
        acumulado_cero_V += salida_V;
        if (k+1u == LAB9_PRETRIGGER)
            cero_V = acumulado_cero_V/(float)LAB9_PRETRIGGER;
    }
    salida_rel_V = (k >= LAB9_PRETRIGGER) ? salida_V-cero_V : salida_V;
    if (salida_rel_V > LAB9_Y_FALLO_V || salida_rel_V < -LAB9_Y_FALLO_V)
        banderas |= LAB9_F_Y;

    /* Seleccion resuelta en compilacion: MONITOR nunca solicita mando; ABIERTO
     * genera un pulso; LQR activa referencia, estimador e integrador. */
#if LAB9_MODO == LAB9_MODO_LAZO_ABIERTO
    if (k >= LAB9_PRETRIGGER && k < LAB9_FIN_ESCALON_ABIERTO)
        u_solicitada_V = LAB9_ESCALON_ABIERTO_V;
#elif LAB9_MODO == LAB9_MODO_LQR
    if (k >= LAB9_PRETRIGGER) {
        if (k < LAB9_FIN_REFERENCIA) referencia_V = LAB9_REFERENCIA_V;
        u_solicitada_V = lab9_calcular_paso(
            &parametros, &estado, referencia_V, salida_rel_V);
        if (estado.saturaciones > saturaciones_antes)
            banderas |= LAB9_F_SAT_CONTROL;
        if (estado.antiwindup_bloqueos > antiwindup_antes)
            banderas |= LAB9_F_ANTIWINDUP;
    } else {
        lab9_reiniciar(&estado, 0.0f, 0.0f);
    }
#else
    u_solicitada_V = 0.0f;
#endif

    /* Cualquier anomalia fatal tiene prioridad sobre el controlador. */
    if (!lab9_es_finito(u_solicitada_V)) {
        u_solicitada_V = 0.0f;
        banderas |= LAB9_F_NUM;
    }
    if ((banderas & LAB9_F_FATALES) != 0u) u_solicitada_V = 0.0f;

    /* Actuacion bipolar, seguida de una segunda barrera sobre el mando que
     * realmente representan los codigos DAC cuantizados. */
    u_nominal_V = lab9_hardware_escribir_salida(
        u_solicitada_V, &positivo, &negativo, &saturado);
    if (saturado || u_nominal_V > LAB9_U_LIMITE_FISICO_V ||
        u_nominal_V < -LAB9_U_LIMITE_FISICO_V) {
        banderas |= LAB9_F_DAC_FISICO;
        lab9_hardware_salida_cero();
        u_nominal_V = 0.0f;
        positivo = 0u;
        negativo = 0u;
    }

#if LAB9_MODO == LAB9_MODO_LQR
    if (k >= LAB9_PRETRIGGER)
        lab9_corregir_mando_aplicado(&parametros, &estado, u_nominal_V);
#endif

    /* Instantanea coherente de la muestra. Se transmite solo al finalizar el
     * ensayo para que el tiempo UART no interfiera con Ts=2 ms. */
    muestra = &memoria[k];
    muestra->adc_V = adc_V;
    muestra->y_V = salida_V;
    muestra->y_rel_V = salida_rel_V;
    muestra->referencia_V = referencia_V;
    muestra->u_solicitada_V = u_solicitada_V;
    muestra->u_dac_nominal_V = u_nominal_V;
    muestra->adc_cuentas = adc_bruto;
    muestra->dac_pos = positivo;
    muestra->dac_neg = negativo;
    muestra->intervalo_us = intervalo;
#if LAB9_MODO == LAB9_MODO_LQR
    muestra->xhat1_V = estado.x_control[0];
    muestra->xhat2_V = estado.x_control[1];
    muestra->xi_V = estado.xi;
    muestra->innovacion_V = estado.innovacion_V;
#else
    muestra->xhat1_V = 0.0f;
    muestra->xhat2_V = 0.0f;
    muestra->xi_V = 0.0f;
    muestra->innovacion_V = 0.0f;
#endif
    /* Presupuesto temporal: la ejecucion debe terminar antes del siguiente
     * periodo; si no, se eleva una bandera fatal y se detiene el ensayo. */
    cpu_us = (uint16)(tic_ini-lab9_leer_timer_us());
    muestra->cpu_us = cpu_us;
    if (cpu_us >= LAB9_TS_US) banderas |= LAB9_F_CPU;
    muestra->banderas = banderas;

    cuenta = k+1u;
    if ((banderas & LAB9_F_FATALES) != 0u || cuenta >= LAB9_N_MUESTRAS)
        lab9_detener_seguro();
    registro_Write(0u);
}

int main(void)
{
    uint16 anterior = 0u;
    uint8 intentos = 0u;

    /* Arranque determinista con interrupciones deshabilitadas y salida nula.
     * La adquisicion comienza solo tras cargar parametros y esperar 3 s. */
    CyGlobalIntDisable;
    if (!lab9_cargar_parametros((lab9_caso_t)LAB9_CASO, &parametros)) {
        for (;;) { }
    }
    lab9_reiniciar(&estado, 0.0f, 0.0f);
    lab9_hardware_inicializar();
    lab9_hardware_salida_cero();
    UART_Debug_Start();
    Clock_Medicion_Start();
    Timer_Medicion_Start();
    Timer_TS_Init();
    Timer_TS_WritePeriod((uint16)(LAB9_TS_CUENTAS-1u));
    isr_StartEx(Lab9MuestreoISR);
    isr_ClearPending();

    UART_Debug_PutString(
        "\r\n# LAB9 inicio seguro; revisar lab9_config.h; espera 3s\r\n");
    CyDelay(LAB9_INICIO_MS);
    CyGlobalIntEnable;
    Clock_1_Start();
    Timer_TS_Enable();

    /* Supervisor de vivacidad: si la ISR no incrementa la cuenta durante
     * aproximadamente 100 ms, fuerza la parada segura. */
    while (!captura_finalizada) {
        CyDelay(10u);
        if (cuenta == anterior) ++intentos;
        else intentos = 0u;
        anterior = cuenta;
        if (intentos >= 10u) {
            uint8 estado_interrupcion = CyEnterCriticalSection();
            lab9_detener_seguro();
            CyExitCriticalSection(estado_interrupcion);
            UART_Debug_PutString(
                "# ERROR no llegan muestras; salida forzada a cero\r\n");
        }
    }
    lab9_volcar_uart(memoria, cuenta);
    for (;;) { CyDelay(1000u); }
}
