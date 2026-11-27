% GENERAR_DIAGRAMA_BLOQUES_LAB9 Diagrama funcional del lazo implementado.
% La figura resume el modelo aumentado, el regulador LQR, la actuacion
% limitada y el estimador actual. No reemplaza al modelo Simulink ejecutable;
% su objetivo es documentar de forma legible la arquitectura pedida en el
% enunciado del Laboratorio 9.

clearvars;

% Las rutas se resuelven desde este archivo para que la exportacion sea
% independiente de la carpeta activa de MATLAB.
carpetaScript = fileparts(mfilename("fullpath"));
carpetaFiguras = fullfile(carpetaScript, "..", "05_Resultados", "figuras");
if ~isfolder(carpetaFiguras)
    mkdir(carpetaFiguras);
end

% El lienzo ancho permite mostrar el flujo principal de izquierda a derecha y
% ubicar debajo el estimador, evitando cruces innecesarios entre conexiones.
figura = figure(Color="white", Position=[50 80 1600 650]);
eje = axes(figura, Position=[0.015 0.035 0.97 0.93]);
hold(eje, "on");
axis(eje, [0 20 0 8.2]);
axis(eje, "off");

% Paleta sobria: azul para procesamiento digital, gris para la planta y
% naranja para la interfaz fisica de actuacion.
azul = [0.84 0.91 0.98];
naranja = [0.98 0.89 0.72];
gris = [0.92 0.92 0.92];
borde = [0.18 0.18 0.18];

% Camino directo: referencia, error integral, ley LQR, actuador y planta.
dibujarSumador(eje, [1.35 5.15], 0.42, borde);
dibujarBloque(eje, [2.20 4.48 2.65 1.34], azul, borde, ...
    "Integral del error", ...
    {"$\xi[k+1]=\xi[k]+r[k]-y[k]$"});
dibujarBloque(eje, [5.45 4.38 2.55 1.54], azul, borde, ...
    "Control LQR", ...
    {"$u[k]=-K_x\hat{x}[k]$", ...
     "$\phantom{u[k]}-K_i\xi[k]$"});
dibujarBloque(eje, [8.75 4.38 2.55 1.54], naranja, borde, ...
    "Saturación y DAC", ...
    {"$v[k]=\mathrm{sat}_{\mathcal{U}}(u[k])$", ...
     "$u_{\mathrm{ap}}[k]=Q_{\mathrm{DAC}}(v[k])$"});
dibujarBloque(eje, [12.05 4.38 3.20 1.54], gris, borde, ...
    "Planta identificada", ...
    {"$x[k+1]=A_{\mathrm{id}}x[k]+B_{\mathrm{id}}u_{\mathrm{ap}}[k]$", ...
     "$y[k]=Cx[k]$"});

dibujarFlecha(eje, 0.30, 5.15, 0.93, 5.15, borde);
text(eje, 0.25, 5.48, "$r[k]$", FontSize=11, FontWeight="bold", ...
    Interpreter="latex", Color="black");
dibujarFlecha(eje, 1.77, 5.15, 2.20, 5.15, borde);
dibujarFlecha(eje, 4.85, 5.15, 5.45, 5.15, borde);
dibujarFlecha(eje, 8.00, 5.15, 8.75, 5.15, borde);
dibujarFlecha(eje, 11.30, 5.15, 12.05, 5.15, borde);
dibujarFlecha(eje, 15.25, 5.15, 16.45, 5.15, borde);
text(eje, 16.52, 5.30, "$y[k]$", FontSize=11, FontWeight="bold", ...
    Interpreter="latex", Color="black");

% La salida medida se deriva despues de la planta. La realimentacion del
% error se lleva por el borde superior, completamente separada del estimador.
% Los puntos solidos identifican bifurcaciones electricamente conectadas.
plot(eje, [15.80 15.80 1.35 1.35], [5.15 6.55 6.55 5.62], ...
    Color=borde, LineWidth=1.15);
