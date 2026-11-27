# Capturas experimentales RIGOL

La asignación física verificada es:

- **CH1/J5:** mando aplicado, $u(t)$.
- **CH2/J7:** salida de la planta, $y(t)$.

Para cada caso se conservan:

- `rigol_caso_N_dos_canales_lab9.csv`, con 1200 muestras por canal;
- `rigol_caso_N_pantalla_lab9.png`, captura nativa del instrumento;
- `rigol_caso_N_metadatos_lab9.json`, configuración y trazabilidad VISA/SCPI.

El procesamiento se realiza con `procesar_capturas_rigol_lab9.m`. La figura
principal conserva las muestras crudas y superpone una media móvil de siete
muestras únicamente para la detección robusta de umbrales. CH2/J7 alcanzó
aproximadamente 0,48 V; de estas trazas se obtienen los tiempos de subida, el
sobrepasamiento, el error final y los extremos físicos de J5 que se presentan
en la tabla del informe.
