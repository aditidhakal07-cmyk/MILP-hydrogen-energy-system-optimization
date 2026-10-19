# MILP-Based Optimization of a PV-Integrated Hydrogen Energy System

## Project Overview

This repository presents a Mixed-Integer Linear Programming (MILP) framework developed as part of a master's thesis to optimize the annual operation and hydrogen storage capacity of a photovoltaic (PV)-integrated hydrogen energy system for an industrial coffee roasting application.

The optimization is implemented in **MATLAB using the `intlinprog` solver**, considering 8,760 hourly time steps over one year.

The framework evaluates two system configurations:

- **Case 1 – Low-Pressure (LP) Hydrogen Storage:** Hydrogen produced by the electrolyzer is stored directly in low-pressure storage without additional compression.
- **Case 2 – High-Pressure (HP) Hydrogen Storage:** Hydrogen is compressed before storage, introducing additional compressor electricity demand supplied by PV or grid electricity.

## Optimization Framework

The MILP framework minimizes annual grid electricity costs and annualized hydrogen storage costs, while accounting for revenue from surplus PV electricity exported to the grid.

The objective function is:

\[
\min Z = C_{\mathrm{Grid}} + C_{\mathrm{H_2,stor}} - R_{\mathrm{PV}}
\]

The optimization considers:

- Electrolyzer operating limits and binary ON/OFF scheduling.
- Grid electricity allocation to the electrolyzer and site loads.
- Hourly hydrogen production and demand balance.
- Optimal hydrogen storage capacity with a cyclic annual storage condition.
- PV electricity allocation, grid export, and curtailment.
- Additional compressor electricity consumption and supply allocation in Case 2.

### Integration with MATLAB/Simulink

The PV-to-electrolyzer electricity profiles are obtained from a MATLAB/Simulink model, which already accounts for converter losses.

These profiles are used as predefined inputs rather than independently optimized PV conversion outputs. The MILP determines electrolyzer operating states and additional grid electricity requirements while preserving the Simulink-derived PV contribution during operating hours.

## Input Data

Both optimization scripts use the same Excel dataset, containing hourly PV availability, industrial electricity demand, hydrogen demand, electricity prices, feed-in tariffs, and electrolyzer operating parameters.

**Input file:** [Download Input Dataset (Excel)](Input_Data/KK_1140xPV_Master_Optimization_Dataset_MILP.xlsx)

## MATLAB Implementation

The repository includes two condensed MATLAB scripts presenting the MILP formulation for each configuration:
- [Case 1 – Low-Pressure Storage](MATLAB/Condensed_Case1_Script.m) – LP hydrogen storage optimization.
- [Case 2 – High-Pressure Storage](MATLAB/Condensed_Case2_Script.m) – HP hydrogen storage optimization with compressor electricity requirements.

**Requirements:** MATLAB with Optimization Toolbox (`intlinprog`).

The scripts formulate and solve the optimization problem. The condensed versions do not include detailed result exports or plotting routines.

## Detailed Mathematical Formulation

The complete mathematical formulation, including the objective function, decision variables, constraints, modelling assumptions, and solution procedure, is provided in the following PDF excerpt from the master's thesis:

[Theoretical Foundation and MILP Formulation (PDF)](Documentation/Theoretical%20Foundation%20MILP.pdf)

## Project Context

This work forms part of a master's thesis investigating the integration of photovoltaic electricity, water electrolysis, and hydrogen storage for industrial coffee roasting. The MILP framework is used to evaluate optimal energy allocation and hydrogen storage requirements for the two system configurations.


## How to Explore This Repository

Visitors can explore the MATLAB scripts for the two MILP optimization configurations in the [`MATLAB/`](MATLAB/) folder, access the hourly input dataset in [`Input_Data/`](Input_Data/), and refer to the [`Documentation/`](Documentation/) folder for the detailed mathematical formulation extracted from the master's thesis.

The repository is intended to demonstrate the optimization methodology, mathematical modelling, and MATLAB implementation of the proposed hydrogen energy system.

## Author

Aditi Dhakal

Master's Thesis Project | Renewable Energy Systems | Hydrogen Technologies | MILP Optimization
