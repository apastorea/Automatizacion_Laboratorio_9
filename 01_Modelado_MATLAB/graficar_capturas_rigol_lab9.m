% GRAFICAR_CAPTURAS_RIGOL_LAB9 Recrea las trazas RIGOL desde sus CSV.
% La visualizacion conserva cada muestra fisica sin filtrado, interpolacion,
% normalizacion ni cambio de amplitud. La mayor legibilidad se obtiene solo
% asignando a cada canal limites verticales acordes con su intervalo medido.
% El script genera solamente la comparacion principal de los tres casos; las
% adquisiciones diagnosticas se conservan como evidencia cruda y no forman
% parte de los resultados presentados en el informe.

clearvars;

% Todas las rutas se calculan desde la ubicacion del script. De este modo, el
% resultado no dependa de la carpeta desde la cual se inicia MATLAB.
carpetaModelo = fileparts(mfilename("fullpath"));
carpetaCapturas = fullfile(carpetaModelo, "..", "04_Ensayos", "capturas");
carpetaResultados = fullfile(carpetaModelo, "..", "05_Resultados");

% Los nombres esperados permiten detectar inmediatamente una exportacion
% incompleta o un CSV que no corresponda a la adquisicion de dos canales.
variablesEsperadas = ["t_s" "ch1_mando_V" "ch2_salida_V"];

%% Comparacion de las tres adquisiciones principales

% Se usa una malla de tres filas por dos columnas: cada fila representa un
% controlador y cada columna conserva la identidad electrica del canal.
figComparacion = figure(Color="white", Position=[80 60 1350 900]);
distribucion = tiledlayout(figComparacion, 3, 2, ...
    TileSpacing="compact", Padding="compact");
title(distribucion, ...
    "Trazas RIGOL reconstruidas desde los CSV fisicos (sin filtrado)", ...
    FontWeight="bold");
xlabel(distribucion, "Tiempo respecto del disparo [s]");

for caso = 1:3
    rutaCSV = fullfile(carpetaCapturas, ...
        "rigol_caso_"+caso+"_dos_canales_lab9.csv");
    captura = leerYValidarCaptura(rutaCSV, variablesEsperadas);

    % Se convierten voltios a milivoltios solo para presentar unidades mas
    % naturales en el rango de trabajo; esta operacion no altera la forma.
    tiempo_s = captura.t_s;
    mando_mV = 1e3*captura.ch1_mando_V;
    salida_mV = 1e3*captura.ch2_salida_V;

    % CH1 usa un eje propio. Los limites se calculan desde minimos y maximos
    % del CSV y agregan un margen de 8 % para evitar que la traza toque el marco.
    axMando = nexttile(distribucion);
    plot(axMando, tiempo_s, mando_mV, Color=[0.90 0.55 0.00], ...
        LineWidth=0.75);
    configurarEje(axMando, limitesConMargen(mando_mV));
    ylabel(axMando, "CH1/J5: mando [mV]");
    title(axMando, sprintf("Caso %d — mando J5", caso));
    xline(axMando, 0, ":", "Disparo", Color=[0.35 0.35 0.35], ...
        LabelVerticalAlignment="bottom");
    escribirEstadisticas(axMando, mando_mV);

    % CH2 se dibuja en otro eje para que una excursion diferente de mando no
    % comprima visualmente la salida. Tampoco se comparten limites verticales.
    axSalida = nexttile(distribucion);
    plot(axSalida, tiempo_s, salida_mV, Color=[0.00 0.55 0.65], ...
        LineWidth=0.75);
    configurarEje(axSalida, limitesConMargen(salida_mV));
    ylabel(axSalida, "CH2/J7: salida [mV]");
    title(axSalida, sprintf("Caso %d — salida J7", caso));
    xline(axSalida, 0, ":", "Disparo", Color=[0.35 0.35 0.35], ...
        LabelVerticalAlignment="bottom");
    escribirEstadisticas(axSalida, salida_mV);
end

% La salida PNG es adecuada para el informe. Tambien se conserva un PDF
% vectorial para ampliaciones sin perdida de los ejes, textos y trazas.
rutaComparacionPNG = fullfile(carpetaResultados, ...
    "rigol_casos_ampliados_desde_csv_lab9.png");
rutaComparacionPDF = fullfile(carpetaResultados, ...
    "rigol_casos_ampliados_desde_csv_lab9.pdf");
exportgraphics(figComparacion, rutaComparacionPNG, Resolution=300);
exportgraphics(figComparacion, rutaComparacionPDF, ContentType="vector");
close(figComparacion);

fprintf("Graficas RIGOL recreadas sin modificar las muestras:\n");
fprintf("  %s\n", rutaComparacionPNG);
fprintf("  %s\n", rutaComparacionPDF);

%% Funciones locales

function captura = leerYValidarCaptura(rutaCSV, variablesEsperadas)
% LEERYVALIDARCAPTURA Importa un CSV y comprueba estructura y base temporal.
    assert(isfile(rutaCSV), "LAB9:RIGOL:CSVFaltante", ...
        "No se encontro el archivo %s.", rutaCSV);
    captura = readtable(rutaCSV, TextType="string", ...
        VariableNamingRule="preserve");
    assert(all(ismember(variablesEsperadas, ...
        string(captura.Properties.VariableNames))), ...
        "LAB9:RIGOL:Columnas", ...
        "El CSV %s no contiene las tres variables esperadas.", rutaCSV);
    assert(height(captura) >= 2, "LAB9:RIGOL:Muestras", ...
        "El CSV %s no posee suficientes muestras.", rutaCSV);
    assert(issorted(captura.t_s, "strictascend"), ...
        "LAB9:RIGOL:Tiempo", ...
        "La base temporal de %s no es estrictamente creciente.", rutaCSV);
    assert(~anymissing(captura(:, variablesEsperadas)), ...
        "LAB9:RIGOL:Faltantes", ...
        "El CSV %s contiene muestras faltantes.", rutaCSV);
end

function limites = limitesConMargen(senal_mV)
% LIMITESCONMARGEN Produce limites visibles sin modificar los datos medidos.
    minimo = min(senal_mV, [], "omitmissing");
    maximo = max(senal_mV, [], "omitmissing");
    amplitud = maximo-minimo;

    % Para una traza exactamente constante se usa un margen minimo de 0.5 mV;
    % esto evita que MATLAB genere limites degenerados o artificialmente enormes.
    margen = max(0.08*amplitud, 0.5);
    limites = [minimo-margen maximo+margen];
end

function configurarEje(ax, limitesY)
% CONFIGURAREJE Aplica una presentacion tecnica comun a todos los paneles.
    grid(ax, "on");
    ax.GridLineStyle = ":";
    ax.GridAlpha = 0.28;
    ax.Box = "on";
    ax.FontName = "Arial";
    ax.FontSize = 9;
    ax.Layer = "top";
    ax.YAxis.Exponent = 0;
    ylim(ax, limitesY);
end

function escribirEstadisticas(ax, senal_mV)
% ESCRIBIRESTADISTICAS Anota limites y pico a pico obtenidos del mismo CSV.
    minimo = min(senal_mV, [], "omitmissing");
    maximo = max(senal_mV, [], "omitmissing");
    picoPico = maximo-minimo;
    etiqueta = sprintf("min = %.2f mV   max = %.2f mV   Vpp = %.2f mV", ...
        minimo, maximo, picoPico);
    text(ax, 0.01, 0.95, etiqueta, Units="normalized", ...
        VerticalAlignment="top", FontSize=8, BackgroundColor="white");
end
