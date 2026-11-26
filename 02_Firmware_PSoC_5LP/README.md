# Firmware PSoC 5LP — plan de integración

El Laboratorio 9 empleará la siguiente arquitectura segura:

- modo inicial `MONITOR`, con ambos DAC en cero;
- enclavamientos de compilación antes de autorizar el lazo cerrado;
- período de interrupción de 2 ms;
- estimador actual, saturación, anti-windup y parada segura;
- telemetría UART de salida, mando, estados, integral y banderas.

La modificación funcional consiste en reemplazar los dos juegos de ganancias por
tres casos LQR. Las ganancias deben tomarse del CSV
`05_Resultados/resumen_diseno_lqr_lab9.csv`
generado con el modelo identificado.

Antes de programar el dispositivo se debe:

1. ejecutar el diseño MATLAB y congelar las ganancias verificadas;
2. repetir `MONITOR` y la comprobación bipolar de ±50 mV;
3. verificar que los límites y escalas del DAC siguen vigentes;
4. ensayar un único caso por compilación/captura;
5. volver a `MONITOR` entre casos y al finalizar.

## Archivos preparados

- `PSoC_Creator_Lab9/Lab9.cywrk`: workspace autónomo rotulado como Lab9.
- `PSoC_Creator_Lab9/Lab9.cydsn/`: proyecto, TopDesign y fuentes integradas.
- `src/lab9_config.h`: modos, casos, tiempos, límites y enclavamientos.
- `src/lab9_control_optimo.h`: interfaz portable del controlador.
- `src/lab9_control_optimo.c`: estimador, LQR, anti-windup y corrección DAC.
- `tests/test_lab9_control_optimo.c`: prueba portable de los tres casos.

El núcleo portable compiló con `-Wall -Wextra -Werror`. El workspace completo
también compiló en configuración Release con GCC ARM 5.4.1 de PSoC Creator 4.4,
sin advertencias: 9560 bytes de Flash y 33889 bytes de SRAM. El script
`01_Modelado_MATLAB/verificar_firmware_lab9.m` confirmó que las ganancias C
coinciden con `dlqr` con error máximo de `4.326e-10`, que las fuentes están
sincronizadas y que el archivo `Lab9.hex` está presente.

No se habilita aquí ningún lazo físico de forma automática. La configuración
entregada permanece en `LAB9_MODO_MONITOR`, con los cuatro enclavamientos en cero.

Para reconstruir desde una consola de PSoC Creator:

```text
cyprjmgr -wrk Lab9.cywrk -clean -build -c Release -warn High
```
