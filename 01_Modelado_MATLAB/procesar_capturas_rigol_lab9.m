% PROCESAR_CAPTURAS_RIGOL_LAB9 Resume las adquisiciones fisicas del RIGOL.
% La rutina calcula magnitudes observables directamente en los dos canales.
% No estima tiempos de subida o establecimiento cuando la amplitud capturada
% no permite identificar de forma confiable el pulso de referencia de 50 mV.

clearvars;

% Las rutas se construyen desde este archivo para que el analisis no dependa
% de la carpeta activa desde la cual se haya iniciado MATLAB.
carpetaModelo = fileparts(mfilename("fullpath"));
carpetaCapturas = fullfile(carpetaModelo, "..", "04_Ensayos", "capturas");
carpetaResultados = fullfile(carpetaModelo, "..", "05_Resultados");

% Se preasigna una tabla vacia. Cada renglon posterior representa una
% adquisicion fisica completa: 1200 muestras de CH1 y 1200 muestras de CH2.
resumenRIGOL = table();

for caso = 1:3
    % El CSV contiene la escala temporal reconstruida a partir del preambulo
    % SCPI y las tensiones ya convertidas a voltios para ambos canales.
    rutaCSV = fullfile(carpetaCapturas, ...
        "rigol_caso_"+caso+"_dos_canales_lab9.csv");
    rutaJSON = fullfile(carpetaCapturas, ...
        "rigol_caso_"+caso+"_metadatos_lab9.json");
    assert(isfile(rutaCSV), "LAB9:RIGOL:CSVFaltante", ...
        "No se encontro la captura del caso %d.", caso);
    assert(isfile(rutaJSON), "LAB9:RIGOL:MetadatosFaltantes", ...
        "No se encontraron los metadatos del caso %d.", caso);

    captura = readtable(rutaCSV, TextType="string", ...
        VariableNamingRule="preserve");
    metadatos = jsondecode(fileread(rutaJSON));

    % La validacion estructural evita resumir archivos truncados, desordenados
    % o con nombres de variables que no corresponden al ensayo de dos canales.
    variablesEsperadas = ["t_s" "ch1_mando_V" "ch2_salida_V"];
    assert(all(ismember(variablesEsperadas, ...
        string(captura.Properties.VariableNames))), ...
        "LAB9:RIGOL:Columnas", "Columnas incompletas en el caso %d.", caso);
    assert(height(captura) == metadatos.muestrasScope, ...
        "LAB9:RIGOL:Longitud", ...
        "El numero de muestras no coincide con los metadatos del caso %d.", ...
        caso);
    assert(issorted(captura.t_s, "strictascend"), ...
        "LAB9:RIGOL:Tiempo", ...
        "La base temporal del caso %d no es estrictamente creciente.", caso);

    % Se obtiene el paso medio real de la base temporal en lugar de asumir el
    % valor nominal configurado en el osciloscopio.
    pasoMedio_ms = 1e3*mean(diff(captura.t_s), "omitmissing");

    % CH1 mide en J5 el mando físico aplicado a la planta. Se publican
    % límites, pico a pico, valor eficaz y dispersión en milivoltios.
    ch1 = captura.ch1_mando_V;
    ch1Min_mV = 1e3*min(ch1, [], "omitmissing");
    ch1Max_mV = 1e3*max(ch1, [], "omitmissing");
    ch1Vpp_mV = ch1Max_mV-ch1Min_mV;
    ch1RMS_mV = 1e3*sqrt(mean(ch1.^2, "omitmissing"));
    ch1Desv_mV = 1e3*std(ch1, 0, "omitmissing");

    % CH2 mide en J7 la salida física de la planta y se procesa con las mismas
    % definiciones para permitir una comparación directa entre casos.
    ch2 = captura.ch2_salida_V;
    ch2Min_mV = 1e3*min(ch2, [], "omitmissing");
    ch2Max_mV = 1e3*max(ch2, [], "omitmissing");
    ch2Vpp_mV = ch2Max_mV-ch2Min_mV;
    ch2RMS_mV = 1e3*sqrt(mean(ch2.^2, "omitmissing"));
    ch2Desv_mV = 1e3*std(ch2, 0, "omitmissing");

    % La dinámica se considera evaluable únicamente cuando J7 alcanza una
    % meseta identificable de 50 mV.
    % Por ello no se calculan de esta fuente tiempos transitorios: hacerlo
    % confundiria excursion de ruido con respuesta de la planta. Las metricas
    % dinamicas del informe proceden de los registros UART validados.
    % Se exige que el maximo de CH2 alcance al menos el 80 % de la meseta
    % esperada. El pico a pico no se usa para este criterio porque sumaria
    % excursiones de ruido positivas y negativas como si fueran una respuesta.
    dinamicaEvaluable = ch2Max_mV >= 0.8*50;
    if dinamicaEvaluable
        evaluacion = "amplitud suficiente; requiere sincronizacion temporal";
    else
        evaluacion = ...
            "no evaluable dinamicamente: amplitud insuficiente en J7/CH2";
    end

    % El JSON registra si UART y osciloscopio pertenecen a la misma ejecucion.
    % En estas tres adquisiciones el osciloscopio es real, pero el puerto COM
    % no entrego una nueva trama; por eso no se afirma sincronizacion conjunta.
    uartSincronizada = logical(metadatos.uartSincronizada);
    instrumento = string(metadatos.instrumento);
    muestras = height(captura);
    tInicio_s = captura.t_s(1);
    tFin_s = captura.t_s(end);

    fila = table(caso, muestras, tInicio_s, tFin_s, pasoMedio_ms, ...
        ch1Min_mV, ch1Max_mV, ch1Vpp_mV, ch1RMS_mV, ch1Desv_mV, ...
        ch2Min_mV, ch2Max_mV, ch2Vpp_mV, ch2RMS_mV, ch2Desv_mV, ...
        uartSincronizada, dinamicaEvaluable, instrumento, evaluacion, ...
        VariableNames=["caso" "muestras" "t_inicio_s" "t_fin_s" ...
        "paso_medio_ms" "ch1_min_mV" "ch1_max_mV" "ch1_vpp_mV" ...
        "ch1_rms_mV" "ch1_desv_mV" "ch2_min_mV" "ch2_max_mV" ...
        "ch2_vpp_mV" "ch2_rms_mV" "ch2_desv_mV" ...
        "uart_sincronizada" "dinamica_evaluable" "instrumento" ...
        "evaluacion"]);
    resumenRIGOL = [resumenRIGOL; fila]; %#ok<AGROW>
end

% El CSV conserva los datos empleados en la tabla de instrumentacion.
rutaSalida = fullfile(carpetaResultados, "resumen_rigol_lab9.csv");
writetable(resumenRIGOL, rutaSalida);
disp(resumenRIGOL);
fprintf("Resumen RIGOL guardado en: %s\n", rutaSalida);
