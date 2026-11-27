# Resultados — Laboratorio 9

Los archivos distinguen diseño calculado, simulación y medición experimental.
Las métricas dinámicas físicas proceden de los CSV de dos canales adquiridos
con el osciloscopio.

## Tablas

- `resumen_diseno_lqr_lab9.csv`: ponderaciones, ganancias, radio espectral y
  convergencia de Riccati.
- `verificacion_firmware_lab9.csv`: contraste entre las constantes C y `dlqr`.
- `tabla_calculado_simulado_medido_lab9.csv`: comparación de los tres
  casos con valores calculados, simulados y medidos.
- `resumen_rigol_lab9.csv`: métricas transitorias y extremos de CH1/J5 y
  CH2/J7.
- `resumen_simulacion_lab9.csv` y `resumen_simulink_lab9.csv`: resultados de
  los modelos identificado y nominal.

MATLAB y Simulink coinciden en los extremos del mando con una diferencia menor
que 1 microvoltio. El modelo Simulink contiene 38 bloques, 76 líneas y ninguna
conexión abierta.

## Figuras principales

- `comparacion_lqr_identificada.png` y `comparacion_lqr_nominal.png`.
- `figuras/respuesta_experimental_rigol_lab9.png` y `.pdf`.
- `mapa_polos_lqr_lab9.png`.
- `diagrama_simulink_lab9.png`.
- `figuras/diagrama_bloques_lab9.png` y `.pdf`: arquitectura simplificada y
  legible del lazo digital implementado.

Las trazas y métricas del osciloscopio se regeneran con
`procesar_capturas_rigol_lab9.m`. El script conserva la señal medida y emplea
una media móvil corta sólo para detectar umbrales con menor sensibilidad a una
muestra aislada.

## Alcance de la medición RIGOL

La asignación verificada es **CH1/J5 = mando** y **CH2/J7 = salida de planta**.
Los tres CSV principales tienen 1200 muestras por canal. Sus intervalos son:

| Caso | CH1/J5 [mV] | CH2/J7 [mV] |
|---:|---:|---:|
| 1 | 16 a 480 | -32 a 496 |
| 2 | -223 a 681 | -40 a 500 |
| 3 | -22 a 482 | -30 a 500 |

La amplitud de J7 fue suficiente para evaluar la dinámica. Respecto del nivel
final experimental, los tiempos de subida fueron 146, 16 y 46 ms; los tiempos
de establecimiento dinámico fueron 264, 34 y 88 ms; y los sobrepasamientos,
0,98 %, 3,48 % y 1,81 %. El seguimiento se evalúa por separado contra 0,5 V:
ningún caso sostuvo la banda de ±10 mV y el error final quedó entre 15,8 y
20,0 mV.
