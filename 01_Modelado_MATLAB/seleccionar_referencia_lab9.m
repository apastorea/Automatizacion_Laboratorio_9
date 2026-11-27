% SELECCIONAR_REFERENCIA_LAB9 Selecciona la amplitud del ensayo cerrado.
% Evalua 0.25, 0.50, 0.75 y 1.00 V con los tres reguladores LQR sobre el
% modelo identificado. Una amplitud es admisible cuando ningun caso satura
% y el mayor mando solicitado permanece dentro de +/-0.8 V. Este margen del
% 20 % evita ensayar en el borde de la etapa fisica de +/-1 V.

clearvars;
close all;
clc;

%% Modelo y realizacion digital usados por el firmware
Ts = 0.002;
N = 600;
C = [0 1];
A = [0.802095310 0; -0.249628290 0.075573620];
B = [-0.631610700; 0.130459080];
L = [-1.860494424; 0.175152235];
K = [-0.052956570 0.033630708 -0.030993647; ...
     -0.579807176 0.837180560 -0.773844770; ...
     -0.608122502 0.257675755 -0.232969182];
referencias_V = [0.25; 0.50; 0.75; 1.00];
limiteFisico_V = 1.00;
limiteDiseno_V = 0.80;

%% Barrido conjunto de amplitud y controlador
filas = table();
for iRef = 1:numel(referencias_V)
    r = zeros(N,1);
    r(33:333) = referencias_V(iRef);
    for caso = 1:3
        [maxSolicitado, saturaciones, picoSalida] = simularCaso( ...
            A, B, C, L, K(caso,1:2), K(caso,3), r, limiteFisico_V);
        cumple = saturaciones == 0 && maxSolicitado <= limiteDiseno_V;
        fila = table(referencias_V(iRef), caso, maxSolicitado, ...
            picoSalida, saturaciones, cumple, 'VariableNames', ...
            {'referencia_V','caso','max_u_solicitada_V','pico_y_V', ...
             'saturaciones','cumple_criterio'});
        filas = [filas; fila]; %#ok<AGROW>
    end
end

% La decision se toma sobre el peor de los tres controladores, no sobre un
% caso favorable aislado. Se elige la mayor amplitud que satisface el margen.
resumen = groupsummary(filas, 'referencia_V', {'max','sum'}, ...
    {'max_u_solicitada_V','saturaciones'});
resumen.Properties.VariableNames{'max_max_u_solicitada_V'} = ...
    'peor_u_solicitada_V';
resumen.Properties.VariableNames{'sum_saturaciones'} = ...
    'saturaciones_totales';
resumen.cumple_criterio = resumen.peor_u_solicitada_V <= limiteDiseno_V & ...
    resumen.saturaciones_totales == 0;
admisibles = resumen.referencia_V(resumen.cumple_criterio);
assert(~isempty(admisibles), 'Ninguna referencia satisface el criterio.');
referenciaSeleccionada_V = max(admisibles);
resumen.seleccionada = resumen.referencia_V == referenciaSeleccionada_V;
assert(abs(referenciaSeleccionada_V-0.50) < eps, ...
    'La referencia seleccionada ya no coincide con 0.50 V; revise el firmware.');

%% Evidencia reproducible
carpetaScript = fileparts(mfilename('fullpath'));
carpetaSalida = fullfile(carpetaScript, '..', '05_Resultados', ...
    'Seleccion_Referencia');
if ~isfolder(carpetaSalida), mkdir(carpetaSalida); end
writetable(filas, fullfile(carpetaSalida, ...
    'barrido_referencias_lab9.csv'));
writetable(resumen, fullfile(carpetaSalida, ...
    'criterio_seleccion_referencia_lab9.csv'));

figura = figure(Color='white', Position=[100 100 860 470]);
hold on;
for caso = 1:3
    datosCaso = filas(filas.caso == caso,:);
    plot(1000*datosCaso.referencia_V, ...
        1000*datosCaso.max_u_solicitada_V, '-o', LineWidth=1.35, ...
        DisplayName=sprintf('Caso %d', caso));
end
yline(1000*limiteDiseno_V, 'k--', 'Margen de diseno (80 %)', ...
    LineWidth=1.15, LabelHorizontalAlignment='left', ...
    HandleVisibility='off');
xline(1000*referenciaSeleccionada_V, ':', 'Seleccion: 500 mV', ...
    LineWidth=1.15, LabelVerticalAlignment='bottom', ...
    HandleVisibility='off');
grid on;
xlabel('Amplitud de referencia [mV]');
ylabel('Maximo |u_{solicitada}| [mV]');
title('Seleccion de amplitud sobre el modelo identificado');
legend(Location='northwest');
exportgraphics(figura, fullfile(carpetaSalida, ...
    'seleccion_referencia_lab9.png'), Resolution=240);
close(figura);

fprintf('Referencia seleccionada: %.0f mV.\n', ...
    1000*referenciaSeleccionada_V);
disp(resumen);

function [maxU, saturaciones, picoY] = simularCaso(A,B,C,L,Kx,Ki,r,uMax)
% SIMULARCASO Replica el orden medir-corregir-controlar-predecir de la ISR.
    x = zeros(2,1);
    xPred = zeros(2,1);
    xi = 0;
    maxU = 0;
    picoY = 0;
    saturaciones = 0;
    for k = 1:numel(r)
        y = C*x;
        innovacion = y-C*xPred;
        xEst = xPred+L*innovacion;
        uSolicitada = -Kx*xEst-Ki*xi;
        uAplicada = min(uMax,max(-uMax,uSolicitada));
        saturaciones = saturaciones+(uAplicada ~= uSolicitada);
        error = r(k)-y;
        if ~((uSolicitada > uMax && error > 0) || ...
                (uSolicitada < -uMax && error < 0))
            xi = xi+error;
        end
        x = A*x+B*uAplicada;
        xPred = A*xEst+B*uAplicada;
        maxU = max(maxU,abs(uSolicitada));
        picoY = max(picoY,abs(y));
    end
end