dibujarNodo(eje, 15.80, 5.15, borde);
dibujarFlecha(eje, 1.35, 6.55, 1.35, 5.57, borde);
text(eje, 0.94, 5.36, "+", FontSize=12, FontWeight="bold", Color="black");
text(eje, 1.55, 5.62, "$-$", FontSize=14, FontWeight="bold", ...
    Interpreter="latex", Color="black");

% El estimador se descompone para mostrar sin ambiguedad la innovacion. La
% salida estimada se calcula desde la prediccion de estado y se resta de la
% salida medida antes de aplicar la ganancia L.
dibujarBloque(eje, [3.20 1.10 3.10 1.52], azul, borde, ...
    "Predictor", ...
    {"$\hat{x}^{-}[k+1]=A_{\mathrm{id}}\hat{x}[k]$", ...
     "$\phantom{\hat{x}^{-}[k+1]}+B_{\mathrm{id}}u_{\mathrm{ap}}[k]$"});
dibujarBloque(eje, [7.05 1.24 2.45 1.24], azul, borde, ...
    "Salida estimada", {"$\hat{y}^{-}[k]=C\hat{x}^{-}[k]$"});
dibujarSumadorInnovacion(eje, [10.55 1.86], 0.38, borde);
dibujarBloque(eje, [11.50 1.30 1.60 1.12], azul, borde, ...
    "Ganancia", {"$L\nu[k]$"});
dibujarBloque(eje, [13.85 1.10 2.85 1.52], azul, borde, ...
    "Corrección", ...
    {"$\hat{x}[k]=\hat{x}^{-}[k]$", "$\phantom{\hat{x}[k]}+L\nu[k]$"});

dibujarFlecha(eje, 6.30, 1.86, 7.05, 1.86, borde);
text(eje, 6.37, 2.10, "$\hat{x}^{-}[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");
dibujarFlecha(eje, 9.50, 1.86, 10.17, 1.86, borde);
dibujarFlecha(eje, 10.93, 1.86, 11.50, 1.86, borde);
text(eje, 11.02, 2.10, "$\nu[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");
dibujarFlecha(eje, 13.10, 1.86, 13.85, 1.86, borde);

% y[k] llega al signo positivo del comparador. La rama vertical parte de la
% salida de planta y posee nodos solo donde existe una bifurcacion real.
plot(eje, [15.80 15.80 10.55], [5.15 3.35 3.35], ...
    Color=borde, LineWidth=1.15);
dibujarFlecha(eje, 10.55, 3.35, 10.55, 2.24, borde);
text(eje, 10.75, 3.15, "$y[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");

% El mando aplicado alimenta al predictor desde el nodo posterior al DAC.
plot(eje, [11.67 11.67 4.75], [5.15 3.05 3.05], ...
    Color=borde, LineWidth=1.15);
dibujarNodo(eje, 11.67, 5.15, borde);
dibujarFlecha(eje, 4.75, 3.05, 4.75, 2.62, borde);
text(eje, 7.70, 3.24, "$u_{\mathrm{ap}}[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");

% El estado corregido vuelve tanto al regulador como al predictor. Una rama
% se mantiene por el borde inferior y la otra usa un corredor libre entre el
% estimador y el camino principal, sin compartir cruces ambiguos.
plot(eje, [16.70 17.25 17.25 2.75 2.75 3.20], ...
    [1.86 1.86 0.45 0.45 1.86 1.86], Color=borde, LineWidth=1.15);
dibujarNodo(eje, 17.25, 1.86, borde);
dibujarFlecha(eje, 2.75, 1.86, 3.20, 1.86, borde);
plot(eje, [17.25 17.25 6.73 6.73], [1.86 2.80 2.80 4.38], ...
    Color=borde, LineWidth=1.15);
dibujarFlecha(eje, 6.73, 2.80, 6.73, 4.38, borde);
text(eje, 8.65, 2.98, "$\hat{x}[k]$", FontSize=9.5, ...
    FontWeight="bold", Interpreter="latex", Color="black");

