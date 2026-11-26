# Revalidación previa al Laboratorio 9

Antes del cierre de lazo se debe repetir la comprobación mínima del montaje:

- alimentación y tierra común;
- salida nula en modo `MONITOR`;
- período real de 2 ms y margen de tiempo de ISR;
- cero y escala del ADC;
- signo y escala del DAC en ambas ramas;
- respuesta abierta a +50 mV y -50 mV;
- ausencia de banderas de falla.

Si cambia la planta, la etapa de acondicionamiento o la escala del DAC, deben
actualizarse el modelo y los límites antes de usar las ganancias LQR.
