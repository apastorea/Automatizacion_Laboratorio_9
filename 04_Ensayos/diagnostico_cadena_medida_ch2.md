# Asignación verificada de canales y estado de la cadena de medida

La identificación física quedó resuelta durante la validación del montaje:

- **CH1 está conectado a J5** y mide el mando físico aplicado, $u(t)$.
- **CH2 está conectado a J7** y mide la salida física de la planta, $y(t)$.

Esta asignación coincide en los scripts de adquisición, los metadatos, las
figuras y el informe. Ya no existe un nodo pendiente de identificar.

## Resultado instrumental

Para cada controlador se adquirieron 1200 muestras por canal con un paso de
2 ms y una referencia de 0,5 V. J7 alcanzó aproximadamente 0,48 V en los tres
casos, por lo que los flancos y las mesetas quedaron claramente visibles. Las
métricas dinámicas experimentales se calculan directamente desde estos CSV.
La media móvil de siete muestras se utiliza sólo para evitar que una muestra
aislada modifique los cruces de umbral; la señal cruda se conserva en las
figuras y archivos originales.

## Estado final seguro

Después de las adquisiciones se recompiló y programó nuevamente `MONITOR`.
Los dos DAC quedaron en cero y los cuatro enclavamientos de actuación
permanecen deshabilitados en la configuración entregada.

Para futuras mediciones debe conservarse una masa común segura y verificarse
que la configuración declarada en el instrumento coincida con la sonda física.
Las capturas crudas forman parte de la trazabilidad y de la comparación de
desempeño presentada en el informe.
