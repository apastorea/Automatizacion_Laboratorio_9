% PROBAR_PROCESAMIENTO_EXPERIMENTAL_LAB9 Prueba el importador sin crear datos.

clearvars;

% El archivo se crea en la carpeta temporal del sistema y onCleanup garantiza
% su eliminacion incluso si una asercion detiene anticipadamente la prueba.
rutaTemporal = string(tempname)+".csv";
limpieza = onCleanup(@() eliminarTemporal(rutaTemporal));
k = (0:599)';
intervalo_us = [0; repmat(2000,599,1)];
t_us = cumsum(intervalo_us);
r_mV = zeros(600,1);
r_mV(33:333) = 50;
% Señal sintetica utilizada para probar el importador. No se
% guarda en resultados ni se presenta como evidencia experimental.
y_rel_mV = zeros(600,1);
for indice = 34:333
    y_rel_mV(indice) = y_rel_mV(indice-1)+0.12*(50-y_rel_mV(indice-1));
end
for indice = 334:600
    y_rel_mV(indice) = 0.88*y_rel_mV(indice-1);
end
adc_counts = repmat(2048,600,1);
adc_mV = y_rel_mV;
y_cal_mV = y_rel_mV;
u_solicitada_mV = r_mV;
u_nominal_mV = r_mV;
xhat1_mV = zeros(600,1);
xhat2_mV = y_rel_mV;
xi_mV = zeros(600,1);
innovacion_mV = zeros(600,1);
dac_pos = zeros(600,1);
dac_neg = zeros(600,1);
cpu_us = repmat(80,600,1);
flags = zeros(600,1);

datos = table(k,t_us,adc_counts,adc_mV,y_cal_mV,y_rel_mV,r_mV, ...
    u_solicitada_mV,u_nominal_mV,xhat1_mV,xhat2_mV,xi_mV, ...
    innovacion_mV,dac_pos,dac_neg,cpu_us,intervalo_us,flags);
lineas = ["# LAB9 version=PRUEBA modelo=IDENTIFICADO estimador=ACTUAL_E2 " + ...
    "Ts_nominal_us=2000 modo=LQR caso=2 referencia_mV=50"; ...
    join(string(datos.Properties.VariableNames),","); ...
    join(string(datos.Variables),",",2)];
writelines(lineas, rutaTemporal, Encoding="UTF-8");

% Caso nominal valido: verifica metricas, cantidad de muestras y tiempo CPU.
resumen = procesar_captura_uart_lab9(rutaTemporal, 2);
assert(resumen.captura_valida && resumen.caso == 2);
assert(isfinite(resumen.tr_ms) && isfinite(resumen.ts_ms));
assert(isfinite(resumen.ts_robusto_ms));
assert(resumen.n_muestras == 600 && resumen.cpu_max_us == 80);

% Prueba negativa: una captura MONITOR no puede poblar la tabla LQR.
lineasMonitor = lineas;
lineasMonitor(1) = replace(lineasMonitor(1), "modo=LQR", "modo=MONITOR");
writelines(lineasMonitor, rutaTemporal, Encoding="UTF-8");
rechazoMonitor = false;
try
    procesar_captura_uart_lab9(rutaTemporal, 2);
catch
    rechazoMonitor = true;
end
assert(rechazoMonitor, "El importador debe rechazar capturas MONITOR.");

% Prueba negativa: cualquier bandera fatal invalida toda la captura.
datos.flags(100) = 1;
lineasConFalla = [lineas(1:2); join(string(datos.Variables),",",2)];
writelines(lineasConFalla, rutaTemporal, Encoding="UTF-8");
rechazoFalla = false;
try
    procesar_captura_uart_lab9(rutaTemporal, 2);
catch
    rechazoFalla = true;
end
assert(rechazoFalla, "El importador debe rechazar banderas fatales.");
fprintf("Importador experimental verificado con archivo temporal.\n");

function eliminarTemporal(ruta)
    if isfile(ruta)
        delete(ruta);
    end
end
