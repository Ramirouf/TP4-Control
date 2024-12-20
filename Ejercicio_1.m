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
G_c_z_bw1 = zpk(minreal(0.4 * (s_bw+0.005399355) /s_bw));
%%%% Backward - T_2 = 40
z = tf('z', T_2);
s_bw = (z-1) / (z*T_2);
G_c_z_bw2 = zpk(minreal(0.4 * (s_bw+0.005399355) /s_bw));

%%%% Forward - T_1 = 200
z = tf('z', T_1);
s_fw = (z-1) / T_1;
G_c_z_fw1 = zpk(minreal(0.4 * (s_fw+0.005399355) /s_fw));
%%%% Forward - T_2 = 40
z = tf('z', T_2);
s_fw = (z-1) / T_2;
G_c_z_fw2 = zpk(minreal(0.4 * (s_fw+0.005399355) /s_fw));

%%%% Tustin - T_1 = 200
z = tf('z', T_1);
s_t = (2/T_1) * (z-1) / (z+1);
G_c_z_t1 = zpk(minreal(0.4 * (s_t+0.005399355) /s_t));
%%%% Tustin - T_2 = 40
z = tf('z', T_2);
s_t = (2/T_2) * (z-1) / (z+1);
G_c_z_t2 = zpk(minreal(0.4 * (s_t+0.005399355) /s_t));

%%% d - Respuestas al escalón en LC para cada uno de los 6 Gc(z), y el
%%% Gc(s)

%G_ = G_c_z_bw1 * Ka * G_p * K_s;


% Discretizar la planta, usando el método de ZOH, por ser usado por los uC.
Gpz = c2d(G_p, T);
% Backward T = 40
G_LAB = G_c_z_bw2 * K_a * Gpz * K_s;
G_LCB = feedback(G_LAB, 1);
% Forward T = 40
G_LAF = G_c_z_fw2 * K_a * Gpz * K_s;
G_LCF = feedback(G_LAF, 1);
% Tustin T = 40
G_LAT = G_c_z_t2 * K_a * Gpz * K_s;
G_LCT = feedback(G_LAT, 1);
figure;
stepplot(320*G_LC, 320*G_LCB, 320*G_LCF, 320*G_LCT);
legend("G LC s", "G LC Backward", "G LC Forward", "G LC Tustin");
title('Respuesta al escalón en LC, para TC y TD (T=40)');
xlabel("Tiempo [s]");
ylabel("Temperatura [°C]");

% Discretizar la planta, usando el método de ZOH y T = 200.
Gpz = c2d(G_p, T_1);
% Backward T = 200
G_LAB = G_c_z_bw1 * K_a * Gpz * K_s;
G_LCB = feedback(G_LAB, 1);
% Forward T = 200
G_LAF = G_c_z_fw1 * K_a * Gpz * K_s;
G_LCF = feedback(G_LAF, 1);
% Tustin T = 200
G_LAT = G_c_z_t1 * K_a * Gpz * K_s;
G_LCT = feedback(G_LAT, 1);
figure;
stepplot(320*G_LC, 320*G_LCB, 320*G_LCF, 320*G_LCT);
legend("G LC s", "G LC Backward", "G LC Forward", "G LC Tustin");
title('Respuesta al escalón en LC, para TC y TD (T=200)');
xlabel("Tiempo [s]");
ylabel("Temperatura [°C]");

% Acciones de control T = 40
u_s = feedback(G_c, K_a * G_p * K_s);
Gpz = c2d(G_p, T);
% Backward T = 40
u_B = feedback(G_c_z_bw2, K_a * Gpz * K_s);
% Forward T = 40
u_F = feedback(G_c_z_fw2, K_a * Gpz * K_s);
% Tustin T = 40
u_T = feedback(G_c_z_t2, K_a * Gpz * K_s);
figure;
stepplot(u_s, u_B, u_F, u_T);
legend("u TC", "u Backward", "u Forward", "u Tustin");
title('Acción de control TC y TD (T=40)');

% Acciones de control T = 200
Gpz = c2d(G_p, T_1);
% Backward T = 200
u_B = feedback(G_c_z_bw1, K_a * Gpz * K_s);
% Forward T = 200
u_F = feedback(G_c_z_fw1, K_a * Gpz * K_s);
% Tustin T = 200
u_T = feedback(G_c_z_t1, K_a * Gpz * K_s);
figure;
stepplot(u_s, u_B, u_F, u_T);
legend("u TC", "u Backward", "u Forward", "u Tustin");
title('Acción de control TC y TD (T=200)');