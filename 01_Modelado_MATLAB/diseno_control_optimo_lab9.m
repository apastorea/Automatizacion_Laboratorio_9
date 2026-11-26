% LABORATORIO 9 - CONTROL OPTIMO DISCRETO CON ACCION INTEGRAL
%
% Disena y compara tres controladores LQR sobre el modelo identificado de la
% planta. El modelo nominal se conserva como prueba de sensibilidad.
%
% Convenciones:
%   x = [x1; x2], y = [0 1]x
%   xi[k+1] = xi[k] + r[k] - y[k]
%   u[k] = -Kx*xhat_actual[k] - Ki*xi[k]
%
% El script no establece comunicacion con hardware. Los resultados generados
% son simulaciones y se etiquetan como tales.

clearvars;
clc;
close all;

fprintf('\nLABORATORIO 9 - DISENO LQR CON MODELO IDENTIFICADO.\n');
fprintf('Los resultados de este script son simulaciones, no ensayos fisicos.\n');

%% 1. Configuracion del ensayo
% La referencia se activa despues de 32 muestras de pretrigger y se retira a
% los 666 ms, exactamente igual que en el firmware Lab9.
Ts = 0.002;
N = 600;
t = (0:N-1)'*Ts;
iInicio = 33;
iFin = 333;
r = zeros(N, 1);
r(iInicio:iFin) = 0.050;

polosObservador = [0.20+0.10i, 0.20-0.10i];

limites.uMin = -0.115;
limites.uMax = 0.107;
limites.qPos = 0.015370448;
limites.qNeg = 0.010560423;
limites.codigoPosMax = 7;
limites.codigoNegMax = 11;
limites.antiwindup = true;

casos(1).nombre = "caso_1";
casos(1).Q = diag([0.01, 0.01, 0.001]);
casos(1).R = 1;
casos(2).nombre = "caso_2";
casos(2).Q = diag([0.01, 0.01, 0.1]);
casos(2).R = 0.1;
casos(3).nombre = "caso_3";
casos(3).Q = diag([0.01, 0.01, 0.001]);
casos(3).R = 0.01;

%% 2. Modelo nominal obtenido de los componentes
R5 = 150e3;
R6 = 47e3;
R1 = 15e3;
R2 = 47e3;
C1 = 100e-9;
C3 = 100e-9;

Fnom = [-1/(R5*C1), 0; -1/(R2*C3), -1/(R1*C3)];
Gnom = [-1/(R6*C1); 0];
C = [0, 1];
D = 0;

sistemaNominal = c2d(ss(Fnom, Gnom, C, D), Ts, "zoh");
[Anom, Bnom, ~, ~] = ssdata(sistemaNominal);

%% 3. Modelo identificado adoptado para sintesis
% Parametros del modelo identificado previamente validado.
Kid = 1.002941;
tau1 = 0.00906915;
tau2 = 0.000774399;
gananciaEtapa1 = R5/R6;
gananciaEtapa2 = Kid/gananciaEtapa1;

Fid = [-1/tau1, 0; -gananciaEtapa2/tau2, -1/tau2];
Gid = [-gananciaEtapa1/tau1; 0];
sistemaIdentificado = c2d(ss(Fid, Gid, C, D), Ts, "zoh");
[Aid, Bid, ~, ~] = ssdata(sistemaIdentificado);

assert(rank(ctrb(Aid, Bid)) == 2, ...
    "El modelo identificado no es controlable.");
assert(rank(obsv(Aid, C)) == 2, ...
    "El modelo identificado no es observable.");
assert(rank(obsv(Aid, C*Aid)) == 2, ...
    "No se puede construir el estimador actual con este modelo.");

Ad = Aid;
Bd = Bid;

fprintf('\nTs = %.3f ms; fs = %.1f Hz\n', 1000*Ts, 1/Ts);
disp('Modelo identificado usado en la sintesis:');
disp('Aid ='); disp(Aid);
disp('Bid ='); disp(Bid);

%% 4. Estimador actual disenado con el modelo identificado
Lactual = place(Ad', (C*Ad)', polosObservador).';
polosEstimador = eig((eye(2)-Lactual*C)*Ad);
assert(max(abs(polosEstimador)) < 1, "El estimador actual es inestable.");

