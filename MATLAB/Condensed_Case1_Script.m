%% Case 1 - LP Storage
clear; clc;

%% 1. Input data
scriptFolder = fileparts(mfilename('fullpath'));
repoFolder = fileparts(scriptFolder);
inputFile = fullfile(repoFolder, 'Input_Data', 'KK_1140xPV_Master_Optimization_Dataset_MILP.xlsx');

T = readtable(inputFile);
T = T(1:min(8760,height(T)),:); N = height(T);

PV_avail = T.PV_available_kWh;
PV_array_ELY_available = T.PV_array_to_electrolyzer_available_kWh;
PV_ELY_available = T.PV_to_electrolyzer_available_kWh;
H2_demand = T.H2_demand_roaster_kg;
Site_load = T.Total_site_load_kWh;
price = T.Electricity_price_EUR_per_kWh;
feed_in_tariff = T.Feed_in_tariff_EUR_per_kWh;
ELY_available = T.Electrolyzer_available;
ELY_min = T.Electrolyzer_min_load_kWh;
ELY_max = T.Electrolyzer_max_load_kWh;
H2_yield = T.H2_yield_kg_per_kWh(1);

P_elec_max = 10;
LP_tank_cost_EUR_per_kg = 1000;
lifetime = 20; interest = 0.06;
CRF = interest*(1+interest)^lifetime/((1+interest)^lifetime-1);
LP_tank_cost_annual_EUR_per_kg = LP_tank_cost_EUR_per_kg*CRF;

%% 2. Decision-variable indexing
% 1 PV_array_ELY | 2 PV_ELY | 3 Grid_ELY | 4 H2 | 5 LP storage
% 6 PV_site | 7 Grid_site | 8 PV_export | 9 Curtailment | 10 ELY_ON
% 11 Site_PV_binary | 12 LP_capacity

idx_pv_array_ely = 1:N;        idx_pv_ely = N+1:2*N;
idx_grid_ely = 2*N+1:3*N;      idx_h2 = 3*N+1:4*N;
idx_lp = 4*N+1:5*N;            idx_pv_site = 5*N+1:6*N;
idx_grid_site = 6*N+1:7*N;     idx_pv_export = 7*N+1:8*N;
idx_pv_curtail = 8*N+1:9*N;    idx_on = 9*N+1:10*N;
idx_site_binary = 10*N+1:11*N; idx_cap = 11*N+1;
nVars = 11*N+1;
intcon = [idx_on,idx_site_binary];

%% 3. Objective and bounds
f = zeros(nVars,1);
f(idx_grid_ely)=price; f(idx_grid_site)=price;
f(idx_pv_export)=-feed_in_tariff;
f(idx_cap)=LP_tank_cost_annual_EUR_per_kg;

lb = zeros(nVars,1); ub = inf(nVars,1);
ub(idx_pv_array_ely)=PV_array_ELY_available;
ub(idx_pv_ely)=PV_ELY_available;
ub(idx_grid_ely)=ELY_max;
ub(idx_h2)=ELY_max.*H2_yield;
ub(idx_pv_site)=Site_load; ub(idx_grid_site)=Site_load;
ub(idx_pv_export)=PV_avail; ub(idx_pv_curtail)=PV_avail;
ub(idx_on)=ELY_available; ub(idx_site_binary)=1;

M = max(PV_avail)+max(Site_load)+P_elec_max+20;

%% 4. Inequality constraints
A = sparse(0,nVars); b = [];

% Electrolyzer maximum load
A1 = sparse(N,nVars);
for t=1:N
    A1(t,idx_pv_ely(t))=1; A1(t,idx_grid_ely(t))=1;
    A1(t,idx_on(t))=-ELY_max(t);
end
A=[A;A1]; b=[b;zeros(N,1)];

% Electrolyzer minimum load
A2 = sparse(N,nVars);
for t=1:N
    A2(t,idx_pv_ely(t))=-1; A2(t,idx_grid_ely(t))=-1;
    A2(t,idx_on(t))=ELY_min(t);
end
A=[A;A2]; b=[b;zeros(N,1)];

% LP storage capacity
A3 = sparse(N,nVars);
for t=1:N
    A3(t,idx_lp(t))=1; A3(t,idx_cap)=-1;
end
A=[A;A3]; b=[b;zeros(N,1)];

% Remaining PV available to site
A4 = sparse(N,nVars);
for t=1:N
    A4(t,idx_pv_array_ely(t))=1; A4(t,idx_pv_site(t))=1;
end
A=[A;A4]; b=[b;PV_avail];

% PV-first site rule, branch 1
A5 = sparse(N,nVars);
for t=1:N
    A5(t,idx_pv_site(t))=-1; A5(t,idx_site_binary(t))=M;
end
A=[A;A5]; b=[b;M-Site_load];

% PV-first site rule, branch 2
A6 = sparse(N,nVars);
for t=1:N
    A6(t,idx_pv_site(t))=-1;
    A6(t,idx_pv_array_ely(t))=-1;
    A6(t,idx_site_binary(t))=-M;
end
A=[A;A6]; b=[b;-PV_avail];

%% 5. Equality constraints
Aeq = sparse(0,nVars); beq = [];

% PV-first electrolyzer: array side
E1 = sparse(N,nVars);
for t=1:N
    E1(t,idx_pv_array_ely(t))=1;
    E1(t,idx_on(t))=-PV_array_ELY_available(t);
end
Aeq=[Aeq;E1]; beq=[beq;zeros(N,1)];

% PV-first electrolyzer: useful side
E2 = sparse(N,nVars);
for t=1:N
    E2(t,idx_pv_ely(t))=1;
    E2(t,idx_on(t))=-PV_ELY_available(t);
end
Aeq=[Aeq;E2]; beq=[beq;zeros(N,1)];

% Hydrogen production
E3 = sparse(N,nVars);
for t=1:N
    E3(t,idx_h2(t))=1;
    E3(t,idx_pv_ely(t))=-H2_yield;
    E3(t,idx_grid_ely(t))=-H2_yield;
end
Aeq=[Aeq;E3]; beq=[beq;zeros(N,1)];

% Site electricity balance
E4 = sparse(N,nVars);
for t=1:N
    E4(t,idx_pv_site(t))=1; E4(t,idx_grid_site(t))=1;
end
Aeq=[Aeq;E4]; beq=[beq;Site_load];

% Complete PV balance
E5 = sparse(N,nVars);
for t=1:N
    E5(t,idx_pv_array_ely(t))=1; E5(t,idx_pv_site(t))=1;
    E5(t,idx_pv_export(t))=1; E5(t,idx_pv_curtail(t))=1;
end
Aeq=[Aeq;E5]; beq=[beq;PV_avail];

% Cyclic LP-storage balance
E6 = sparse(N,nVars);
for t=1:N
    E6(t,idx_lp(t))=1; E6(t,idx_h2(t))=-1;
    if t==1, E6(t,idx_lp(N))=-1;
    else, E6(t,idx_lp(t-1))=-1; end
end
Aeq=[Aeq;E6]; beq=[beq;-H2_demand];

%% 6. Solve MILP
options = optimoptions("intlinprog","Display","iter","MaxTime",600,...
    "RelativeGapTolerance",1e-6);
[x,fval,exitflag,output] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,options);
if exitflag<=0, error("MILP failed. Exit flag: %d",exitflag); end

