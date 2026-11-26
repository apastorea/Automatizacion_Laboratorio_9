# Capturas experimentales UART y RIGOL

## Telemetría UART

Las capturas válidas de los controladores se almacenan como:

- `caso_1_uart.csv`
- `caso_2_uart.csv`
- `caso_3_uart.csv`

Cada archivo conserva los metadatos que comienzan con `#` y la cabecera CSV
emitida por el firmware. `actualizar_resultados_experimentales_lab9.m` exige
modo `LQR`, caso coincidente, 600 muestras consecutivas, período de 2 ms con
tolerancia de ±10 %, referencia de 50 mV y ausencia de banderas fatales. Los
datos que no cumplen estas condiciones se rechazan y no se incorporan a la
tabla comparativa.

## Osciloscopio RIGOL

La asignación física verificada es:

- **CH1/J5:** mando aplicado, $u(t)$.
- **CH2/J7:** salida de la planta, $y(t)$.

Para cada caso se conservan:

- `rigol_caso_N_dos_canales_lab9.csv`, con 1200 muestras por canal;
- `rigol_caso_N_pantalla_lab9.png`, captura nativa del instrumento;
- `rigol_caso_N_metadatos_lab9.json`, configuración y trazabilidad VISA/SCPI.

Las adquisiciones principales tienen `uartSincronizada=false`: constituyen una
medición física independiente y no se alinean muestra a muestra con los CSV
UART. El procesamiento se realiza con `procesar_capturas_rigol_lab9.m` y la
figura principal se regenera mediante `graficar_capturas_rigol_lab9.m`, sin
filtrado, suavizado, interpolación ni normalización.

CH2/J7 alcanzó como máximo 14.8 mV, por lo que los tiempos de subida,
establecimiento y sobrepasamiento no se calculan desde estas trazas. Las
métricas dinámicas experimentales se obtuvieron por UART. Las otras
capturas instrumentales se conservan como evidencia diagnóstica cruda, pero no
se usan en el informe ni en la tabla de desempeño.
