% GENERAR_TABLA_COMPARATIVA_LAB9 Integra calculo, simulacion y experimento.
% Los campos experimentales se dejan como NaN hasta disponer de mediciones;
% un cero se reserva para una magnitud fisicamente nula.

clearvars;

% Se leen por separado los resultados de diseno, simulacion y experimento.
% Si falta una medicion, el campo correspondiente se conserva como NaN.
carpetaModelo = fileparts(mfilename("fullpath"));
rutaResultados = fullfile(carpetaModelo, "..", "05_Resultados");
rutaSimulacion = fullfile(rutaResultados, "resumen_simulacion_lab9.csv");
rutaDiseno = fullfile(rutaResultados, "resumen_diseno_lqr_lab9.csv");
rutaExperimental = fullfile(rutaResultados, "resumen_experimental_lab9.csv");
simulacion = readtable(rutaSimulacion, "TextType", "string", ...
    "VariableNamingRule", "preserve");
diseno = readtable(rutaDiseno, "TextType", "string", ...
    "VariableNamingRule", "preserve");
if isfile(rutaExperimental)
    experimental = readtable(rutaExperimental, "TextType", "string", ...
        "VariableNamingRule", "preserve");
else
    experimental = table();
end

% El bloque calculado se obtiene nuevamente desde el modelo identificado; no
% se copia desde los CSV para conservar una verificacion independiente.
Ts = 0.002;
R5 = 150e3;
R6 = 47e3;
gananciaIdentificada = 1.002941;
tau1Identificada = 0.00906915;
tau2Identificada = 0.000774399;
gananciaEtapa1 = R5/R6;
gananciaEtapa2 = gananciaIdentificada/gananciaEtapa1;
Fidentificada = [-1/tau1Identificada, 0; ...
    -gananciaEtapa2/tau2Identificada, -1/tau2Identificada];
Gidentificada = [-gananciaEtapa1/tau1Identificada; 0];
C = [0, 1];
sistemaIdentificado = c2d(ss(Fidentificada, Gidentificada, C, 0), ...
    Ts, "zoh");
[A, B, ~, ~] = ssdata(sistemaIdentificado);
Aumentada = [A, zeros(2, 1); -C, 1];
Bumentada = [B; 0];

