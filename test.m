% -------------------------------------------------------------------------
% ********** BE COMMANDE OPTIMALE - SUSPENSION SEMI-ACTIVE/ACTIVE *********
% ****************** Lenny LAFFARGUE & Yiannis MANZO **********************
% -------------------------------------------------------------------------
%% Paramétrages
clear all
close all
clc

% *************************************************************************
% PARTIE 1 - ETABLISSEMENT DU MODELE **************************************
% *************************************************************************
%% Constantes
Ms = 280;
Mu = 45;
Ks = 20000;
Kt = 150000;
Cs = 1000;
Ct = 0.0;
%% Représentation d'état
A = [0 1 0 -1 ; -Ks/Ms -Cs/Ms 0 Cs/Ms ; 0 0 0 1 ; Ks/Mu Cs/Mu -Kt/Mu -(Cs+Ct)/Mu];
B = [0 ; 1/Ms ; 0 ; -1/Mu];
E = [0 ; 0 ; -1 ; Ct/Mu];
C = [0 1 0 0 ; 0 0 0 1];
D = [0];

% *************************************************************************
% PARTIE 2 - ANALYSE EN BOUCLE OUVERTE ************************************
% *************************************************************************
%% Création des espaces d'état & fonctions de transfert 
ss_caisse = ss(A,E,C(1,:),D);
ss_roue = ss(A,E,C(2,:),D);
tf_caisse = tf(ss_caisse)
tf_roue = tf(ss_roue)
%% Tracés de Bode
figure(1), bode(tf_caisse), title("Tracé de Bode pour la caisse")
figure(2), bode(tf_roue), title("Tracé de Bode pour la roue")
%% Etude du comportement de la caisse & de la roue à l'encontre d'un trottoir de 8 cm
figure(3)
% ***** Caisse *****
step(0.08*tf_caisse)
info_caisse = stepinfo(0.08*tf_caisse,'SettlingTime',0.05);
ts_caisse = info_caisse.SettlingTime    % Affichage du temps d'établissementg à 95%
over_caisse = info_caisse.Overshoot     % Affichage de l'overshoot (en %)
hold on
% ***** Roue *****
step(0.08*tf_roue)
info_roue = stepinfo(0.08*tf_roue,'SettlingTime',0.05);
ts_roue = info_roue.SettlingTime        % Affichage du temps d'établissementg à 95%
over_roue = info_roue.Overshoot         % Affichage de l'overshoot (en %)
title("Réponses de la caisse et de la roue à un échelon de 0.08 (trottoir de 8cm)")
legend('caisse','roue');

% *************************************************************************
% PARTIE 4.1 - LQR - ESTIMATION DES COEFFS DE Q ***************************
% *************************************************************************
%% Matrices pour la commande LQR
q1 = 4*10^8;
q2 = 1*10^6;
q3 = 2.25*10^10;
q4 = 0;
Q = diag([q1,q2,q3,q4]);
N = 0;
R = 1;
%% Récupération du gain LQ
[K,S,e] = lqr(A,B,Q,R,N);
%% Espace d'état & fonction de transfert associés
A_LQ = A-B*K;
B_LQ = E;
C_LQ = C;
D_LQ = 0;
ss_caisse_LQ = ss(A_LQ,B_LQ,C_LQ(1,:),D_LQ);
ss_roue_LQ = ss(A_LQ,B_LQ,C_LQ(2,:),D_LQ);
tf_caisse_LQ = tf(ss_caisse_LQ)
tf_roue_LQ = tf(ss_roue_LQ)
%% Tracés de Bode - comparaison
figure(4), bode(tf_caisse_LQ), title("Tracé de Bode pour la caisse - LQR version 1")
figure(5), bode(tf_roue_LQ), title("Tracé de Bode pour la roue - LQR version 1")
%% Réponses à un échelon de 0.08 (trottoir de 8cm)
figure(6)
% ***** Caisse *****
step(0.08*tf_caisse_LQ)
info_caisse_LQ = stepinfo(0.08*tf_caisse_LQ,'SettlingTime',0.05);
ts_caisse_LQ = info_caisse_LQ.SettlingTime    % Affichage du temps d'établissementg à 95%
over_caisse_LQ = info_caisse_LQ.Overshoot     % Affichage de l'overshoot (en %)
hold on
% ***** Roue *****
step(0.08*tf_roue_LQ)
info_roue_LQ = stepinfo(0.08*tf_roue_LQ,'SettlingTime',0.05);
ts_roue_LQ = info_roue_LQ.SettlingTime        % Affichage du temps d'établissementg à 95%
over_roue_LQ = info_roue_LQ.Overshoot         % Affichage de l'overshoot (en %)
title("Réponses de la caisse et de la roue à un échelon de 0.08 (trottoir de 8cm)")
legend('caisse','roue');

