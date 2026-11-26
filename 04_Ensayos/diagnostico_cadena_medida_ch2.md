# Asignación verificada de canales y estado de la cadena de medida

La identificación física quedó resuelta durante la validación del montaje:

- **CH1 está conectado a J5** y mide el mando físico aplicado, $u(t)$.
- **CH2 está conectado a J7** y mide la salida física de la planta, $y(t)$.

Esta asignación coincide en los scripts de adquisición, los metadatos, las
figuras y el informe. Ya no existe un nodo pendiente de identificar.

## Resultado instrumental

Para cada controlador se adquirieron 1200 muestras por canal con un paso de
2 ms. En los tres ensayos principales, CH1/J5 quedó entre 11.2 y 17.6 mV y
CH2/J7 entre 3.2 y 14.8 mV. La amplitud observada en J7 no permitió reconocer
una meseta de 50 mV ni calcular de forma confiable tiempos de subida,
establecimiento o sobrepasamiento desde el osciloscopio.

Por esa razón, el RIGOL se usa como verificación independiente de conexión,
amplitud, nivel eficaz y ruido. Las métricas dinámicas experimentales proceden
de las capturas UART validadas de 600 muestras por controlador. No se mezclan
ni sincronizan artificialmente ambas fuentes.

## Estado final seguro

Después de las adquisiciones se recompiló y programó nuevamente `MONITOR`.
Los dos DAC quedaron en cero y los cuatro enclavamientos de actuación
permanecen deshabilitados en la configuración entregada.

Para futuras mediciones debe conservarse una masa común segura y verificarse
que la configuración declarada en el instrumento coincida con la sonda física.
Las capturas diagnósticas crudas se conservan únicamente como trazabilidad y
no forman parte de la comparación de desempeño.
