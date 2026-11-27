% PROCESAR_CAPTURAS_RIGOL_LAB9 Analiza los ensayos fisicos a 500 mV.
%
% CH1 corresponde al mando fisico medido en J5 y CH2 a la salida de planta
% medida en J7. La rutina elimina el nivel de reposo, alinea cada ensayo con
% el comienzo del mando y calcula las mismas magnitudes usadas en el diseno:
% tiempo de subida 10--90 %, establecimiento al 2 %, sobreimpulso, error de
% regimen y extremos de la accion de control. Los resultados se comparan con
% el calculo continuo/ideal y con la simulacion que incluye el DAC cuantizado.

clearvars;

carpetaModelo = fileparts(mfilename("fullpath"));
carpetaCapturas = fullfile(carpetaModelo, "..", "04_Ensayos", "capturas");
carpetaResultados = fullfile(carpetaModelo, "..", "05_Resultados");
carpetaFiguras = fullfile(carpetaResultados, "figuras");
if ~isfolder(carpetaFiguras), mkdir(carpetaFiguras); end

referencia_V = 0.500;
duracionReferencia_s = (333-32)*0.002; % 301 periodos de 2 ms.
resumenRIGOL = table();

% Figura recreada desde los CSV del osciloscopio. Se conserva la resolucion
% de adquisicion y solo se suaviza CH2 para calcular metricas robustas; en la
% grafica se muestra tambien la señal medida sin ocultar su dispersion.
fig = figure(Color="w", Position=[80 80 1180 780]);
tiledlayout(3, 2, TileSpacing="compact", Padding="compact");

for caso = 1:3
    rutaCSV = fullfile(carpetaCapturas, ...
        "rigol_caso_"+caso+"_dos_canales_lab9.csv");
    rutaJSON = fullfile(carpetaCapturas, ...
        "rigol_caso_"+caso+"_metadatos_lab9.json");
    assert(isfile(rutaCSV) && isfile(rutaJSON), ...
        "LAB9:RIGOL:Faltante", "Falta la captura fisica del caso %d.", caso);

    captura = readtable(rutaCSV, VariableNamingRule="preserve");
    meta = jsondecode(fileread(rutaJSON));
    assert(meta.disparoDetectado && height(captura) == 1200, ...
        "LAB9:RIGOL:CapturaInvalida", ...
        "La captura del caso %d no tiene un disparo valido y 1200 muestras.", caso);

    t = captura.t_s;
    u = captura.ch1_mando_V;
    y = captura.ch2_salida_V;

    % El inicio se detecta en CH1, usando tres muestras consecutivas por
    % encima de 20 mV. El umbral supera el ruido de reposo y antecede al
    % disparo de hardware de 50 mV, por lo que no sesga el tiempo de subida.
    % El origen temporal SCPI no coincide necesariamente con el disparo;
    % por eso el cero global se toma del primer 10 % del registro, que en
    % modo SINGLE siempre pertenece al pretrigger.
    nBase = max(20, floor(0.10*numel(u)));
    u0Global = mean(u(1:nBase), "omitmissing");
    candidato = movsum(abs(u-u0Global) >= 0.020, [0 2]) == 3;
    iInicio = find(candidato, 1, "first");
    assert(~isempty(iInicio), "LAB9:RIGOL:SinMando", ...
        "No se detecto el comienzo del mando en el caso %d.", caso);
    iInicio = max(1, iInicio-2);
    tInicio = t(iInicio);
    tRel = t-tInicio;

    % El nivel de reposo se estima inmediatamente antes del ensayo. La
    % duracion de referencia procede del firmware y evita confundir con la
    % descarga posterior el calculo del error estacionario.
    pre = tRel >= -0.20 & tRel <= -0.04;
    u0 = mean(u(pre), "omitmissing");
    y0 = mean(y(pre), "omitmissing");
    uRel = u-u0;
    yRel = y-y0;
    yFiltrada = movmean(yRel, 7, "omitmissing");
    meseta = tRel >= 0 & tRel <= duracionReferencia_s;
    regimen = tRel >= duracionReferencia_s-0.080 & ...
        tRel <= duracionReferencia_s-0.020;

    % Tiempo de subida respecto de la referencia de 500 mV.
    i10 = find(meseta & yFiltrada >= 0.10*referencia_V, 1, "first");
    i90 = find(meseta & yFiltrada >= 0.90*referencia_V, 1, "first");
    assert(~isempty(i10) && ~isempty(i90) && i90 >= i10, ...
        "LAB9:RIGOL:Subida", "No se pudo medir la subida del caso %d.", caso);
    tr_ms = 1e3*(t(i90)-t(i10));

    % Establecimiento: primera muestra a partir de la cual la salida filtrada
    % permanece dentro de ±2 % hasta 20 ms antes de retirar la referencia.
    banda = 0.02*referencia_V;
    indicesMeseta = find(tRel >= 0 & tRel <= duracionReferencia_s-0.020);
    fuera = abs(yFiltrada(indicesMeseta)-referencia_V) > banda;
    ultimoFuera = find(fuera, 1, "last");
    establecio_2pct = true;
    if isempty(ultimoFuera)
        ts_ms = 0;
    elseif ultimoFuera < numel(indicesMeseta)
        ts_ms = 1e3*tRel(indicesMeseta(ultimoFuera+1));
    else
        % No se reemplaza por cero ni por un guion: se informa el limite
        % inferior observable y una bandera que explicita que no se alcanzo.
        ts_ms = 1e3*duracionReferencia_s;
        establecio_2pct = false;
    end

    pico_V = max(yFiltrada(meseta), [], "omitmissing");
    Mp_pct = max(0, 100*(pico_V-referencia_V)/referencia_V);
    yRegimen_V = mean(yFiltrada(regimen), "omitmissing");
    ess_mV = 1e3*(referencia_V-yRegimen_V);
    ventanaMando = tRel >= 0 & tRel <= duracionReferencia_s+0.20;
    u_min_mV = 1e3*min(uRel(ventanaMando), [], "omitmissing");
    u_max_mV = 1e3*max(uRel(ventanaMando), [], "omitmissing");
    paso_medio_ms = 1e3*mean(diff(t));

    fila = table(caso, height(captura), paso_medio_ms, tr_ms, ts_ms, ...
        Mp_pct, ess_mV, u_min_mV, u_max_mV, y0*1e3, ...
        establecio_2pct, string(meta.instrumento), ...
        logical(meta.disparoDetectado), ...
        VariableNames=["caso" "muestras" "paso_medio_ms" "tr_ms" ...
        "ts_ms" "Mp_pct" "ess_mV" "u_min_mV" "u_max_mV" ...
        "offset_salida_mV" "establecio_2pct" "instrumento" ...
        "disparo_detectado"]);
    resumenRIGOL = [resumenRIGOL; fila]; %#ok<AGROW>

    nexttile(2*caso-1);
    plot(1e3*tRel, 1e3*yRel, Color=[0.72 0.78 0.86], LineWidth=0.7); hold on;
    plot(1e3*tRel, 1e3*yFiltrada, Color=[0 0.32 0.62], LineWidth=1.7);
    yline(500, "--", Color=[0.75 0.16 0.12], LineWidth=1.2);
    xline(0, ":k"); xline(1e3*duracionReferencia_s, ":k");
    xlim([-80 760]); ylim([-60 590]); grid on;
    ylabel("Salida J7 (mV)"); title("Caso "+caso+": seguimiento");
    if caso == 3, xlabel("Tiempo desde el escalon (ms)"); end
    legend("Medida", "Media movil (7)", "Referencia", ...
        Location="southeast", FontSize=7);

    nexttile(2*caso);
    plot(1e3*tRel, 1e3*uRel, Color=[0.08 0.08 0.08], LineWidth=1.2);
    xline(0, ":k"); xline(1e3*duracionReferencia_s, ":k");
    yline(1000, "--", Color=[0.75 0.16 0.12]);
    yline(-1000, "--", Color=[0.75 0.16 0.12]);
    xlim([-80 760]); ylim([-300 800]); grid on;
    ylabel("Mando J5 (mV)"); title("Caso "+caso+": accion de control");
    if caso == 3, xlabel("Tiempo desde el escalon (ms)"); end
