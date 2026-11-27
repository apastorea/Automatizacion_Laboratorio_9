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
Respecto del nivel final experimental, los tiempos de subida fueron 146, 16 y
46 ms y los establecimientos dinámicos al 2 % fueron 264, 34 y 88 ms. En una
comprobación separada, ninguna salida permaneció dentro de la banda de
seguimiento de ±10 mV alrededor de 0,5 V; el error final quedó entre 15,8 y
20,0 mV.

Al finalizar se recompiló y programó `MONITOR`. Los DAC quedaron en cero y los
cuatro enclavamientos de actuación permanecen deshabilitados.