caso = repelem((1:3)', 3);
origen = repmat(["calculado"; "simulado"; "experimental"], 3, 1);
tr_ms = nan(9, 1);
ts_ms = nan(9, 1);
ts_robusto_ms = nan(9, 1);
Mp_pct = nan(9, 1);
ess_mV = nan(9, 1);
u_min_mV = nan(9, 1);
u_max_mV = nan(9, 1);
radio_espectral = nan(9, 1);
estado = strings(9, 1);

for indiceCaso = 1:3
    filaCalculada = 3*indiceCaso-2;
    filaSimulada = filaCalculada+1;
    filaExperimental = filaCalculada+2;

    filaDiseno = diseno.caso == indiceCaso;
    assert(nnz(filaDiseno) == 1, "No se encontro el diseno requerido.");
    K = [diseno.Kx1(filaDiseno), diseno.Kx2(filaDiseno), ...
        diseno.Ki(filaDiseno)];
    polos = eig(Aumentada-Bumentada*K);
    [~, indiceDominante] = max(abs(polos));
    poloDominante = polos(indiceDominante);
    radio = abs(poloDominante);
    tau = -Ts/log(radio);
    tr_ms(filaCalculada) = 1000*2.2*tau;
    ts_ms(filaCalculada) = 1000*4*tau;
    % Aproximación analítica al establecimiento en banda del 5 % para el
    % modo dominante: tres constantes de tiempo. Esta columna complementa,
    % pero no reemplaza, el criterio estricto del 2 %.
    ts_robusto_ms(filaCalculada) = 1000*3*tau;
    poloContinuo = log(poloDominante)/Ts;
    zeta = -real(poloContinuo)/abs(poloContinuo);
    if abs(imag(poloDominante)) > eps && zeta < 1
        Mp_pct(filaCalculada) = 100*exp(-pi*zeta/sqrt(1-zeta^2));
    else
        Mp_pct(filaCalculada) = 0;
    end
    ess_mV(filaCalculada) = 0;
    radio_espectral(filaCalculada) = radio;
    estado(filaCalculada) = "estimacion por polo dominante";

    coincide = simulacion.caso == indiceCaso & ...
        simulacion.planta == "identificada" & ...
        simulacion.actuador == "ideal_limitado";
    assert(nnz(coincide) == 1, "No se encontro la simulacion requerida.");
    tr_ms(filaSimulada) = simulacion.tr_ms(coincide);
    ts_ms(filaSimulada) = simulacion.ts_ms(coincide);
    % La serie temporal simulada se procesa con la misma banda del 5 % y la
    % misma mediana móvil de 11 muestras usadas para los datos experimentales.
    rutaSerie = fullfile(rutaResultados, sprintf( ...
        "caso_%d_identificada_ideal_limitado.csv", indiceCaso));
    serie = readtable(rutaSerie, VariableNamingRule="preserve");
    ts_robusto_ms(filaSimulada) = calcularEstablecimientoRobusto(serie);
    Mp_pct(filaSimulada) = simulacion.Mp_pct(coincide);
    ess_mV(filaSimulada) = simulacion.ess_mV(coincide);
    u_min_mV(filaSimulada) = simulacion.u_min_mV(coincide);
    u_max_mV(filaSimulada) = simulacion.u_max_mV(coincide);
    radio_espectral(filaSimulada) = simulacion.rho_combinado(coincide);
    estado(filaSimulada) = "modelo identificado, actuador ideal limitado";

    if ~isempty(experimental)
        coincideExperimental = experimental.caso == indiceCaso;
        assert(nnz(coincideExperimental) == 1, ...
            "El resumen experimental debe contener un renglon por caso.");
        if experimental.captura_valida(coincideExperimental)
            tr_ms(filaExperimental) = experimental.tr_ms(coincideExperimental);
            ts_ms(filaExperimental) = experimental.ts_ms(coincideExperimental);
            ts_robusto_ms(filaExperimental) = ...
                experimental.ts_robusto_ms(coincideExperimental);
            Mp_pct(filaExperimental) = experimental.Mp_pct(coincideExperimental);
            ess_mV(filaExperimental) = experimental.ess_mV(coincideExperimental);
            u_min_mV(filaExperimental) = ...
                experimental.u_min_mV(coincideExperimental);
            u_max_mV(filaExperimental) = ...
                experimental.u_max_mV(coincideExperimental);
            estado(filaExperimental) = "medicion experimental validada";
        else
            estado(filaExperimental) = ...
                experimental.estado(coincideExperimental);
        end
    else
        estado(filaExperimental) = "pendiente de medicion en el montaje";
    end
end

tablaComparativa = table(caso, origen, tr_ms, ts_ms, ts_robusto_ms, ...
    Mp_pct, ess_mV, ...
    u_min_mV, u_max_mV, radio_espectral, estado);
rutaSalida = fullfile(rutaResultados, ...
    "tabla_calculado_simulado_experimental_lab9.csv");
writetable(tablaComparativa, rutaSalida);
disp(tablaComparativa);
fprintf("Tabla comparativa guardada en: %s\n", rutaSalida);

function tsRobusto_ms = calcularEstablecimientoRobusto(serie)
    % La referencia del pulso define el comienzo y el final
    % de la meseta. No se fijan índices dependientes de una corrida concreta.
    enReferencia = serie.r_V > 0.5*max(serie.r_V);
    inicio = find(enReferencia, 1, "first");
    fin = find(~enReferencia & (1:height(serie))' > inicio, 1, "first")-1;
    assert(~isempty(inicio) && ~isempty(fin), ...
        "La simulación no contiene una meseta de referencia válida.");
    meseta = inicio:fin;
    referencia = median(serie.r_V(meseta), "omitmissing");
    salidaFiltrada = smoothdata(serie.y_V(meseta), "movmedian", 11);
    dentro = abs(salidaFiltrada-referencia) <= 0.05*abs(referencia);
    ultimoFuera = find(~dentro, 1, "last");
    if isempty(ultimoFuera)
        tsRobusto_ms = 0;
    elseif ultimoFuera < numel(meseta)
        tsRobusto_ms = 1000*(serie.t_s(meseta(ultimoFuera+1))- ...
            serie.t_s(inicio));
    else
        tsRobusto_ms = NaN;
    end
end