end

exportgraphics(fig, fullfile(carpetaFiguras, ...
    "respuesta_experimental_rigol_lab9.png"), Resolution=220);
exportgraphics(fig, fullfile(carpetaFiguras, ...
    "respuesta_experimental_rigol_lab9.pdf"), ContentType="vector");
close(fig);

writetable(resumenRIGOL, fullfile(carpetaResultados, ...
    "resumen_rigol_lab9.csv"));

% Tabla comparativa: "calculado" usa el modelo identificado y actuador ideal
% limitado; "simulado" incorpora cuantizacion y asimetria de los DAC; la
% tercera fuente procede exclusivamente de los CSV recién adquiridos.
sim = readtable(fullfile(carpetaResultados, "resumen_simulacion_lab9.csv"), ...
    TextType="string");
tablaComparativa = table();
metricas = ["tr_ms" "ts_ms" "Mp_pct" "ess_mV" "u_min_mV" "u_max_mV"];
unidades = ["ms" "ms" "%" "mV" "mV" "mV"];
for caso = 1:3
    ideal = sim(sim.caso == caso & sim.planta == "identificada" & ...
        sim.actuador == "ideal_limitado", :);
    dac = sim(sim.caso == caso & sim.planta == "identificada" & ...
        sim.actuador == "dac_cuantizado", :);
    med = resumenRIGOL(resumenRIGOL.caso == caso, :);
    for j = 1:numel(metricas)
        nombre = metricas(j);
        fila = table(caso, nombre, unidades(j), ideal.(nombre), ...
            dac.(nombre), med.(nombre), ...
            VariableNames=["caso" "parametro" "unidad" ...
            "calculado" "simulado" "medido"]);
        tablaComparativa = [tablaComparativa; fila]; %#ok<AGROW>
    end
end
writetable(tablaComparativa, fullfile(carpetaResultados, ...
    "tabla_calculado_simulado_medido_lab9.csv"));

disp(resumenRIGOL);
disp(tablaComparativa);
fprintf("Capturas fisicas procesadas y tabla comparativa actualizada.\n");
