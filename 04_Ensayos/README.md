# Protocolo experimental ejecutado

Cada controlador se ensayó por separado mediante la misma secuencia segura:

1. programar `MONITOR` y confirmar mando y DAC nulos;
2. seleccionar un caso LQR y habilitar conscientemente el lazo;
3. aplicar el pulso de referencia de 0,5 V;
4. capturar simultáneamente ambos canales del RIGOL;
5. registrar firmware, ganancias, período, límites y metadatos;
6. regresar a `MONITOR` antes del siguiente caso.

Para cada caso se calcularon tiempo de subida 10–90 %, establecimiento al 2 %,
sobrepasamiento, error estacionario y extremos del mando. Los resultados
simulados nunca sustituyen datos experimentales.

## Capturas RIGOL

Se adquirieron 1200 muestras por canal y caso con un RIGOL DS1202Z-E. La
asignación verificada es **CH1/J5 = mando** y **CH2/J7 = salida de planta**.
Los intervalos principales fueron:

| Caso | CH1/J5 mando [mV] | CH2/J7 salida [mV] |
|---:|---:|---:|
| 1 | 16 a 480 | -32 a 496 |
| 2 | -223 a 681 | -40 a 500 |
| 3 | -22 a 482 | -30 a 500 |

Las adquisiciones muestran con claridad los transitorios de mando y salida.
Los tiempos de subida medidos fueron 166, 16 y 58 ms para los casos 1, 2 y 3.
El tiempo de establecimiento se informa como mayor que 602 ms porque ninguna
salida permaneció dentro de la banda de ±10 mV antes de retirar el pulso.

Al finalizar se recompiló y programó `MONITOR`. Los DAC quedaron en cero y los
cuatro enclavamientos de actuación permanecen deshabilitados.