disp('Ganancia del estimador actual L ='); disp(Lactual);
disp('Polos del estimador ='); disp(polosEstimador.');

%% 5. Modelo aumentado y controlabilidad
% El tercer estado es xi[k+1]=xi[k]+r[k]-y[k]. La referencia no participa en
% la sintesis de K, pero actua como entrada exogena del integrador.
Aaug = [Ad, zeros(2, 1); -C, 1];
Baug = [Bd; 0];
assert(rank(ctrb(Aaug, Baug)) == 3, ...
    "El modelo aumentado identificado no es controlable.");

%% 6. Diseno LQR y verificacion independiente de Riccati
resumenDiseno = table();
ganancias = repmat(struct("K", [], "S", [], "polos", [], ...
    "iteraciones", 0, "errorRiccati", NaN), numel(casos), 1);

for i = 1:numel(casos)
    Q = casos(i).Q;
    R = casos(i).R;
    [Kdlqr, Sdlqr, polos] = dlqr(Aaug, Baug, Q, R);
    [Kriccati, Sriccati, iteraciones] = resolverRiccati( ...
        Aaug, Baug, Q, R, 1e-12, 100000);

    errorK = norm(Kriccati-Kdlqr, inf);
    errorS = norm(Sriccati-Sdlqr, inf);
    assert(errorK < 1e-8 && errorS < 1e-8, ...
        "Riccati iterativo no coincide con dlqr en el caso %d.", i);
    assert(max(abs(polos)) < 1, ...
        "El controlador del caso %d es inestable.", i);

    ganancias(i).K = Kdlqr;
    ganancias(i).S = Sdlqr;
    ganancias(i).polos = polos;
    ganancias(i).iteraciones = iteraciones;
    ganancias(i).errorRiccati = errorK;

    Kx = Kdlqr(1:2);
    Ki = Kdlqr(3);
    fila = table(i, casos(i).nombre, Q(1,1), Q(2,2), Q(3,3), R, ...
        Kx(1), Kx(2), Ki, max(abs(polos)), iteraciones, errorK, errorS, ...
        'VariableNames', {'caso','nombre','Q11','Q22','Q33','Q2', ...
        'Kx1','Kx2','Ki','radio_espectral','iteraciones_riccati', ...
        'error_K_riccati_dlqr','error_S_riccati_dlqr'});
    resumenDiseno = [resumenDiseno; fila]; %#ok<AGROW>

    fprintf('\nCASO %d: diag(Q1)=[%.3g %.3g %.3g], Q2=%.3g\n', ...
        i, Q(1,1), Q(2,2), Q(3,3), R);
    fprintf('Kx=[%.12f %.12f], Ki=%.12f\n', Kx(1), Kx(2), Ki);
    fprintf('Polos de lazo cerrado: '); disp(polos.');
    fprintf('Riccati: %d iteraciones, ||Kric-Kdlqr||inf=%.3e\n', ...
        iteraciones, errorK);
end

%% 7. Simulacion sobre modelo identificado y nominal
carpetaScript = fileparts(mfilename('fullpath'));
carpetaResultados = fullfile(carpetaScript, '..', '05_Resultados');
carpetaFiguras = fullfile(carpetaResultados, 'figuras');
if ~isfolder(carpetaResultados), mkdir(carpetaResultados); end
if ~isfolder(carpetaFiguras), mkdir(carpetaFiguras); end

writetable(resumenDiseno, ...
    fullfile(carpetaResultados, 'resumen_diseno_lqr_lab9.csv'));

nombresPlanta = ["identificada", "nominal"];
nombresActuador = ["ideal_limitado", "dac_cuantizado"];
resultados = table();
curvas = cell(numel(casos), numel(nombresPlanta), numel(nombresActuador));

for i = 1:numel(casos)
    K = ganancias(i).K;
    Kx = K(1:2);
    Ki = K(3);

    for j = 1:numel(nombresPlanta)
        if nombresPlanta(j) == "identificada"
            Ap = Aid;
            Bp = Bid;
        else
            Ap = Anom;
            Bp = Bnom;
        end

        rhoCombinado = radioEspectralCombinado( ...
            Ap, Bp, Ad, Bd, C, Lactual, Kx, Ki);
        assert(rhoCombinado < 1, ...
            "Lazo lineal inestable en caso %d / planta %s.", ...
            i, nombresPlanta(j));

        for q = 1:numel(nombresActuador)
            usarCuantizacion = nombresActuador(q) == "dac_cuantizado";
            simulacion = simularControl( ...
                Ap, Bp, Ad, Bd, C, Lactual, Kx, Ki, r, ...
                limites, usarCuantizacion);
            metricas = calcularMetricas( ...
                simulacion, t, r, iInicio, iFin, Ts);

            curvas{i,j,q} = simulacion;
            fila = table(i, casos(i).nombre, nombresPlanta(j), ...
                nombresActuador(q), rhoCombinado, metricas.tr_ms, ...
                metricas.ts_ms, metricas.Mp_pct, metricas.ess_mV, ...
                metricas.uMin_mV, metricas.uMax_mV, ...
                metricas.saturaciones, metricas.bloqueosAntiwindup, ...
                'VariableNames', {'caso','nombre','planta','actuador', ...
                'rho_combinado','tr_ms','ts_ms','Mp_pct','ess_mV', ...
                'u_min_mV','u_max_mV','saturaciones', ...
                'bloqueos_antiwindup'});
            resultados = [resultados; fila]; %#ok<AGROW>

            tablaMuestras = table(t, r, simulacion.y, simulacion.u, ...
                simulacion.uSolicitada, simulacion.xi, ...
                'VariableNames', {'t_s','r_V','y_V','u_aplicado_V', ...
                'u_solicitado_V','xi_integral_V'});
            archivo = sprintf('%s_%s_%s.csv', casos(i).nombre, ...
                nombresPlanta(j), nombresActuador(q));
            writetable(tablaMuestras, fullfile(carpetaResultados, archivo));
        end
    end
end

writetable(resultados, ...
    fullfile(carpetaResultados, 'resumen_simulacion_lab9.csv'));

disp(' ');
disp('RESUMEN DE DISENO LQR:');
disp(resumenDiseno);
disp('RESUMEN DE SIMULACION:');
disp(resultados);

%% 8. Figuras comparativas
qCuantizado = find(nombresActuador == "dac_cuantizado", 1);
for j = 1:numel(nombresPlanta)
    fig = figure('Color', 'w', ...
        'Name', "LQR Lab9 - " + nombresPlanta(j));
    tiledlayout(2, 1, 'TileSpacing', 'compact');

    nexttile;
    hold on;
    stairs(t*1000, r*1000, 'k--', 'LineWidth', 1.3);
    for i = 1:numel(casos)
        stairs(t*1000, curvas{i,j,qCuantizado}.y*1000, 'LineWidth', 1.2);
    end
    grid on;
    xlim([0, 850]);
    ylabel('Salida y [mV]');
    title("Respuesta con DAC cuantizado - planta " + nombresPlanta(j));
    legend('Referencia', 'Caso 1', 'Caso 2', 'Caso 3', ...
        'Location', 'best');

    nexttile;
    hold on;
    for i = 1:numel(casos)
        stairs(t*1000, curvas{i,j,qCuantizado}.u*1000, 'LineWidth', 1.2);
    end
    yline(limites.uMax*1000, 'k--', 'Limite +');
    yline(limites.uMin*1000, 'k--', 'Limite -');
    grid on;
    xlim([0, 850]);
    xlabel('Tiempo [ms]');
    ylabel('Mando aplicado [mV]');
    legend('Caso 1', 'Caso 2', 'Caso 3', 'Location', 'best');

    exportgraphics(fig, fullfile(carpetaFiguras, ...
        "comparacion_lqr_" + nombresPlanta(j) + ".png"), ...
        'Resolution', 220);
end

figPolos = figure('Color', 'w', 'Name', 'Polos LQR Lab9');
hold on;
theta = linspace(0, 2*pi, 500);
plot(cos(theta), sin(theta), 'k--', 'LineWidth', 1);
colores = lines(numel(casos));
for i = 1:numel(casos)
    p = ganancias(i).polos;
    plot(real(p), imag(p), 'x', 'Color', colores(i,:), ...
        'MarkerSize', 9, 'LineWidth', 1.8);
end
plot(real(polosEstimador), imag(polosEstimador), 'o', ...
    'Color', [0.2, 0.2, 0.2], 'MarkerSize', 7, 'LineWidth', 1.4);
axis equal;
grid on;
xlim([-1.05, 1.05]);
ylim([-1.05, 1.05]);
xlabel('Parte real');
ylabel('Parte imaginaria');
title('Polos de los controladores y del estimador actual');
legend('Circulo unitario', 'Caso 1', 'Caso 2', 'Caso 3', ...
    'Estimador', 'Location', 'southwest');
exportgraphics(figPolos, fullfile(carpetaFiguras, ...
    'mapa_polos_lqr_lab9.png'), 'Resolution', 220);

fprintf('\nResultados escritos en: %s\n', carpetaResultados);

%% Funciones locales
function [K, S, iteraciones] = resolverRiccati(A, B, Q, R, tol, maxIter)
    % Iteracion de Riccati discreta usada como verificacion independiente de
    % dlqr; no se emplea para exportar las ganancias al firmware.
    S = Q;
    for iteraciones = 1:maxIter
        Kactual = (R+B'*S*B) \ (B'*S*A);
        Snueva = Q+A'*S*A-A'*S*B*Kactual;
        if norm(Snueva-S, inf) < tol
            S = Snueva;
            K = (R+B'*S*B) \ (B'*S*A);
            return;
        end
        S = Snueva;
    end
    error('Riccati no convergio en %d iteraciones.', maxIter);
end

function rho = radioEspectralCombinado(Ap, Bp, A, B, C, L, Kx, Ki)
    % Matriz aumentada planta-observador-integrador para estudiar estabilidad
    % cuando la planta simulada Ap,Bp difiere del modelo A,B del controlador.
    E = eye(2)-L*C;
    M = [Ap-Bp*Kx*L*C, -Bp*Kx*E, -Bp*Ki; ...
         (A-B*Kx)*L*C, (A-B*Kx)*E, -B*Ki; ...
         -C, zeros(1,2), 1];
    rho = max(abs(eig(M)));
end

function S = simularControl(Ap, Bp, A, B, C, L, Kx, Ki, r, limites, cuantizar)
    % Replica el orden de la ISR: medir, corregir el estimador, calcular mando,
    % saturar/cuantizar, propagar planta y predictor, y actualizar el integrador.
    cantidad = numel(r);
    x = zeros(2,1);
    z = zeros(2,1);
    xi = 0;

    S.y = zeros(cantidad,1);
    S.u = zeros(cantidad,1);
    S.uSolicitada = zeros(cantidad,1);
    S.xi = zeros(cantidad,1);
    S.saturado = false(cantidad,1);
    S.antiwindup = false(cantidad,1);

    for k = 1:cantidad
        y = C*x;
        innovacion = y-C*z;
        xhat = z+L*innovacion;
        uSolicitada = -Kx*xhat-Ki*xi;
        uLimitada = min(limites.uMax, max(limites.uMin, uSolicitada));

        if cuantizar
            if uLimitada >= 0
                codigo = min(limites.codigoPosMax, ...
                    max(0, round(uLimitada/limites.qPos)));
                uAplicada = codigo*limites.qPos;
            else
                codigo = min(limites.codigoNegMax, ...
                    max(0, round(-uLimitada/limites.qNeg)));
                uAplicada = -codigo*limites.qNeg;
            end
        else
            uAplicada = uLimitada;
        end

        saturado = abs(uSolicitada-uLimitada) > eps(max(1, abs(uSolicitada)));
        errorSeguimiento = r(k)-y;
        bloqueo = limites.antiwindup && ...
            ((uSolicitada > limites.uMax && errorSeguimiento > 0) || ...
             (uSolicitada < limites.uMin && errorSeguimiento < 0));

        S.y(k) = y;
        S.u(k) = uAplicada;
        S.uSolicitada(k) = uSolicitada;
        S.xi(k) = xi;
        S.saturado(k) = saturado;
        S.antiwindup(k) = bloqueo;

        x = Ap*x+Bp*uAplicada;
        z = A*xhat+B*uAplicada;
        if ~bloqueo
            xi = xi+errorSeguimiento;
        end

        assert(all(isfinite([x; z; xi; uAplicada])), ...
            "La simulacion produjo NaN o Inf.");
    end
end

function m = calcularMetricas(S, t, r, iInicio, iFin, Ts)
    % Metricas de seguimiento calculadas unicamente durante la meseta positiva.
    referencia = r(iInicio);
    y = S.y(iInicio:iFin);
    tx = t(iInicio:iFin);

    i10 = find(y >= 0.1*referencia, 1, 'first');
    i90 = find(y >= 0.9*referencia, 1, 'first');
    m.tr_ms = NaN;
    if ~isempty(i10) && ~isempty(i90) && i90 >= i10
        m.tr_ms = 1000*(tx(i90)-tx(i10));
    end

    m.Mp_pct = max(0, 100*(max(y)-referencia)/referencia);
    fuera = find(abs(y-referencia) > 0.02*abs(referencia));
    m.ts_ms = NaN;
    if isempty(fuera)
        m.ts_ms = 0;
    elseif fuera(end) < numel(y)
        m.ts_ms = fuera(end)*Ts*1000;
    end

    iPromedio = max(1, numel(y)-15):numel(y);
    m.ess_mV = 1000*mean(referencia-y(iPromedio));
    m.uMin_mV = 1000*min(S.u);
    m.uMax_mV = 1000*max(S.u);
    m.saturaciones = nnz(S.saturado);
    m.bloqueosAntiwindup = nnz(S.antiwindup);
end
