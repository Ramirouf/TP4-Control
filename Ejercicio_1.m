%% Definiciones globales
s = tf('s');
%% Definir la planta.

%Gp = T_H/V_e;
K_H = 350/250;
Gp = K_H / (400*s+1);
% Este modelo térmico se modela con un equivalente elétrico, donde:
C_p = 1; R_p = 400; K_1 = 1;4; % F; Ohm; °C/V
% El acondicionador del sensor entrega 3,5 V para 350 °C.
% Es decir, para 3,5 V, e=0
% K_s es el sensor con acondicionador

%% Objetivo
% Controlar T a 320 °C, y que entrada al escalón cumpla con:
% e_{ssp} = 0; M_p <= 10 %, t_s < 1500 segundos.
% Para esto, se tiene el siguiente PI.
G_c = 0,4 * (s+0.005399355)/s;

%% Primera Parte: Rediseño Digital:

%%% Diagrama de bloques
% ref -> (+_) -> 
