%% Definiciones globales
s = tf('s');
%% Actuador
K_a = 250;

%% Definir la planta.

%Gp = T_H/V_e;
K_H = 350/250;          % °C/V
G_p = K_H / (400*s+1);   
% Este modelo térmico se modela con un equivalente elétrico, donde:
C_p = 1; R_p = 400; K_1 = 1;4; % F; Ohm; °C/V
% El acondicionador del sensor entrega 3,5 V para 350 °C.
% Es decir, para 3,5 V, e=0
% K_s es el sensor CON acondicionador
K_s = 3.5/350;       % V/°C
temp_final = 320;
ref = K_s * temp_final;
%% Objetivo
% Controlar T a 320 °C, y que entrada al escalón cumpla con:
% e_{ssp} = 0; M_p <= 10 %, t_s < 1500 segundos.
% Para esto, se tiene el siguiente PI.
G_c = 0.4 * (s+0.005399355) /s;

%% Primera Parte: Rediseño Digital:

%%% Seleccionar período de muestreo.
% Primero, encuentro FT LC.
G_LA = G_c * K_a * G_p * K_s;
G_LC = zpk(feedback(G_LA,1));

%figure;
%pzmap(G_LC);
Den_G_LC = 400* s*s + 2.4 *s + 0.007559;

w_n = sqrt(0.007559/400);
psita = 2.4 / (400*2*w_n);
w_d = w_n * sqrt(1-psita*psita);
T_d = 2*pi / w_d;
N_d = 10;
T_1 = ceil(T_d / N_d);
N_d = 50;
T_2 = ceil(T_d / N_d);
T = T_2;
%%% c - Aproximaciones
%%%% Backward - T_1 = 200
z = tf('z', T_1);
s_bw = (z-1) / (z*T_1);
% Debo obtener G_c (z), reemplazando s por s_bw en G_c (s).
G_c_z_bw1 = zpk(minreal(0.4 * (s_bw+0.005399355) /s_bw))
%%%% Backward - T_2 = 40
z = tf('z', T_2);
s_bw = (z-1) / (z*T_2);
G_c_z_bw2 = zpk(minreal(0.4 * (s_bw+0.005399355) /s_bw))

%%%% Forward - T_1 = 200
z = tf('z', T_1);
s_fw = (z-1) / T_1;
G_c_z_fw1 = zpk(minreal(0.4 * (s_fw+0.005399355) /s_fw))
%%%% Forward - T_2 = 40
z = tf('z', T_2);
s_fw = (z-1) / T_2;
G_c_z_fw2 = zpk(minreal(0.4 * (s_fw+0.005399355) /s_fw))

%%%% Tustin - T_1 = 200
z = tf('z', T_1);
s_t = (2/T_1) * (z-1) / (z+1);
G_c_z_t1 = zpk(minreal(0.4 * (s_t+0.005399355) /s_t))
%%%% Tustin - T_2 = 40
z = tf('z', T_2);
s_t = (2/T_2) * (z-1) / (z+1);
G_c_z_t2 = zpk(minreal(0.4 * (s_t+0.005399355) /s_t))

%%% d - Respuestas al escalón en LC para cada uno de los 6 Gc(z), y el
%%% Gc(s)

%G_ = G_c_z_bw1 * Ka * G_p * K_s;
figure;
title('Respuesta al escalón a lazo cerrado para controlador en tiempo continuo');
xlabel("Tiempo continuo");
ylabel("Temperatura");

% Discretizar la planta, usando el método de ZOH, por ser usado por los uC.
Gpz = c2d(G_p, T);
%Gpz_T_2 = c2d(G_p, T_2);
% Tustin T = 200
%G_LAz1 = G_c_z_t1 * K_a * Gpz_T_1 * K_s;
%G_LCz1 = feedback(G_LAz1, 1);

% Backward
G_LAB = G_c_z_bw2 * K_a * Gpz * K_s;
% Forward

% Tustin T = 40
G_LATz = G_c_z_t2 * K_a * Gpz * K_s;
G_LCz2 = feedback(G_LAz2, 1);
stepplot(G_LC, G_LCz1, G_LCz2);
legend("G LC s", "G LC Tustin T=200", "G LC Tustin T=40");

% Acciones de control
u_t1 = feedback(G_c_z_t1, K_a*Gpz_T_1*K_s);
u_t2 = feedback(G_c_z_t2, K_a*Gpz_T_2*K_s);
figure;
step(u_t1, u_t2);
legend("Acción de control Tustin para T=200", "Acción de control Tustin para T=40");