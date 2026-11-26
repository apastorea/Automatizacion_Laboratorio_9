# Protocolo experimental ejecutado

Cada controlador se ensayó por separado mediante la misma secuencia segura:

1. programar `MONITOR` y confirmar mando y DAC nulos;
2. seleccionar un caso LQR y habilitar conscientemente el lazo;
3. aplicar el pulso de referencia de 50 mV;
4. capturar la telemetría UART y ambos canales del RIGOL;
5. registrar firmware, ganancias, período, límites y metadatos;
6. regresar a `MONITOR` antes del siguiente caso.

Para cada caso se calcularon tiempo de subida 10–90 %, establecimiento al 2 %,
establecimiento robusto frente a ruido, sobrepasamiento, error estacionario,
RMS, mando mínimo y máximo, saturaciones, anti-windup, fallas, período y peor
tiempo de ISR. Los resultados simulados nunca sustituyen datos experimentales.

## Capturas UART

Los tres casos cuentan con 600 muestras válidas. El importador
`01_Modelado_MATLAB/actualizar_resultados_experimentales_lab9.m` verifica los
metadatos y genera las métricas, figuras y la tabla
calculado–simulado–experimental.

## Capturas RIGOL

Se adquirieron 1200 muestras por canal y caso con un RIGOL DS1202Z-E. La
asignación verificada es **CH1/J5 = mando** y **CH2/J7 = salida de planta**.
Los intervalos principales fueron:

| Caso | CH1/J5 mando [mV] | CH2/J7 salida [mV] |
|---:|---:|---:|
| 1 | 12.0 a 17.6 | 4.0 a 14.4 |
| 2 | 11.2 a 17.6 | 3.2 a 14.8 |
| 3 | 12.0 a 17.6 | 4.4 a 14.0 |

El RIGOL aporta amplitud, valor eficaz, dispersión y trazabilidad instrumental.
Como J7 no presentó una meseta de 50 mV, estas adquisiciones no se emplean
para calcular métricas transitorias; esas métricas proceden de UART. Los
metadatos indican `uartSincronizada=false`, de modo que ambas fuentes se
mantienen separadas.

Al finalizar se recompiló y programó `MONITOR`. Los DAC quedaron en cero y los
cuatro enclavamientos de actuación permanecen deshabilitados.