% *************************************************************************
% PARTIE 4.2 - LQR - AMELIORATION DES COEFFS DE Q *************************
% *************************************************************************
%% Optimisation de q1 - Diminution de la déflexion de l'amortisseur
figure(7)
for i=1:10:100
    q1_var = i*4*10^8;
    Q_var = diag([q1_var,q2,q3,q4]);
    [K_var,S_var,e_var] = lqr(A,B,Q_var,R,N);
    A_LQ_var = A-B*K_var;
    ss_caisse_LQ_var = ss(A_LQ_var,B_LQ,C_LQ(1,:),D_LQ);
    tf_caisse_LQ_var = tf(ss_caisse_LQ_var);
    hold on
    step(tf_caisse_LQ_var*0.08);
    title('Optimisation de q1 - Deflexion - Sur caisse');
    legend show
end
%% Optimisation de q2 - Amélioration du confort passager
figure(8)
for i=1:10:100
    q2_var = i*1*10^6;
    Q_var = diag([q1,q2_var,q3,q4]);
    [K_var,S_var,e_var] = lqr(A,B,Q_var,R,N);
    A_LQ_var = A-B*K_var;
    ss_caisse_LQ_var = ss(A_LQ_var,B_LQ,C_LQ(1,:),D_LQ);
    tf_caisse_LQ_var = tf(ss_caisse_LQ_var);
    hold on
    step(tf_caisse_LQ_var*0.08);
    title('Optimisation de q2 - Confort passager - Sur caisse');
end
%% Optimisation de q3 - Amélioration de la tenue de route
figure(9)
for i=1:10:100
    q3_var = i*2.25*10^10;
    Q_var = diag([q1,q2,q3_var,q4]);
    [K_var,S_var,e_var] = lqr(A,B,Q_var,R,N);
    A_LQ_var = A-B*K_var;
    ss_roue_LQ_var = ss(A_LQ_var,B_LQ,C_LQ(2,:),D_LQ);
    tf_roue_LQ_var = tf(ss_roue_LQ_var);
    hold on
    step(tf_roue_LQ_var*0.08);
    title('Optimisation de q3 - Tenue de route - Sur roue');
end
%% Coefficients qi retenus
q1_var = 10*4*10^8;
q2_var = 30*1*10^6;
q3_var = 100*2.25*10^10;
Q_var = diag([q1_var,q2_var,q3_var,q4]);
%% Commande LQR & nouvelles fonctions de transfert
[K_var,S_var,e_var] = lqr(A,B,Q_var,R,N);
A_LQ_var = A-B*K_var;
ss_caisse_LQ_var = ss(A_LQ_var,B_LQ,C_LQ(1,:),D_LQ);
tf_caisse_LQ_var = tf(ss_caisse_LQ_var)
ss_roue_LQ_var = ss(A_LQ_var,B_LQ,C_LQ(2,:),D_LQ);
tf_roue_LQ_var = tf(ss_roue_LQ_var)
%% Tracé de Bode
figure(10), bode(tf_caisse_LQ_var), title("Tracé de Bode pour la caisse - LQR version finale")
figure(11), bode(tf_roue_LQ_var), title("Tracé de Bode pour la roue - LQR version finale")
%% Réponses à un échelon de 0.08 (trottoir de 8cm)
figure(12)
step(tf_caisse_LQ_var*0.08);
info_caisse_LQ_var = stepinfo(0.08*tf_caisse_LQ_var,'SettlingTime',0.05);
ts_caisse_LQ_var = info_caisse_LQ_var.SettlingTime    % Affichage du temps d'établissementg à 95%
over_caisse_LQ_var = info_caisse_LQ_var.Overshoot     % Affichage de l'overshoot (en %)
hold on
step(tf_roue_LQ_var*0.08);
info_roue_LQ_var = stepinfo(0.08*tf_roue_LQ_var,'SettlingTime',0.05);
ts_roue_LQ_var = info_roue_LQ_var.SettlingTime        % Affichage du temps d'établissementg à 95%
over_roue_LQ_var = info_roue_LQ_var.Overshoot         % Affichage de l'overshoot (en %)
legend('caisse','roue');
title("Réponses de la caisse et de la roue à un échelon de 0.08 (trottoir de 8cm)")

