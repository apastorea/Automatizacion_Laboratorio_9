/* Interfaz del controlador digital y definicion de sus parametros de diseno. */
#ifndef LAB9_CONTROL_OPTIMO_H
#define LAB9_CONTROL_OPTIMO_H

typedef enum {
    LAB9_CONTROL_CASO_1 = 1,
    LAB9_CONTROL_CASO_2 = 2,
    LAB9_CONTROL_CASO_3 = 3
} lab9_caso_t;

/* Parametros inmutables durante un ensayo. A, B y C representan el modelo
 * identificado discreto; Kx y Ki definen el LQR integral; L es la ganancia
 * del estimador actual y los ultimos campos acotan el mando continuo. */
typedef struct {
    float A[2][2];
    float B[2];
    float C[2];
    float Kx[2];
    float Ki;
    float L[2];
    float u_min_V;
    float u_max_V;
} lab9_parametros_t;

/* Memoria dinamica del algoritmo. x_pred es la estimacion a priori para la
 * muestra siguiente y x_control la estimacion corregida usada por el LQR. */
typedef struct {
    float x_pred[2];
    float x_control[2];
    float xi;
    float u_aplicado_V;
    float u_solicitado_V;
    float innovacion_V;
    float error_V;
    unsigned int saturaciones;
    unsigned int antiwindup_bloqueos;
} lab9_estado_t;

/* Carga A, B, C, L, limites y las ganancias del caso solicitado.
 * Retorna 1 si el caso es valido y 0 en caso contrario.
 */
int lab9_cargar_parametros(lab9_caso_t caso, lab9_parametros_t *parametros);

void lab9_reiniciar(lab9_estado_t *estado, float x0_est1, float x0_est2);

/* Ejecuta correccion actual, LQR, saturacion, anti-windup y prediccion.
 * Retorna el mando continuo limitado, antes de cuantizarlo en la HAL.
 */
float lab9_calcular_paso(const lab9_parametros_t *parametros,
                         lab9_estado_t *estado,
                         float referencia_V,
                         float salida_medida_V);

/* Debe llamarse despues de convertir el mando a codigos DAC. Corrige la
 * prediccion con la tension realmente aplicada, no con el mando ideal.
 */
void lab9_corregir_mando_aplicado(const lab9_parametros_t *parametros,
                                  lab9_estado_t *estado,
                                  float mando_real_V);

#endif
