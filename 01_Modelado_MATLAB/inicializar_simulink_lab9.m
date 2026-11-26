% INICIALIZAR_SIMULINK_LAB9 Parametros del modelo Simulink del Laboratorio 9.
%
% Defina antes de ejecutar:
%   lab9Caso  = 1, 2 o 3
%   lab9Planta = "identificada" o "nominal"
%
% Los nombres de variables constituyen la interfaz del diagrama y sus valores
% se calculan en este archivo.

% La inicializacion usa el mismo modelo identificado, ganancias y convencion
% integral que el firmware. Las variables quedan en el workspace llamador
% porque los bloques del SLX las resuelven durante la compilacion.
if ~exist("lab9Caso", "var")
    lab9Caso = 1;
end
if ~exist("lab9Planta", "var")
    lab9Planta = "identificada";
end

mustBeMember(lab9Caso, 1:3);
mustBeMember(lab9Planta, ["identificada", "nominal"]);

TsLab9 = 0.002;

R5 = 150e3;
R6 = 47e3;
R1 = 15e3;
R2 = 47e3;
C1 = 100e-9;
C3 = 100e-9;
Cplanta = [0, 1];
Dplanta = 0;

Fnominal = [-1/(R5*C1), 0; -1/(R2*C3), -1/(R1*C3)];
Gnominal = [-1/(R6*C1); 0];
sistemaNominal = c2d(ss(Fnominal, Gnominal, Cplanta, Dplanta), ...
    TsLab9, "zoh");
[Anominal, Bnominal, ~, ~] = ssdata(sistemaNominal);

gananciaIdentificada = 1.002941;
tau1Identificada = 0.00906915;
tau2Identificada = 0.000774399;
gananciaEtapa1 = R5/R6;
gananciaEtapa2 = gananciaIdentificada/gananciaEtapa1;
Fidentificada = [-1/tau1Identificada, 0; ...
    -gananciaEtapa2/tau2Identificada, -1/tau2Identificada];
Gidentificada = [-gananciaEtapa1/tau1Identificada; 0];
sistemaIdentificado = c2d(ss(Fidentificada, Gidentificada, ...
    Cplanta, Dplanta), TsLab9, "zoh");
[Aidentificada, Bidentificada, ~, ~] = ssdata(sistemaIdentificado);

if lab9Planta == "identificada"
    AplantaLab9 = Aidentificada;
    BplantaLab9 = Bidentificada;
else
    AplantaLab9 = Anominal;
    BplantaLab9 = Bnominal;
end

AobservadorLab9 = Aidentificada;
BobservadorLab9 = Bidentificada;
CobservadorLab9 = Cplanta;
polosObservadorLab9 = [0.20+0.10i, 0.20-0.10i];
LobservadorLab9 = place(Aidentificada', ...
    (Cplanta*Aidentificada)', polosObservadorLab9).';

AumentadaLab9 = [Aidentificada, zeros(2,1); -Cplanta, 1];
BumentadaLab9 = [Bidentificada; 0];

QcasosLab9 = {
    diag([0.01, 0.01, 0.001]); ...
    diag([0.01, 0.01, 0.1]); ...
    diag([0.01, 0.01, 0.001])};
RcasosLab9 = [1, 0.1, 0.01];

KoptimaLab9 = dlqr(AumentadaLab9, BumentadaLab9, ...
    QcasosLab9{lab9Caso}, RcasosLab9(lab9Caso));
KxLab9 = KoptimaLab9(1:2);
KiLab9 = KoptimaLab9(3);

uMinLab9 = -0.115;
uMaxLab9 = 0.107;
referenciaLab9 = 0.050;
inicioReferenciaLab9 = 0.064;
finReferenciaLab9 = 0.666;
tiempoFinalLab9 = 1.198;

assert(rank(ctrb(AumentadaLab9, BumentadaLab9)) == 3, ...
    "El modelo aumentado del Laboratorio 9 no es controlable.");
assert(max(abs(eig(AumentadaLab9-BumentadaLab9*KoptimaLab9))) < 1, ...
    "El controlador LQR seleccionado no es estable.");
