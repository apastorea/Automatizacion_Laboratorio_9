# Registro de decisiones — Laboratorio 9

## 25/11/2026 — diseño y modelo

- Se adoptó el modelo identificado previamente validado para diseñar tanto los
  controladores como el estimador.
- El modelo nominal se conserva solamente para el análisis de sensibilidad.
- Se mantuvo $T_s=2$ ms y una referencia experimental de 50 mV.
- Se implementaron los tres pares de ponderaciones indicados en el enunciado.
- La simulación incluye actuador ideal limitado y DAC cuantizado.

## 25/11/2026 — Simulink y firmware

- Se verificaron seis simulaciones: tres controladores sobre las plantas
  identificada y nominal.
- MATLAB y Simulink coinciden en el mando mínimo y máximo dentro de
  1 microvoltio.
- El modelo compiló con 38 bloques, 76 líneas y ninguna conexión abierta.
- El núcleo C usa el mando realmente aplicado después de cuantizar el DAC.
- Las constantes C coinciden con `dlqr`; el error máximo es `4.326e-10`.
- Se creó el workspace autónomo `Lab9.cywrk` y el proyecto `Lab9.cyprj`.
- La compilación Release terminó sin advertencias y generó `Lab9.hex`.
- Uso de memoria: 9560 bytes de Flash y 33889 bytes de SRAM.

## Modelo de diseño

- `K = 1.002941`.
- `tau1 = 9.06915 ms`.
- `tau2 = 0.774399 ms`.
- Salida: `C = [0 1]`.
- Polos del estimador actual: `0.20 ± j0.10`.

## 25/11/2026 — cierre experimental

- Se revalidó `MONITOR` y la actuación bipolar en lazo abierto.
- Se obtuvieron 600 muestras UART válidas para cada controlador.
- Se completó la tabla calculado–simulado–experimental con métricas
  transitorias, error estacionario, mando y tiempos de ejecución.
- Se adquirieron 1200 muestras por canal y caso con el RIGOL DS1202Z-E.
- La asignación física quedó verificada como **CH1/J5 = mando** y
  **CH2/J7 = salida de planta**.
- CH1/J5 quedó entre 11.2 y 17.6 mV; CH2/J7 entre 3.2 y 14.8 mV.
- Como J7 no mostró una meseta de 50 mV, el RIGOL se emplea para amplitud,
  RMS, ruido y trazabilidad; las métricas dinámicas proceden de UART.
- Las fuentes no se mezclaron porque los metadatos RIGOL indican
  `uartSincronizada=false`.
- Se generó un diagrama de bloques simplificado para documentar la arquitectura
  implementada además del modelo Simulink completo.
- Al finalizar se recompiló y programó `MONITOR`; los DAC y los cuatro
  enclavamientos de actuación quedaron en cero.
