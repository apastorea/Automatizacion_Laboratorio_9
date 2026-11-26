% ACTUALIZAR_RESULTADOS_EXPERIMENTALES_LAB9 Procesa capturas UART disponibles.

clearvars;

% Las rutas se construyen desde la ubicacion del propio script para que el
% procesamiento funcione aunque MATLAB se inicie en otra carpeta.
carpetaModelo = fileparts(mfilename("fullpath"));
carpetaCapturas = fullfile(carpetaModelo, "..", "04_Ensayos", "capturas");
carpetaResultados = fullfile(carpetaModelo, "..", "05_Resultados");
resumenExperimental = table();

% Cada caso se procesa de forma independiente: una captura ausente o invalida
% queda trazada como pendiente sin borrar resultados validos de otros casos.
for caso = 1:3
    ruta = fullfile(carpetaCapturas, "caso_"+caso+"_uart.csv");
    if isfile(ruta)
        try
            fila = procesar_captura_uart_lab9(ruta, caso);
        catch excepcion
            fila = filaPendiente(caso, ruta, ...
                "rechazada: "+string(excepcion.message));
            warning("LAB9:CapturaRechazada", ...
                "Caso %d rechazado: %s", caso, excepcion.message);
        end
    else
        fila = filaPendiente(caso, ruta, "pendiente de captura");
    end
    resumenExperimental = [resumenExperimental; fila]; %#ok<AGROW>
end

rutaSalida = fullfile(carpetaResultados, "resumen_experimental_lab9.csv");
writetable(resumenExperimental, rutaSalida);
disp(resumenExperimental);
fprintf("Resumen experimental guardado en: %s\n", rutaSalida);

generar_tabla_comparativa_lab9;

% Una vez validadas y resumidas las capturas, se regeneran tambien las
% figuras de respuesta y esfuerzo. De este modo, las tablas y los graficos
% publicados siempre proceden del mismo conjunto de archivos UART.
generar_figuras_experimentales_lab9;

function fila = filaPendiente(caso, ruta, estado)
    % Se conserva el mismo esquema de columnas que una medicion valida. Los
    % NaN impiden confundir datos aun no medidos con ceros experimentales.
    [~, nombreArchivo, extensionArchivo] = fileparts(ruta);
    archivo = nombreArchivo+extensionArchivo;
    captura_valida = false;
    tr_ms = NaN;
    ts_ms = NaN;
    ts_robusto_ms = NaN;
    Mp_pct = NaN;
    ess_mV = NaN;
    error_rms_mV = NaN;
    u_min_mV = NaN;
    u_max_mV = NaN;
    saturaciones = NaN;
    bloqueos_antiwindup = NaN;
    periodo_medio_us = NaN;
    desviacion_periodo_max_us = NaN;
    cpu_max_us = NaN;
    n_muestras = NaN;
    fila = table(caso, archivo, captura_valida, tr_ms, ts_ms, ...
        ts_robusto_ms, Mp_pct, ...
        ess_mV, error_rms_mV, u_min_mV, u_max_mV, saturaciones, ...
        bloqueos_antiwindup, periodo_medio_us, ...
        desviacion_periodo_max_us, cpu_max_us, n_muestras, string(estado), ...
        VariableNames=["caso","archivo","captura_valida","tr_ms", ...
        "ts_ms","ts_robusto_ms","Mp_pct","ess_mV","error_rms_mV","u_min_mV", ...
        "u_max_mV","saturaciones","bloqueos_antiwindup", ...
        "periodo_medio_us","desviacion_periodo_max_us","cpu_max_us", ...
        "n_muestras","estado"]);
end
