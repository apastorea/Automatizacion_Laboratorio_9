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
figura = figure(Color="white", Position=[70 100 1500 570]);
eje = axes(figura, Position=[0.02 0.04 0.96 0.92]);
hold(eje, "on");
axis(eje, [0 18 0 7]);
axis(eje, "off");

% Paleta sobria: azul para procesamiento digital, gris para la planta y
% naranja para la interfaz fisica de actuacion.
azul = [0.84 0.91 0.98];
naranja = [0.98 0.89 0.72];
gris = [0.92 0.92 0.92];
borde = [0.18 0.18 0.18];

% Camino directo: referencia, error integral, ley LQR, actuador y planta.
dibujarSumador(eje, [1.45 4.65], 0.42, borde);
dibujarBloque(eje, [2.55 4.00 2.05 1.30], azul, borde, ...
    "Integral del error", ...
    {"$\xi[k+1]=\xi[k]+r[k]-y[k]$"});
dibujarBloque(eje, [5.05 3.88 2.20 1.54], azul, borde, ...
    "Control LQR", ...
    {"$u[k]=-K_x\hat{x}[k]$", ...
     "$\phantom{u[k]}-K_i\xi[k]$"});
dibujarBloque(eje, [7.90 3.88 2.05 1.54], naranja, borde, ...
    "Saturación y DAC", ...
    {"$v[k]=\mathrm{sat}_{\mathcal{U}}(u[k])$", ...
     "$u_{\mathrm{ap}}[k]=Q_{\mathrm{DAC}}(v[k])$"});
dibujarBloque(eje, [10.65 3.88 2.55 1.54], gris, borde, ...
    "Planta identificada", ...
    {"$x[k+1]=A_{\mathrm{id}}x[k]+B_{\mathrm{id}}u_{\mathrm{ap}}[k]$", ...
     "$y[k]=Cx[k]$"});

dibujarFlecha(eje, 0.35, 4.65, 1.02, 4.65, borde);
text(eje, 0.30, 4.95, "$r[k]$", FontSize=11, FontWeight="bold", ...
    Interpreter="latex", Color="black");
dibujarFlecha(eje, 1.88, 4.65, 2.55, 4.65, borde);
dibujarFlecha(eje, 4.60, 4.65, 5.05, 4.65, borde);
dibujarFlecha(eje, 7.25, 4.65, 7.90, 4.65, borde);
dibujarFlecha(eje, 9.95, 4.65, 10.65, 4.65, borde);
dibujarFlecha(eje, 13.20, 4.65, 14.25, 4.65, borde);
text(eje, 14.30, 4.78, "$y[k]$", FontSize=11, FontWeight="bold", ...
    Interpreter="latex", Color="black");

% La salida medida se deriva despues de la planta. Su realimentacion se lleva
% por debajo del estimador para que no cruce las conexiones de xhat ni u_ap.
% Los puntos solidos identifican bifurcaciones electricamente conectadas.
plot(eje, [13.70 13.70 1.45 1.45], [4.65 0.35 0.35 4.12], ...
    Color=borde, LineWidth=1.15);
dibujarNodo(eje, 13.70, 4.65, borde);
dibujarFlecha(eje, 1.45, 0.35, 1.45, 4.20, borde);
text(eje, 1.05, 4.85, "+", FontSize=12, FontWeight="bold", Color="black");
text(eje, 1.03, 4.18, "$-$", FontSize=14, FontWeight="bold", ...
    Interpreter="latex", Color="black");

% El estimador se descompone para mostrar sin ambiguedad la innovacion. La
% salida estimada se calcula desde la prediccion de estado y se resta de la
% salida medida antes de aplicar la ganancia L.
dibujarBloque(eje, [5.00 0.78 2.55 1.48], azul, borde, ...
    "Predictor", ...
    {"$\hat{x}^{-}[k+1]=A_{\mathrm{id}}\hat{x}[k]$", ...
     "$\phantom{\hat{x}^{-}[k+1]}+B_{\mathrm{id}}u_{\mathrm{ap}}[k]$"});
dibujarBloque(eje, [8.05 0.90 1.85 1.24], azul, borde, ...
    "Salida estimada", {"$\hat{y}^{-}[k]=C\hat{x}^{-}[k]$"});
dibujarSumadorInnovacion(eje, [11.05 1.52], 0.38, borde);
dibujarBloque(eje, [12.00 0.98 1.35 1.08], azul, borde, ...
    "Ganancia", {"$L\nu[k]$"});
dibujarBloque(eje, [13.92 0.78 2.35 1.48], azul, borde, ...
    "Corrección", ...
    {"$\hat{x}[k]=\hat{x}^{-}[k]$", "$\phantom{\hat{x}[k]}+L\nu[k]$"});

dibujarFlecha(eje, 7.55, 1.52, 8.05, 1.52, borde);
text(eje, 7.60, 1.73, "$\hat{x}^{-}[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");
dibujarFlecha(eje, 9.90, 1.52, 10.67, 1.52, borde);
dibujarFlecha(eje, 11.43, 1.52, 12.00, 1.52, borde);
text(eje, 11.43, 1.76, "$\nu[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");
dibujarFlecha(eje, 13.35, 1.52, 13.92, 1.52, borde);

% y[k] llega al signo positivo del comparador. La rama vertical parte de la
% salida de planta y posee nodos solo donde existe una bifurcacion real.
plot(eje, [13.70 13.70 11.05], [4.65 2.72 2.72], ...
    Color=borde, LineWidth=1.15);
dibujarNodo(eje, 13.70, 4.65, borde);
dibujarFlecha(eje, 11.05, 2.72, 11.05, 1.90, borde);
text(eje, 11.20, 2.54, "$y[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");

% El mando aplicado alimenta al predictor desde el nodo posterior al DAC.
plot(eje, [10.30 10.30 6.28], [4.65 2.52 2.52], ...
    Color=borde, LineWidth=1.15);
dibujarNodo(eje, 10.30, 4.65, borde);
dibujarFlecha(eje, 6.28, 2.52, 6.28, 2.26, borde);
text(eje, 8.42, 2.70, "$u_{\mathrm{ap}}[k]$", FontSize=9.5, ...
    Interpreter="latex", Color="black");

% El estado corregido vuelve tanto al regulador como al predictor. El trazado
% se mantiene por el borde derecho e inferior para no cruzar otras señales.
plot(eje, [16.27 16.75 16.75 4.50 4.50 6.15], ...
    [1.52 1.52 0.72 0.72 3.48 3.48], Color=borde, LineWidth=1.15);
dibujarNodo(eje, 16.75, 1.52, borde);
dibujarFlecha(eje, 6.15, 3.48, 6.15, 3.88, borde);
plot(eje, [4.50 4.50 5.00], [0.72 1.52 1.52], ...
    Color=borde, LineWidth=1.15);
dibujarFlecha(eje, 4.50, 1.52, 5.00, 1.52, borde);
text(eje, 4.65, 0.90, "$\hat{x}[k]$", FontSize=9.5, ...
    FontWeight="bold", Interpreter="latex", Color="black");

% Notas que vinculan la arquitectura con las verificaciones del laboratorio.
text(eje, 9.0, 6.25, ...
    "Arquitectura digital implementada (Ts = 2 ms)", ...
    HorizontalAlignment="center", FontSize=14, FontWeight="bold", ...
    Color="black");
text(eje, 9.0, 5.86, ...
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
