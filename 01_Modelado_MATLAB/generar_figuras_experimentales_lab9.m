% GENERAR_FIGURAS_EXPERIMENTALES_LAB9 Grafica las capturas fisicas del Lab9.
% Este script carga los tres registros UART validados, comprueba que las
% variables necesarias esten presentes y exporta las figuras a
% 300 dpi. Las rutas se resuelven desde este archivo, por lo que no depende
% de la carpeta activa de MATLAB.

clearvars;

% Se definen rutas portables dentro del arbol del laboratorio. La carpeta de
% salida se crea si todavia no existe para permitir una ejecucion limpia.
carpetaScript = fileparts(mfilename("fullpath"));
carpetaCapturas = fullfile(carpetaScript, "..", "04_Ensayos", "capturas");
carpetaFiguras = fullfile(carpetaScript, "..", "05_Resultados", "figuras");
if ~isfolder(carpetaFiguras)
    mkdir(carpetaFiguras);
end

% Los colores se fijan para que un mismo caso conserve su identidad visual
% en la respuesta y en el esfuerzo de control. Se usan tonos distinguibles
% tanto en pantalla como en una impresion a color.
casos = 1:3;
colores = [0.0000, 0.4470, 0.7410; ...
           0.8500, 0.3250, 0.0980; ...
           0.4660, 0.6740, 0.1880];
datos = cell(numel(casos), 1);

% La importacion ignora las lineas de metadatos iniciadas con '#'. Antes de
% usar cada tabla se verifica el conjunto minimo de senales; asi, una captura
% incompleta genera un error explicito en vez de una grafica enganosa.
variablesRequeridas = ["t_us", "r_mV", "y_rel_mV", "u_nominal_mV"];
for indice = 1:numel(casos)
    caso = casos(indice);
    archivo = fullfile(carpetaCapturas, "caso_"+caso+"_uart.csv");
    assert(isfile(archivo), "LAB9:CapturaAusente", ...
        "No se encontro la captura experimental del caso %d.", caso);

    opciones = detectImportOptions(archivo, "Delimiter", ",", ...
        "CommentStyle", "#", "VariableNamingRule", "preserve");
    opciones.MissingRule = "error";
    opciones.ImportErrorRule = "error";
    tabla = readtable(archivo, opciones);

    variablesAusentes = setdiff(variablesRequeridas, ...
        string(tabla.Properties.VariableNames));
    assert(isempty(variablesAusentes), "LAB9:ColumnasAusentes", ...
        "Caso %d: faltan columnas UART: %s.", caso, ...
        strjoin(variablesAusentes, ", "));
    assert(height(tabla) >= 500, "LAB9:CapturaCorta", ...
        "Caso %d: la captura contiene solo %d muestras.", caso, height(tabla));

    % El tiempo transmitido en microsegundos se expresa en milisegundos para
    % relacionarlo directamente con las metricas dinamicas del informe.
    tabla.t_ms = tabla.t_us/1000;
    datos{indice} = tabla;
end

% Figura 1: respuesta fisica. La referencia se dibuja una sola vez porque es
% comun a los tres ensayos. La salida corresponde a y_rel_mV, es decir, a la
% tension calibrada despues de retirar el offset medido al inicio del ensayo.
figuraRespuesta = figure("Visible", "off", "Color", "w", ...
    "Position", [100, 100, 980, 520]);
ejeRespuesta = axes(figuraRespuesta);
hold(ejeRespuesta, "on");
plot(ejeRespuesta, datos{1}.t_ms, datos{1}.r_mV, "k--", ...
    "LineWidth", 1.6, "DisplayName", "Referencia");
for indice = 1:numel(casos)
    plot(ejeRespuesta, datos{indice}.t_ms, datos{indice}.y_rel_mV, ...
        "Color", colores(indice, :), "LineWidth", 1.25, ...
        "DisplayName", "Caso "+casos(indice));
end
grid(ejeRespuesta, "on");
box(ejeRespuesta, "on");
xlabel(ejeRespuesta, "Tiempo [ms]");
ylabel(ejeRespuesta, "Salida relativa [mV]");
title(ejeRespuesta, "Respuesta experimental de los controladores LQR");
legend(ejeRespuesta, "Location", "best");
xlim(ejeRespuesta, [0, max(datos{1}.t_ms)]);
exportgraphics(ejeRespuesta, ...
    fullfile(carpetaFiguras, "respuesta_experimental_lab9.png"), ...
    "Resolution", 300);
close(figuraRespuesta);

% Figura 2: esfuerzo de control. Se grafica u_nominal_mV, que es el mando
% bipolar realmente representable por el par de DAC despues de cuantizar. Las
% lineas discontinuas indican los limites medidos disponibles del actuador.
figuraMando = figure("Visible", "off", "Color", "w", ...
    "Position", [100, 100, 980, 520]);
ejeMando = axes(figuraMando);
hold(ejeMando, "on");
for indice = 1:numel(casos)
    plot(ejeMando, datos{indice}.t_ms, datos{indice}.u_nominal_mV, ...
        "Color", colores(indice, :), "LineWidth", 1.15, ...
        "DisplayName", "Caso "+casos(indice));
end
yline(ejeMando, 107, "k--", "Limite positivo", ...
    "LabelHorizontalAlignment", "left", "HandleVisibility", "off");
yline(ejeMando, -115, "k--", "Limite negativo", ...
    "LabelHorizontalAlignment", "left", "HandleVisibility", "off");
grid(ejeMando, "on");
box(ejeMando, "on");
xlabel(ejeMando, "Tiempo [ms]");
ylabel(ejeMando, "Mando cuantizado [mV]");
title(ejeMando, "Esfuerzo de control experimental");
legend(ejeMando, "Location", "best");
xlim(ejeMando, [0, max(datos{1}.t_ms)]);
ylim(ejeMando, [-125, 117]);
exportgraphics(ejeMando, ...
    fullfile(carpetaFiguras, "mando_experimental_lab9.png"), ...
    "Resolution", 300);
close(figuraMando);

fprintf("Figuras experimentales guardadas en: %s\n", carpetaFiguras);
