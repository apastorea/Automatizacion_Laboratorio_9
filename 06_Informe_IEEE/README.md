# Informe IEEE — Laboratorio 9

La carpeta `Informe_Lab9` contiene el informe en formato IEEE.

El documento incluye el modelo identificado, el diseño LQR, la verificación de
Riccati, el estimador actual, las simulaciones, la validación física y una tabla
comparativa de valores calculados, simulados y medidos experimentalmente.

Para compilar:

```text
pdflatex -jobname=Informe_Lab9_Automatizacion_Aldo_Pastore_v2 main.tex
pdflatex -jobname=Informe_Lab9_Automatizacion_Aldo_Pastore_v2 main.tex
```

Las figuras se generan mediante los scripts de `01_Modelado_MATLAB`. El informe
lee los resultados generales desde `05_Resultados/figuras` y conserva en
`Informe_Lab9/figuras` únicamente las dos imágenes que incorpora como copia
local.
