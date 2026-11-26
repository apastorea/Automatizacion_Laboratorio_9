# Resultados — Laboratorio 9

Los archivos distinguen diseño calculado, simulación y medición experimental.
Las métricas dinámicas físicas proceden únicamente de UART; las magnitudes de
amplitud y ruido del osciloscopio se presentan como verificación instrumental
independiente.

## Tablas

- `resumen_diseno_lqr_lab9.csv`: ponderaciones, ganancias, radio espectral y
  convergencia de Riccati.
- `verificacion_firmware_lab9.csv`: contraste entre las constantes C y `dlqr`.
- `tabla_calculado_simulado_experimental_lab9.csv`: comparación de los tres
  casos con valores calculados, simulados y medidos.
- `resumen_experimental_lab9.csv`: métricas transitorias UART, mando, período,
  carga de CPU y banderas.
- `resumen_rigol_lab9.csv`: mínimos, máximos, pico a pico, RMS y dispersión de
  CH1/J5 y CH2/J7.
- `resumen_simulacion_lab9.csv` y `resumen_simulink_lab9.csv`: resultados de
  los modelos identificado y nominal.

MATLAB y Simulink coinciden en los extremos del mando con una diferencia menor
que 1 microvoltio. El modelo Simulink contiene 38 bloques, 76 líneas y ninguna
conexión abierta.

## Figuras principales

- `comparacion_lqr_identificada.png` y `comparacion_lqr_nominal.png`.
- `respuesta_experimental_lab9.png` y `mando_experimental_lab9.png`.
- `mapa_polos_lqr_lab9.png`.
- `diagrama_simulink_lab9.png`.
- `figuras/diagrama_bloques_lab9.png` y `.pdf`: arquitectura simplificada y
  legible del lazo digital implementado.
- `rigol_casos_ampliados_desde_csv_lab9.png` y `.pdf`: trazas de los tres casos
  con ejes independientes, sin alterar las muestras.

Las figuras UART se regeneran con
`actualizar_resultados_experimentales_lab9.m`. Las trazas del osciloscopio se
regeneran con `graficar_capturas_rigol_lab9.m`; el script no filtra, interpola,
suaviza ni normaliza los datos.

## Alcance de la medición RIGOL

La asignación verificada es **CH1/J5 = mando** y **CH2/J7 = salida de planta**.
Los tres CSV principales tienen 1200 muestras por canal. Sus intervalos son:

| Caso | CH1/J5 [mV] | CH2/J7 [mV] |
|---:|---:|---:|
| 1 | 12.0 a 17.6 | 4.0 a 14.4 |
| 2 | 11.2 a 17.6 | 3.2 a 14.8 |
| 3 | 12.0 a 17.6 | 4.4 a 14.0 |

La amplitud máxima de J7 fue 14.8 mV y no permitió reconocer una meseta de
50 mV. En consecuencia, `dinamica_evaluable` es falsa y no se derivan de estas
trazas $t_r$, $t_s$ ni $M_p$. Esas métricas se obtienen de las capturas UART
validadas. Las adquisiciones diagnósticas crudas se conservan como trazabilidad,
pero no se incluyen en el informe ni en la tabla de desempeño.
