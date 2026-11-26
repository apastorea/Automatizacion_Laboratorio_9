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
- Referencia inicial de simulación y banco: pulso de `50 mV`, compatible con
  los límites revalidados del montaje.

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
generar_tabla_comparativa_lab9
actualizar_resultados_experimentales_lab9
verificar_simulink_lab9
verificar_estructura_simulink_lab9
verificar_firmware_lab9
```

El script verifica controlabilidad, observabilidad, estabilidad, convergencia de
Riccati y coincidencia con `dlqr`. Luego simula los tres diseños con las plantas
identificada y nominal, tanto con actuador ideal limitado como con el DAC
cuantizado del montaje.

La tabla consolidada se guarda en
`05_Resultados/tabla_calculado_simulado_experimental_lab9.csv` y contiene los
valores calculados, simulados y medidos para los tres casos. Las capturas UART
se conservan en `04_Ensayos/capturas/`; el actualizador valida sus metadatos,
integridad temporal y banderas antes de incorporar las métricas.

## Estado actual

La etapa de diseño MATLAB/Simulink, el firmware y las mediciones quedan
generadas por los scripts. El diagrama compiló con 38 bloques, 76 líneas y cero conexiones
abiertas. El workspace `PSoC_Creator_Lab9/Lab9.cywrk` genera `Lab9.hex` con GCC
ARM sin advertencias. Se revalidaron MONITOR y los pulsos abiertos de
`+/-50 mV`, y se capturaron los tres controladores LQR sin banderas ni
saturación. La placa quedó finalmente programada en `MONITOR`, con los
enclavamientos en cero y ambos DAC en cero.
