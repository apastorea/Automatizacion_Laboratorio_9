# Laboratorio 9 — Control óptimo con integrador

Este directorio reúne el desarrollo completo del Laboratorio 9 de
Automatización. La síntesis de los controladores y del estimador se realiza con
el **modelo identificado** previamente validado. El modelo calculado a
partir de los componentes se conserva únicamente como caso de incertidumbre.

## Decisión técnica principal

- Período de muestreo: `Ts = 2 ms`.
- Modelo de diseño: identificado, con `K = 1.002941`,
  `tau1 = 9.06915 ms` y `tau2 = 0.774399 ms`.
- Salida medida: `y = [0 1]x`.
- Estado integral: `xi[k+1] = xi[k] + r[k] - y[k]`.
- Ley de control: `u[k] = -Kx*xhat[k] - Ki*xi[k]`.
- Estimador: actual, diseñado con el mismo modelo identificado.
- Referencia de simulación y banco: pulso de `0,5 V`, seleccionado mediante un
  barrido de amplitud entre 0,25 V y 1 V. El criterio exige ausencia de
  saturación y un mando máximo de 0,8 V para conservar margen físico.

## Ponderaciones solicitadas

| Caso | `diag(Q1)` | `Q2` |
|---|---:|---:|
| 1 | `[0.01 0.01 0.001]` | `1` |
| 2 | `[0.01 0.01 0.1]` | `0.1` |
| 3 | `[0.01 0.01 0.001]` | `0.01` |

## Estructura

- `00_Enunciado/`: consigna actual del laboratorio.
- `01_Modelado_MATLAB/`: diseño LQR, Riccati, estimador y simulaciones.
- `02_Firmware_PSoC_5LP/`: proyecto, código y verificación del firmware Lab9.
- `03_Calibracion/`: comprobaciones que deben repetirse antes del cierre de lazo.
- `04_Ensayos/`: protocolo y capturas experimentales UART.
- `05_Resultados/`: CSV y figuras generadas por MATLAB.
- `06_Informe_IEEE/`: informe técnico en formato IEEE.
- `07_Registro_de_decisiones/`: trazabilidad de parámetros y decisiones.

## Reproducción

Desde MATLAB, con `01_Modelado_MATLAB` como carpeta activa:

```matlab
diseno_control_optimo_lab9
seleccionar_referencia_lab9
procesar_capturas_rigol_lab9
generar_diagrama_bloques_lab9
verificar_simulink_lab9
verificar_estructura_simulink_lab9
verificar_firmware_lab9
```

El script verifica controlabilidad, observabilidad, estabilidad, convergencia de
Riccati y coincidencia con `dlqr`. Luego simula los tres diseños con las plantas
identificada y nominal, tanto con actuador ideal limitado como con el DAC
cuantizado del montaje.

La tabla consolidada se guarda en
`05_Resultados/tabla_calculado_simulado_medido_lab9.csv` y contiene los valores
calculados, simulados y medidos para los tres casos. Las métricas físicas se
obtienen directamente de los CSV de dos canales adquiridos con el RIGOL.

## Estado actual

La etapa de diseño, el firmware y la medición física están completos. Se
revalidó la cadena con un pulso abierto de 0,5 V y se capturaron los tres
controladores con 1200 muestras por canal. Las respuestas de J7 alcanzaron
aproximadamente 0,48 V y el caso 2 fue el más rápido. El proyecto PSoC Creator
compiló sin advertencias y la placa quedó finalmente programada en `MONITOR`,
con los enclavamientos de actuación y ambos DAC en cero.
