% VERIFICAR_SIMULINK_LAB9 Ejecuta los seis casos del modelo Simulink.
% Los resultados corresponden a un actuador ideal limitado; no son mediciones.

clearvars;

carpetaModelo = fileparts(mfilename("fullpath"));
modelo = "lab9_control_optimo";
casos = repelem((1:3)', 2);
plantas = repmat(["identificada"; "nominal"], 3, 1);
numeroSimulaciones = numel(casos);

caso = zeros(numeroSimulaciones, 1);
planta = strings(numeroSimulaciones, 1);
picoSalida_mV = zeros(numeroSimulaciones, 1);
mandoMinimo_mV = zeros(numeroSimulaciones, 1);
mandoMaximo_mV = zeros(numeroSimulaciones, 1);
errorRmsRegimen_mV = zeros(numeroSimulaciones, 1);

% Barrido factorial: tres sintesis LQR por dos modelos de planta. SimulationInput
% evita modificar permanentemente parametros dentro del archivo SLX.
for indice = 1:numeroSimulaciones
    lab9Caso = casos(indice);
    lab9Planta = plantas(indice);
    inicializar_simulink_lab9;

    entrada = Simulink.SimulationInput(modelo);
    entrada = entrada.setModelParameter("StopTime", "1.198");
    salida = sim(entrada);

    y = salida.ySimulinkLab9;
    u = salida.uSimulinkLab9;
    r = salida.rSimulinkLab9;
    % La ventana pertenece al tramo de referencia constante y se usa para el
    % error RMS de regimen antes de retirar el escalon.
    ventanaRegimen = y.Time >= 0.550 & y.Time <= 0.660;

    caso(indice) = casos(indice);
    planta(indice) = plantas(indice);
    picoSalida_mV(indice) = 1000*max(y.Data);
    mandoMinimo_mV(indice) = 1000*min(u.Data);
    mandoMaximo_mV(indice) = 1000*max(u.Data);
    errorRmsRegimen_mV(indice) = 1000*sqrt(mean( ...
        (r.Data(ventanaRegimen)-y.Data(ventanaRegimen)).^2));
end

resumenSimulink = table(caso, planta, picoSalida_mV, ...
    mandoMinimo_mV, mandoMaximo_mV, errorRmsRegimen_mV);
disp(resumenSimulink);

% Contraste independiente con la simulacion MATLAB de actuador ideal.
rutaResumenMatlab = fullfile(carpetaModelo, "..", "05_Resultados", ...
    "resumen_simulacion_lab9.csv");
if isfile(rutaResumenMatlab)
    resumenMatlab = readtable(rutaResumenMatlab, ...
        "TextType", "string", "VariableNamingRule", "preserve");
    for indice = 1:height(resumenSimulink)
        coincide = resumenMatlab.caso == resumenSimulink.caso(indice) & ...
            resumenMatlab.planta == resumenSimulink.planta(indice) & ...
            resumenMatlab.actuador == "ideal_limitado";
        assert(nnz(coincide) == 1, ...
            "No se encontro el caso equivalente en el resumen MATLAB.");
        assert(abs(resumenMatlab.u_min_mV(coincide)- ...
            resumenSimulink.mandoMinimo_mV(indice)) < 1e-3, ...
            "Simulink y MATLAB difieren en el mando minimo.");
        assert(abs(resumenMatlab.u_max_mV(coincide)- ...
            resumenSimulink.mandoMaximo_mV(indice)) < 1e-3, ...
            "Simulink y MATLAB difieren en el mando maximo.");
    end
end

rutaSalida = fullfile(carpetaModelo, "..", "05_Resultados", ...
    "resumen_simulink_lab9.csv");
writetable(resumenSimulink, rutaSalida);
fprintf("Resumen Simulink guardado en: %s\n", rutaSalida);
fprintf("Simulink y MATLAB coinciden en los limites de mando (<1 uV).\n");

assert(all(isfinite(resumenSimulink{:,3:end}), "all"), ...
    "Simulink produjo metricas no finitas.");
assert(all(resumenSimulink.mandoMinimo_mV >= -115-1e-6), ...
    "Simulink excedio el limite inferior.");
assert(all(resumenSimulink.mandoMaximo_mV <= 107+1e-6), ...
    "Simulink excedio el limite superior.");
