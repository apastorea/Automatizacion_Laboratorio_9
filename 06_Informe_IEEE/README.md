# Informe IEEE — Laboratorio 9

La carpeta `Informe_Lab9` contiene el informe en formato IEEE.

El documento incluye el modelo identificado, el diseño LQR, la verificación de
Riccati, el estimador actual, las simulaciones, la validación física y una tabla
comparativa de valores calculados, simulados y medidos experimentalmente.

Para compilar:

```text
pdflatex -jobname=Informe_Lab9_Automatizacion_Aldo_Pastore_v1 main.tex
pdflatex -jobname=Informe_Lab9_Automatizacion_Aldo_Pastore_v1 main.tex
```

Las figuras se generan mediante `01_Modelado_MATLAB/diseno_control_optimo_lab9.m`
y se copian a `Informe_Lab9/figuras` antes de compilar.
