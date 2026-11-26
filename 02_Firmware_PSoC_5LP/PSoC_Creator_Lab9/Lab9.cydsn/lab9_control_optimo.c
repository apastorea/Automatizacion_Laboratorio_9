/*
 * Laboratorio 9 - Regulador LQR con accion integral.
 *
 * Este modulo contiene el modelo identificado discreto, las ganancias de los
 * tres casos y el estimador actual. Las tensiones se expresan en voltios y la
 * rutina de control se ejecuta una vez por cada periodo de muestreo.
 */
#include "lab9_control_optimo.h"

static float lab9_limitar(float valor, float inferior, float superior)
{
    /* Saturador simetrico en estructura, aunque los limites reales pueden
     * ser asimetricos debido a la etapa analogica de actuacion. */
    if (valor < inferior) return inferior;
    if (valor > superior) return superior;
    return valor;
}

int lab9_cargar_parametros(lab9_caso_t caso, lab9_parametros_t *p)
{
    if (p == 0) return 0;

    /* Modelo identificado discretizado con ZOH y Ts = 2 ms:
     * x[k+1]=A*x[k]+B*u[k], y[k]=C*x[k]. Se usa directamente para el
     * diseno y para el predictor, evitando volver al modelo nominal. */
    p->A[0][0] = 0.802095310f;
    p->A[0][1] = 0.0f;
    p->A[1][0] = -0.249628290f;
    p->A[1][1] = 0.075573620f;
    p->B[0] = -0.631610700f;
    p->B[1] = 0.130459080f;
    p->C[0] = 0.0f;
    p->C[1] = 1.0f;

    /* Ganancia del estimador actual. La correccion se hace con y[k] antes
     * de calcular u[k]; sus polos 0.20 +/- j0.10 dan convergencia rapida. */
    p->L[0] = -1.860494424f;
    p->L[1] = 0.175152235f;
    p->u_min_V = -0.115f;
    p->u_max_V = 0.107f;

    /* Cada caso conserva el mismo modelo y estimador; solo cambia el costo
     * LQR y, por tanto, las ganancias de estado Kx y de integracion Ki. */
    switch (caso) {
    case LAB9_CONTROL_CASO_1:
        p->Kx[0] = -0.052956570f;
        p->Kx[1] = 0.033630708f;
        p->Ki = -0.030993647f;
        break;
    case LAB9_CONTROL_CASO_2:
        p->Kx[0] = -0.579807176f;
        p->Kx[1] = 0.837180560f;
        p->Ki = -0.773844770f;
        break;
    case LAB9_CONTROL_CASO_3:
        p->Kx[0] = -0.608122502f;
        p->Kx[1] = 0.257675755f;
        p->Ki = -0.232969182f;
        break;
    default:
        return 0;
    }

    return 1;
}

void lab9_reiniciar(lab9_estado_t *e, float x0_est1, float x0_est2)
{
    if (e == 0) return;

    /* x_pred es la prediccion a priori usada por el estimador actual;
     * x_control conserva el ultimo estado corregido usado por el regulador. */
    e->x_pred[0] = x0_est1;
    e->x_pred[1] = x0_est2;
    e->x_control[0] = x0_est1;
    e->x_control[1] = x0_est2;
    e->xi = 0.0f;
    e->u_aplicado_V = 0.0f;
    e->u_solicitado_V = 0.0f;
    e->innovacion_V = 0.0f;
    e->error_V = 0.0f;
    e->saturaciones = 0u;
    e->antiwindup_bloqueos = 0u;
}

float lab9_calcular_paso(const lab9_parametros_t *p,
                         lab9_estado_t *e,
                         float referencia_V,
                         float salida_medida_V)
{
    float innovacion;
    float x0;
    float x1;
    float u_solicitado;
    float u_limitado;
    float error;
    unsigned int bloquear_integral;

    if (p == 0 || e == 0 || p->u_max_V <= p->u_min_V) return 0.0f;

    /* Correccion del estimador actual:
     * innovacion=y-C*x_pred; xhat=x_pred+L*innovacion. */
    innovacion = salida_medida_V-
        (p->C[0]*e->x_pred[0]+p->C[1]*e->x_pred[1]);
    x0 = e->x_pred[0]+p->L[0]*innovacion;
    x1 = e->x_pred[1]+p->L[1]*innovacion;

    /* Ley de control con la convencion u=-Kx*xhat-Ki*xi. xi acumula el
     * error r-y sin multiplicar por Ts porque Ki fue calculada para esa
     * realizacion discreta del integrador. */
    u_solicitado = -p->Kx[0]*x0-p->Kx[1]*x1-p->Ki*e->xi;
    u_limitado = lab9_limitar(u_solicitado, p->u_min_V, p->u_max_V);
    if (u_limitado != u_solicitado) ++e->saturaciones;

    error = referencia_V-salida_medida_V;
    /* Anti-windup condicional: se congela xi solamente si el error intenta
     * empujar aun mas el mando fuera del limite que ya esta activo. */
    bloquear_integral = (unsigned int)
        ((u_solicitado > p->u_max_V && error > 0.0f) ||
         (u_solicitado < p->u_min_V && error < 0.0f));
    if (bloquear_integral != 0u) ++e->antiwindup_bloqueos;
    else e->xi += error;

    e->x_control[0] = x0;
    e->x_control[1] = x1;
    e->u_solicitado_V = u_solicitado;
    e->u_aplicado_V = u_limitado;
    e->innovacion_V = innovacion;
    e->error_V = error;

    /* Prediccion para k+1 con el mando saturado. Despues, el nivel hardware
     * puede corregirla por la cuantizacion efectiva de los DAC. */
    e->x_pred[0] = p->A[0][0]*x0+p->A[0][1]*x1+p->B[0]*u_limitado;
    e->x_pred[1] = p->A[1][0]*x0+p->A[1][1]*x1+p->B[1]*u_limitado;
    return u_limitado;
}

void lab9_corregir_mando_aplicado(const lab9_parametros_t *p,
                                  lab9_estado_t *e,
                                  float mando_real_V)
{
    float diferencia;

    if (p == 0 || e == 0) return;
    /* Sustituye en la prediccion el mando continuo por el valor reconstruido
     * desde los codigos DAC. Asi el observador conoce la actuacion real. */
    diferencia = mando_real_V-e->u_aplicado_V;
    e->x_pred[0] += p->B[0]*diferencia;
    e->x_pred[1] += p->B[1]*diferencia;
    e->u_aplicado_V = mando_real_V;
}
