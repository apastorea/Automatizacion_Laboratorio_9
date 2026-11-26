function resumen = procesar_captura_uart_lab9(rutaCaptura, casoEsperado)
% PROCESAR_CAPTURA_UART_LAB9 Valida una captura UART y calcula sus metricas.

arguments
    rutaCaptura (1,1) string {mustBeFile}
    casoEsperado (1,1) double {mustBeInteger,mustBeMember(casoEsperado,1:3)}
end

lineas = readlines(rutaCaptura, Encoding="UTF-8");
% Las lineas iniciadas en # son metadatos del firmware y no forman parte de
% la tabla. Se usan para impedir mezclar modos o casos distintos.
comentarios = strip(lineas(startsWith(strip(lineas), "#")));
assert(~isempty(comentarios), "La captura no contiene metadatos UART.");
metadatos = join(comentarios, " ");

modo = regexp(metadatos, 'modo=([A-Z_]+)', 'tokens', 'once');
caso = regexp(metadatos, 'caso=([0-9]+)', 'tokens', 'once');
assert(~isempty(modo) && string(modo{1}) == "LQR", ...
    "La captura no corresponde al modo LQR.");
assert(~isempty(caso) && str2double(caso{1}) == casoEsperado, ...
    "El numero de caso de la captura no coincide con el esperado.");

% El importador falla ante ausencias o conversiones invalidas; de esta forma
% una celda corrupta no se transforma silenciosamente en NaN.
opciones = detectImportOptions(rutaCaptura, FileType="text", ...
    Delimiter=",", CommentStyle="#", VariableNamingRule="preserve");
opciones.MissingRule = "error";
opciones.ImportErrorRule = "error";
datos = readtable(rutaCaptura, opciones);

requeridas = ["k","t_us","y_rel_mV","r_mV","u_solicitada_mV", ...
    "u_nominal_mV","cpu_us","intervalo_us","flags"];
assert(all(ismember(requeridas, string(datos.Properties.VariableNames))), ...
    "Faltan variables requeridas en la captura UART.");
assert(height(datos) == 600, ...
    "La captura debe contener exactamente 600 muestras.");
assert(all(isfinite(datos{:,requeridas}), "all"), ...
    "La captura contiene valores no finitos.");

