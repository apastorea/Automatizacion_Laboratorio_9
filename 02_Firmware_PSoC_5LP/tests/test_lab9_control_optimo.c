#include <assert.h>
#include <math.h>
#include <stdio.h>

#include "../src/lab9_control_optimo.h"

static void ejecutar_caso(lab9_caso_t caso)
{
    lab9_parametros_t p;
    lab9_estado_t e;
    float x[2] = {0.0f, 0.0f};
    float y;
    float referencia;
    float u;
    float x0_nuevo;
    float x1_nuevo;
    float pico = 0.0f;
    float u_min = 0.0f;
    float u_max = 0.0f;
    int k;

    assert(lab9_cargar_parametros(caso, &p) == 1);
    lab9_reiniciar(&e, 0.0f, 0.0f);

    for (k = 0; k < 600; ++k) {
        referencia = (k >= 32 && k <= 332) ? 0.050f : 0.0f;
        y = p.C[0]*x[0]+p.C[1]*x[1];
        u = lab9_calcular_paso(&p, &e, referencia, y);

        if (y > pico) pico = y;
        if (u < u_min) u_min = u;
        if (u > u_max) u_max = u;
        assert(isfinite(y));
        assert(isfinite(u));
        assert(u >= p.u_min_V-1.0e-6f);
        assert(u <= p.u_max_V+1.0e-6f);

        x0_nuevo = p.A[0][0]*x[0]+p.A[0][1]*x[1]+p.B[0]*u;
        x1_nuevo = p.A[1][0]*x[0]+p.A[1][1]*x[1]+p.B[1]*u;
        x[0] = x0_nuevo;
        x[1] = x1_nuevo;
    }

    assert(pico > 0.049f);
    assert(pico < 0.060f);
    assert(e.saturaciones == 0u);
    assert(e.antiwindup_bloqueos == 0u);
    assert(fabsf(x[1]) < 1.0e-4f);

    printf("Caso %d: pico=%.6f V, u=[%.6f, %.6f] V\n",
        (int)caso, pico, u_min, u_max);
}

int main(void)
{
    lab9_parametros_t parametros;

    assert(lab9_cargar_parametros((lab9_caso_t)0, &parametros) == 0);
    assert(lab9_cargar_parametros(LAB9_CONTROL_CASO_1, 0) == 0);

    ejecutar_caso(LAB9_CONTROL_CASO_1);
    ejecutar_caso(LAB9_CONTROL_CASO_2);
    ejecutar_caso(LAB9_CONTROL_CASO_3);
    puts("Pruebas del nucleo LQR completadas.");
    return 0;
}
