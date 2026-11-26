/*
 * Adaptacion entre el algoritmo de control y los perifericos del PSoC 5LP.
 * Centraliza la calibracion del ADC, la conversion del mando a los dos DAC y
 * la puesta a cero segura de la etapa de actuacion.
 */
#include "lab9_hardware.h"
#include "lab9_config.h"

/* Conversion determinada por las constantes generadas para el ADC del
 * TopDesign. Se calcula una vez para reducir el costo dentro de la ISR. */
static float adc_V_por_cuenta = 0.0f;
static int16 adc_offset_cuentas = 0;

float lab9_limitar_hardware(float valor, float inferior, float superior)
{
    return (valor > superior) ? superior :
           ((valor < inferior) ? inferior : valor);
}

static uint8 lab9_codigo_dac(float dac_V)
{
    /* Cuantizacion al entero mas cercano y saturacion al rango de 8 bits. */
    const float codigo = lab9_limitar_hardware(
        dac_V/LAB9_DAC_V_POR_CUENTA, 0.0f, 255.0f);
    return (uint8)(codigo+0.5f);
}

void lab9_hardware_inicializar(void)
{
    int32 escala;
    /* El orden de arranque mantiene primero ambos DAC en cero. Los opamps y
     * el ADC se habilitan despues, sin iniciar aun el temporizador de control. */
    Timer_TS_Stop();
    registro_Write(0u);
    DAC_P_Init();
    DAC_N_Init();
    DAC_P_SetRange(DAC_P_RANGE_1V);
    DAC_N_SetRange(DAC_N_RANGE_1V);
    DAC_P_SetValue(0u);
    DAC_N_SetValue(0u);
    DAC_P_Enable();
    DAC_N_Enable();
    Opamp_2_Start();
    Opamp_3_Start();
    Opamp_4_Start();
    ADC_Start();
    ADC_IRQ_Disable();
    CyDelayUs(20u);

    /* PSoC Creator puede generar countsPerVolt o countsPer10Volt segun la
     * configuracion. Esta expresion normaliza ambos casos a V/cuenta. */
    escala = (ADC_countsPerVolt != 0) ?
             (int32)ADC_countsPerVolt*10 : ADC_countsPer10Volt;
    if (escala > 0) {
        adc_offset_cuentas = ADC_offset;
        adc_V_por_cuenta = 10.0f/(float)escala;
    }
}

float lab9_hardware_leer_planta(int16 *cuentas, float *adc_V)
{
    /* Primero se convierte la cuenta del SAR a tension en el pin. Luego se
     * deshace el offset y la ganancia del acondicionamiento identificado. */
    const int16 bruto = ADC_GetResult16();
    const float voltios = (float)(int16)(bruto-adc_offset_cuentas)*
                          adc_V_por_cuenta;
    *cuentas = bruto;
    *adc_V = voltios;
    return (voltios-LAB9_ADC_OFFSET_V)/LAB9_ADC_V_POR_V_PLANTA;
}

float lab9_hardware_escribir_salida(float solicitada_V, uint8 *dac_pos,
                                    uint8 *dac_neg, uint8 *saturada)
{
    const float limitada = lab9_limitar_hardware(
        solicitada_V, LAB9_SALIDA_FISICA_MIN_V, LAB9_SALIDA_FISICA_MAX_V);
    uint8 positiva = 0u;
    uint8 negativa = 0u;

    /* Una sola rama queda activa: DAC_P para u>=0 y DAC_N para u<0. Las
     * ganancias diferentes compensan la asimetria medida de ambas ramas. */
    *saturada = (uint8)(limitada != solicitada_V);
    if (limitada >= 0.0f)
        positiva = lab9_codigo_dac(limitada/LAB9_DAC_GANANCIA_POS);
    else
        negativa = lab9_codigo_dac(-limitada/LAB9_DAC_GANANCIA_NEG);

    DAC_P_SetValue(positiva);
    DAC_N_SetValue(negativa);
    *dac_pos = positiva;
    *dac_neg = negativa;
    /* Valor nominal realmente aplicado despues de redondear los codigos;
     * se devuelve para realimentarlo al predictor y registrarlo por UART. */
    return LAB9_DAC_V_POR_CUENTA*
           (LAB9_DAC_GANANCIA_POS*(float)positiva-
            LAB9_DAC_GANANCIA_NEG*(float)negativa);
}

void lab9_hardware_salida_cero(void)
{
    DAC_P_SetValue(0u);
    DAC_N_SetValue(0u);
}