% Integridad temporal: indice consecutivo, tiempo monotono y periodo dentro
% de +/-10 % respecto de Ts=2 ms a partir de la segunda muestra.
datos = sortrows(datos, "k");
assert(isequal(datos.k, (0:height(datos)-1)'), ...
    "La secuencia k debe ser unica y consecutiva desde cero.");
assert(all(diff(datos.t_us) > 0), ...
    "El tiempo acumulado debe ser estrictamente creciente.");
assert(all(abs(datos.intervalo_us(2:end)-2000) <= 200), ...
    "El periodo medido queda fuera de la tolerancia de 2 ms +/- 10%%.");

% Los bits 0..5 corresponden a fallas fatales de ADC, DAC, aritmetica, CPU,
% periodo o salida fuera de rango. Los bits 6 y 7 son eventos no fatales.
banderas = uint8(datos.flags);
assert(~any(bitand(banderas, uint8(63)) ~= 0), ...
    "La captura contiene al menos una bandera fatal.");

% La meseta se detecta desde la propia referencia transmitida para no fijar
% indices experimentales que podrian variar entre versiones del firmware.
enReferencia = datos.r_mV > 0.5*max(datos.r_mV);
inicio = find(enReferencia, 1, "first");
fin = find(~enReferencia & (1:height(datos))' > inicio, 1, "first")-1;
assert(~isempty(inicio) && ~isempty(fin) && fin-inicio >= 100, ...
    "No se encontro una meseta de referencia valida.");

pretrigger = 1:inicio-1;
meseta = inicio:fin;
referencia_mV = median(datos.r_mV(meseta), "omitmissing");
base_mV = mean(datos.y_rel_mV(pretrigger), "omitmissing");
amplitud_mV = referencia_mV-base_mV;
assert(abs(referencia_mV-50) <= 1, ...
    "La referencia experimental debe ser 50 mV +/- 1 mV.");
assert(abs(amplitud_mV) > 1, "La amplitud de referencia no es valida.");

% Tiempo de subida 10--90 %, asentamiento al 2 %, sobreimpulso y error de
% regimen se calculan sobre la salida referida al cero del pretrigger.
progreso = (datos.y_rel_mV(meseta)-base_mV)/amplitud_mV;
i10 = find(progreso >= 0.10, 1, "first");
i90 = find(progreso >= 0.90, 1, "first");
assert(~isempty(i10) && ~isempty(i90) && i90 >= i10, ...
    "No se pudieron determinar los cruces de subida 10-90%%.");
tr_ms = (datos.t_us(meseta(i90))-datos.t_us(meseta(i10)))/1000;

banda_mV = 0.02*abs(referencia_mV);
dentro = abs(datos.y_rel_mV(meseta)-referencia_mV) <= banda_mV;
ultimoFuera = find(~dentro, 1, "last");
if isempty(ultimoFuera)
    ts_ms = 0;
elseif ultimoFuera < numel(meseta)
    ts_ms = (datos.t_us(meseta(ultimoFuera+1))- ...
        datos.t_us(inicio))/1000;
else
    ts_ms = NaN;
end

% Como complemento al criterio estricto, se calcula un establecimiento
% robusto sobre una mediana movil de 11 muestras (22 ms) y una banda del 5 %.
% Esta metrica reduce la sensibilidad a la cuantizacion del ADC sin ocultar
% oscilaciones sostenidas de baja frecuencia.
salidaFiltrada_mV = smoothdata(datos.y_rel_mV(meseta), "movmedian", 11);
bandaRobusta_mV = 0.05*abs(referencia_mV);
dentroRobusto = abs(salidaFiltrada_mV-referencia_mV) <= bandaRobusta_mV;
ultimoFueraRobusto = find(~dentroRobusto, 1, "last");
if isempty(ultimoFueraRobusto)
    ts_robusto_ms = 0;
elseif ultimoFueraRobusto < numel(meseta)
    ts_robusto_ms = (datos.t_us(meseta(ultimoFueraRobusto+1))- ...
        datos.t_us(inicio))/1000;
else
    ts_robusto_ms = NaN;
end

Mp_pct = max(0, 100*(max(datos.y_rel_mV(meseta))- ...
    referencia_mV)/abs(referencia_mV));
ventanaRegimen = max(inicio,fin-49):fin;
errorRegimen_mV = datos.r_mV(ventanaRegimen)- ...
    datos.y_rel_mV(ventanaRegimen);
ess_mV = mean(errorRegimen_mV, "omitmissing");
error_rms_mV = sqrt(mean(errorRegimen_mV.^2, "omitmissing"));
u_min_mV = min(datos.u_nominal_mV, [], "omitmissing");
u_max_mV = max(datos.u_nominal_mV, [], "omitmissing");
% Los contadores permiten relacionar el desempeno con saturacion del mando y
% actuacion del anti-windup condicional.
saturaciones = nnz(bitand(banderas, uint8(64)) ~= 0);
bloqueos_antiwindup = nnz(bitand(banderas, uint8(128)) ~= 0);
periodo_medio_us = mean(datos.intervalo_us(2:end), "omitmissing");
desviacion_periodo_max_us = max(abs(datos.intervalo_us(2:end)-2000), ...
    [], "omitmissing");
cpu_max_us = max(datos.cpu_us, [], "omitmissing");
n_muestras = height(datos);

caso = casoEsperado;
[~, nombreArchivo, extensionArchivo] = fileparts(rutaCaptura);
archivo = nombreArchivo+extensionArchivo;
captura_valida = true;
estado = "valida";
resumen = table(caso, archivo, captura_valida, tr_ms, ts_ms, ...
    ts_robusto_ms, Mp_pct, ess_mV, error_rms_mV, u_min_mV, u_max_mV, saturaciones, ...
    bloqueos_antiwindup, periodo_medio_us, desviacion_periodo_max_us, ...
    cpu_max_us, n_muestras, estado);
end