% Notas que vinculan la arquitectura con las verificaciones del laboratorio.
text(eje, 10.0, 7.75, ...
    "Arquitectura digital implementada ($T_s=2~\mathrm{ms}$)", ...
    HorizontalAlignment="center", FontSize=14, FontWeight="bold", ...
    Interpreter="latex", Color="black");
text(eje, 10.0, 7.35, ...
    "Modelo identificado para regulador y estimador; modelo nominal reservado para incertidumbre", ...
    HorizontalAlignment="center", FontSize=10.5, Color="black");

% La exportacion PNG se usa en LaTeX y el PDF vectorial queda disponible para
% inspeccion o reutilizacion sin perdida de nitidez.
rutaPNG = fullfile(carpetaFiguras, "diagrama_bloques_lab9.png");
rutaPDF = fullfile(carpetaFiguras, "diagrama_bloques_lab9.pdf");
exportgraphics(figura, rutaPNG, Resolution=300);
exportgraphics(figura, rutaPDF, ContentType="vector");
close(figura);

fprintf("Diagrama funcional guardado en:\n  %s\n  %s\n", rutaPNG, rutaPDF);

function dibujarBloque(eje, posicion, relleno, borde, titulo, expresiones)
% DIBUJARBLOQUE Separa el titulo tecnico de las expresiones matematicas.
    rectangle(eje, Position=posicion, Curvature=0.05, ...
        FaceColor=relleno, EdgeColor=borde, LineWidth=1.15);
    centroX = posicion(1)+posicion(3)/2;
    centroY = posicion(2)+posicion(4)/2;
    text(eje, centroX, centroY+0.23*posicion(4), titulo, ...
        HorizontalAlignment="center", VerticalAlignment="middle", ...
        FontSize=9.5, FontWeight="bold", Color="black", ...
        Interpreter="none");
    text(eje, centroX, centroY-0.13*posicion(4), expresiones, ...
        HorizontalAlignment="center", VerticalAlignment="middle", ...
        FontSize=9.2, Color="black", Interpreter="latex");
end

function dibujarSumador(eje, centro, radio, borde)
% DIBUJARSUMADOR Representa el nodo donde se forma e[k]=r[k]-y[k].
    rectangle(eje, Position=[centro(1)-radio centro(2)-radio 2*radio 2*radio], ...
        Curvature=[1 1], FaceColor="white", EdgeColor=borde, LineWidth=1.15);
    text(eje, centro(1), centro(2), "$e[k]$", HorizontalAlignment="center", ...
        VerticalAlignment="middle", FontSize=9.5, Interpreter="latex", ...
        Color="black");
end

function dibujarSumadorInnovacion(eje, centro, radio, borde)
% DIBUJARSUMADORINNOVACION Forma nu[k]=y[k]-yhat^-[k].
    rectangle(eje, Position=[centro(1)-radio centro(2)-radio 2*radio 2*radio], ...
        Curvature=[1 1], FaceColor="white", EdgeColor=borde, LineWidth=1.15);
    text(eje, centro(1), centro(2), "$\nu[k]$", ...
        HorizontalAlignment="center", VerticalAlignment="middle", ...
        FontSize=9.2, Interpreter="latex", Color="black");
    text(eje, centro(1)-0.31, centro(2)+0.23, "$-$", ...
        FontSize=11, Interpreter="latex", Color="black");
    text(eje, centro(1)+0.08, centro(2)+0.42, "$+$", ...
        FontSize=10, Interpreter="latex", Color="black");
end

function dibujarNodo(eje, x, y, color)
% DIBUJARNODO Marca una union o bifurcacion real de señales.
    plot(eje, x, y, "o", MarkerSize=4.5, MarkerFaceColor=color, ...
        MarkerEdgeColor=color, LineWidth=0.8);
end

function dibujarFlecha(eje, x1, y1, x2, y2, color)
% DIBUJARFLECHA Dibuja una conexion dirigida en coordenadas del mismo eje.
    quiver(eje, x1, y1, x2-x1, y2-y1, 0, Color=color, ...
        LineWidth=1.15, MaxHeadSize=0.30);
end
