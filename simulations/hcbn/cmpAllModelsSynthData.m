function [llMat, llVarMat] = cmpAllModelsSynthData( D, numMCSims, cfg, logFilename, plotOption )
%CMPALLMODELSSYNTHDATA - compares all the models for hybrid networks
% (CLG, HCBN, MTE, [CBN], [MULTINOMIAL]) with synthetic data generated with
% various different dependencies
%  Inputs:
%   D - the dimensionality of the data.  A value of D maps to a unique
%       graphical model from which the synthetic data was generated from.
%   numMCSims - the number of monte-carlo simulations to run each time to
%               generate average KL Div values
%   cfg - the configuration for the value of D, different configurations of
%         D test different configurations of the discrete variable
%
%  Outputs:
%   resultsMat - 
%     For D=2, resultsMat is a [4 x 4 x 4 x 8 x 7 x <CFG>] matrix of results, 
%     where each dimension is representative of the following:
%       1 >> the copula type.  (1)=Frank, (2)=Gumbel, (3)=Clayton, (4)=Gaussian
%       2 >> the type of distribution for the dependent RV that is
%            continuous, maps to:
%            (1)=Multinomial (2)=Uniform (3)=Gaussian (4)=ThickTailed
%       3 >> dependency amount
%            For archimedean copulas, 
%              (1)=1, (2)=4, (3)=7, (4)=10
%       4 >> the number of samples
%              (1)=250 (2)=500 (3)=750 (4)=1000
%              (5)=1250 (6)=1500 (7)=1750 (8)=2000
%       5 >> the model compared to generative model via KL Divergence
%              (1)-copula estimate w/ rank pseudo-obs, f2 estimate
%              (2)-copula estimate w/ rank pseudo-obs, f2 actual
%              (3)-copula actual, f2 estimate
%              (4)-hcbn (copula estimate w/ ecdf pseudo-obs, f2 estimate)
%              (5)-empirical kernel density estimate of data
%              (6)-mte
%              (7)-clg
%       6 >> the conditional value of X1 for which the KL Divergence was
%            estimated for X2.  The size of this depends on the
%            configuration input.  See below for different configurations
%            and the kind of data they generate
%
%**************************************************************************
%* 
%* Copyright (C) 2016  Kiran Karra <kiran.karra@gmail.com>
%*
%* This program is free software: you can redistribute it and/or modify
%* it under the terms of the GNU General Public License as published by
%* the Free Software Foundation, either version 3 of the License, or
%* (at your option) any later version.
%*
%* This program is distributed in the hope that it will be useful,
%* but WITHOUT ANY WARRANTY; without even the implied warranty of
%* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%* GNU General Public License for more details.
%*
%* You should have received a copy of the GNU General Public License
%* along with this program.  If not, see <http://www.gnu.org/licenses/>.
%* 
%**************************************************************************

% define the parametrization variables
% parametrization variables
global mVec copulaTypeVec alphaVec RhoVecs_2D RhoVecs_3D  
global numModelsCompared numMC bntPath logFile K h continuousDistTypeVec
global plotFlag numTest
global HCBN_LL_MAT_IDX MTE_LL_MAT_IDX CLG_LL_MAT_IDX MULTINOMIAL_LL_MAT_IDX 
global CBN_LL_MAT_IDX REF_LL_MAT_IDX
global NUM_DISCRETE_INTERVALS
global CDE_combinations C1C2C3_combinations dependency_combinations

if(nargin>4)
    plotFlag = plotOption;
else
    plotFlag = 0;
end

K = 50; h = 0.05;      % beta kernel estimation parameters
NUM_DISCRETE_INTERVALS = 10;
bntPath = '../bnt'; addpath(genpath(bntPath));
mVec = 250:250:1000;
copulaTypeVec = {'Frank', 'Gumbel', 'Clayton', 'Gaussian'};
alphaVec = [1 10 20];
RhoVecs_2D = cell(1,length(alphaVec)); 
RhoVecs_2D{1} = [1 -0.9; -0.9 1]; RhoVecs_2D{2} = [1 -0.65; -0.65 1];
RhoVecs_2D{3} = [1 0.35; 0.35 1]; RhoVecs_2D{4} = [1 0.1; 0.1 1];
RhoVecs_3D = cell(1,length(alphaVec));
RhoVecs_3D{1} = [1 .4 .2; .4 1 -.8; .2 -.8 1];
RhoVecs_3D{2} = [1 .1 .3; .1 1 -.6; .3 -.6 1];
RhoVecs_3D{3} = [1 .75 .3; .75 1 -.1; .3 -.1 1];
RhoVecs_3D{4} = [1 -.75 -.3; -.75 1 .1; -.3 .1 1];

numTest = 1000; % the # of samples to generate to calculate likelihood
HCBN_LL_MAT_IDX = 1;
MTE_LL_MAT_IDX = 2;
CLG_LL_MAT_IDX = 3;
MULTINOMIAL_LL_MAT_IDX = 4;
CBN_LL_MAT_IDX = 5;
REF_LL_MAT_IDX = 6;

continuousDistTypeVec = {'Gaussian', 'Uniform', 'Multimodal', 'ThickTailed'}; 
numModelsCompared = 6;
numMC = numMCSims;
logFile = logFilename;

% enumerate all the possible combinations for the 5-D test
CDE_combinations = cell(1,8);
CDE_combinations{1} = {'Gaussian', 'Gaussian', 'Gaussian'};
CDE_combinations{2} = {'Uniform', 'Uniform', 'Uniform'};
CDE_combinations{3} = {'Multimodal', 'Multimodal', 'Multimodal'};
CDE_combinations{4} = {'ThickTailed', 'ThickTailed', 'ThickTailed'};
CDE_combinations{5} = {'Multimodal', 'Uniform', 'Multimodal'};
CDE_combinations{6} = {'Gaussian', 'Multimodal', 'Uniform'};
CDE_combinations{7} = {'Uniform', 'Uniform', 'ThickTailed'};
CDE_combinations{8} = {'Multimodal', 'Gaussian', 'Uniform'};

C1C2C3_combinations = cell(1,4);
C1C2C3_combinations{1} = {'Gaussian', 'Gaussian', 'Gaussian'};
C1C2C3_combinations{2} = {'Frank', 'Gaussian', 'Frank'};
C1C2C3_combinations{3} = {'Clayton', 'Gaussian', 'Clayton'};
C1C2C3_combinations{4} = {'Frank', 'Gaussian', 'Clayton'};

dependency_combinations = cell(1,4);
dependency_combinations{1} = {'Strong', 'Strong', 'Strong'};
dependency_combinations{2} = {'Strong', 'Weak', 'Strong'};
dependency_combinations{3} = {'Weak', 'Strong', 'Weak'};
dependency_combinations{4} = {'Weak', 'Weak', 'Weak'};

if(exist(logFile,'file')==2)
    % delete the file
    delete(logFile);
end

% decide which function to run based on D and the configuration
switch D
    case 2
        switch cfg
            case 1
                [llMat, llVarMat] = runD2CFG1();
            case 2
                [llMat, llVarMat] = runD2CFG2();
            case 3
                [llMat, llVarMat] = runD2CFG3();
            case 4
                [llMat, llVarMat] = runD2CFG4();
            case 5
                [llMat, llVarMat] = runD2CFG5();
            case 6
                [llMat, llVarMat] = runD2CFG6();
            case 7
                [llMat, llVarMat] = runD2CFG7();
            otherwise
                error('Max configurations=7 for D=2');
        end
    case 3
        switch cfg
            case 1
                [llMat, llVarMat] = runD3CFG1();
            case 2
                [llMat, llVarMat] = runD3CFG2();
            case 3
                [llMat, llVarMat] = runD3CFG3();
            case 4
                [llMat, llVarMat] = runD3CFG4();
            case 5
                [llMat, llVarMat] = runD3CFG5();
            otherwise
                error('CFG not valid for D=3!');
        end
    case 5
        switch cfg
            case 1
                [llMat, llVarMat] = runD5CFG1();
            case 2
                [llMat, llVarMat] = runD5CFG2();
            case 3
                [llMat, llVarMat] = runD5CFG3();
            case 4
                [llMat, llVarMat] = runD5CFG4();
            case 5
                [llMat, llVarMat] = runD5CFG5();
            otherwise
                error('CFG not valid for D=5!');
        end
    otherwise
        error('D != 2,3,5 not yet implemented!');
end

end

function [llMat, llVarMat] = runD2CFG1()
% runD2CFG1 - the multinomial probabilities are evenly distributed
probs = [0.25 0.25 0.25 0.25];
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2CFG2()
% runD2CFG2 - the multinomial probabilities are skewed left
probs = [0.5 0.3 0.1 0.1];
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2CFG3()
% runD2CFG2 - the multinomial probabilities are skewed left
probs = fliplr([0.5 0.3 0.1 0.1]);
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2CFG4()
% runD2CFG2 - the multinomial probabilities are skewed right
probs = [0.5 0.5];
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2CFG5()
% runD2CFG2 - the multinomial probabilities are skewed left
probs = [0.7 0.3];
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2CFG6()
% runD2CFG2 - the multinomial probabilities are skewed right
probs = [0.3 0.7];
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2CFG7()
% runD2CFG2 - the multinomial probabilities are skewed right
probs = 0.05*ones(1,20);
[llMat, llVarMat] = runD2(probs);
end

function [llMat, llVarMat] = runD2(a_probs)
global mVec copulaTypeVec alphaVec RhoVecs_2D continuousDistTypeVec 
global numModelsCompared numMC bntPath logFile K h
global plotFlag numTest
global HCBN_LL_MAT_IDX MTE_LL_MAT_IDX CLG_LL_MAT_IDX REF_LL_MAT_IDX
global MULTINOMIAL_LL_MAT_IDX NUM_DISCRETE_INTERVALS CBN_LL_MAT_IDX

a_dist = makedist('Multinomial','Probabilities',a_probs);

% setup the graphical model
aa = 1; bb = 2;
D = 2;
dag = zeros(D,D);
dag(aa,bb) = 1;
discreteNodes = [aa];
nodeNames = {'A', 'B'};
discreteNodeNames = {'A'};

llMCMat = zeros(numModelsCompared,numMC);
llMat = zeros(length(copulaTypeVec),...
              length(continuousDistTypeVec),...
              length(alphaVec),...
              length(mVec),...
              numModelsCompared);
llVarMat = zeros(length(copulaTypeVec),...
              length(continuousDistTypeVec),...
              length(alphaVec),...
              length(mVec),...
              numModelsCompared);

fid = fopen(logFile, 'a');
dispstat('','init'); % One time only initialization
dispstat(sprintf('Begining the simulation...\n'),'keepthis','timestamp');
numTotalLoops = length(copulaTypeVec)*length(continuousDistTypeVec)*length(alphaVec)*length(mVec)*numMC;
progressIdx = 1;
for copulaTypeVecIdx=1:length(copulaTypeVec)
    for continuousDistTypeVecIdx=1:length(continuousDistTypeVec)
        for alphaVecIdx=1:length(alphaVec)
            for mVecIdx=1:length(mVec)
                copulaType = copulaTypeVec{copulaTypeVecIdx};
                continuousDistType = continuousDistTypeVec{continuousDistTypeVecIdx};
                if(strcmp(copulaType, 'Gaussian'))
                    alpha = RhoVecs_2D{alphaVecIdx};        % alpha is Rho here
                else
                    alpha = alphaVec(alphaVecIdx);
                end
                M = mVec(mVecIdx);
                
                %%%%%%%%%%% MAIN SIMULATION CODE %%%%%%%%%%
                progressAmt = progressIdx/numTotalLoops*100;
                if(strcmp(copulaType,'Gaussian'))
                    progressStr = sprintf('copulaType=%s x2DistType=%s rho=%f M=%d || Progress=%0.04f', ...
                                    copulaType, continuousDistType, alpha(1,2), M, progressAmt);
                else
                    progressStr = sprintf('copulaType=%s x2DistType=%s alpha=%d M=%d || Progress=%0.04f', ...
                                    copulaType, continuousDistType, alpha, M, progressAmt);
                end
                dispstat(progressStr,'keepthis','timestamp');
                fprintf(fid, progressStr);
                
                % make the actual copula density, and the partial
                % derivative of the copula function w.r.t. the
                % continuous variable (x_2)
                u = linspace(0,1,K);
                [U1,U2] = ndgrid(u);
                c_actual = reshape( copulapdf(copulaType, [U1(:) U2(:)], alpha), K, K );
                C_actual_discrete_integrate = cumtrapz(u, c_actual, 1);
                
                for mcSimNum=1:numMC
                    dispstat(sprintf('MC Sim=%d', mcSimNum), 'timestamp');
                    U = copularnd(copulaType, alpha, M+numTest);
                    X_hybrid = zeros(M+numTest,2);
                    
                    % make both X1 and X2 multimodal distributions
                    if(strcmp(continuousDistType, 'Multimodal'))
                        xContinuous = [normrnd(-2,0.3,1000,1); normrnd(2,0.8,1000,1)];
                    elseif(strcmp(continuousDistType, 'Uniform'))
                        xContinuous = unifrnd(-2,2,2000,1);
                    elseif(strcmp(continuousDistType, 'UnimodalSkewed'))
                        xContinuous = betarnd(2,5,2000,1);
                    elseif(strcmp(continuousDistType, 'Gaussian'))
                        xContinuous = normrnd(2,0.5,2000,1);
                    elseif(strcmp(continuousDistType, 'ThickTailed'))
                        xContinuous = trnd(1, 2000, 1);
                    else
                        error('Unknown X2 Dist Type!');
                    end
                    xContinuous = xContinuous(randperm(2000),:);     % permute for evenness of samples

                    [fContinous,xiContinuous] = emppdf(xContinuous,0);
                    FContinuous = empcdf(xContinuous,0);
                    continuousDistInfo = rvEmpiricalInfo(xiContinuous,fContinous,FContinuous);
                    X_hybrid(:,1) = a_dist.icdf(U(:,1));
                    for ii=1:M+numTest
                        X_hybrid(ii,2) = continuousDistInfo.icdf(U(ii,2));
                    end
                    % generate train and test datasets
                    X_hybrid_test = X_hybrid(M+1:end,:);
                    X_hybrid = X_hybrid(1:M,:);
                    
                    [fAest,xAest] = emppdf(X_hybrid(:,1),1);
                    FAest = empcdf(X_hybrid(:,1),1);
                    distAEst = rvEmpiricalInfo(xAest,fAest,FAest);

                    [fBest,xBest] = emppdf(X_hybrid(:,2),0); FBest = empcdf(X_hybrid(:,2),0);
                    distBEst = rvEmpiricalInfo(xBest,fBest,FBest);

                    hcbnObj = hcbn(bntPath, X_hybrid, nodeNames, discreteNodeNames, K, h, dag); 
                    mtebnObj = mtebn(X_hybrid, discreteNodes, dag);
                    clgbnObj = clgbn(X_hybrid, discreteNodes, dag);
                    multinomialbnObj = multinomialbn(X_hybrid, discreteNodes, dag, NUM_DISCRETE_INTERVALS);
                    cbnObj = cbn(bntPath, X_hybrid, nodeNames, dag);

                    X_hybrid_continued = X_hybrid;
                    X_hybrid_continued(:,1) = continueRv(X_hybrid(:,1));
                    % generate pseudo-observations
                    U_hybrid_continued = pseudoobs(X_hybrid_continued, 'ecdf', 100);
                    c_est = empcopulapdf(U_hybrid_continued, h, K, 'betak');
                    C_est_discrete_integrate = cumtrapz(u, c_est, 1);
                    
                    if(plotFlag)
                        % plot some conditional distributions from the known copula and known
                        % marginal distributions
                        x1_discrete_conditional_vec = 1:1:length(a_probs);
                        for x1_discrete_conditional=x1_discrete_conditional_vec
                            X_continuous_subset = [];
                            for jj=1:M
                                if(X_hybrid(jj,1)==x1_discrete_conditional)
                                    X_continuous_subset = [X_continuous_subset; X_hybrid(jj,2)];
                                end
                            end

                            % estimate the empirical PDF/CDF for this
                            isdiscrete = 0;
                            [f_kde,xi_kde] = emppdf(X_continuous_subset, isdiscrete);
                            F_kde = empcdf(X_continuous_subset, isdiscrete);
                            conditionalKDE = rvEmpiricalInfo(xi_kde, f_kde, F_kde);

                            fx2_givenx1_generative = zeros(1,length(xiContinuous));
                            fx2_givenx1_copulaestf2est = zeros(1,length(xiContinuous));
                            fx2_givenx1_copulaestf2Actual = zeros(1,length(xiContinuous));
                            fx2_givenx1_copulaActualf2est = zeros(1,length(xiContinuous));
                            fx2_givenx1_copulahcbnf2hcbn = zeros(1,length(xiContinuous));
                            fx2_givenx1_copulahcbnf2Actual = zeros(1,length(xiContinuous));

                            fx2_givenx1_clg = zeros(1,length(xiContinuous));
                            fx2_givenx1_mte = zeros(1,length(xiContinuous));
                            fx2_givenx1_conditionalKDE = zeros(1,length(xiContinuous));

                            copulaActual = zeros(1,length(xiContinuous));
                            copulaEst = zeros(1,length(xiContinuous));
                            copulaHcbn = zeros(1,length(xiContinuous));
                            f2Actual = zeros(1,length(xiContinuous));
                            f2Est = zeros(1,length(xiContinuous));
                            f2Hcbn = zeros(1,length(xiContinuous));
                            u2Val = zeros(1,length(xiContinuous));

                            % compute the conditional density w/ the formula
                            % given by Eq.9 in Joint Regression 
                            % Analysis of Correlated Data Using Gaussian 
                            % Copulas -- Biometrics 2009
                            % Authors: Song, Li, Yuan
                            fX1 = a_dist.pdf(x1_discrete_conditional);
                            fX1_hat = distAEst.pdf(x1_discrete_conditional);
                            for ii=1:length(xiContinuous)
                                xiContinuous_val = xiContinuous(ii);
                                uuGenerative1 = [a_dist.cdf(x1_discrete_conditional) continuousDistInfo.cdf(xiContinuous_val)];
                                uuGenerative2 = [a_dist.cdf(x1_discrete_conditional-1) continuousDistInfo.cdf(xiContinuous_val)];

                                uuEst1 = [distAEst.cdf(x1_discrete_conditional) ...
                                          distBEst.cdf(xiContinuous_val)];
                                uuEst2 = [distAEst.cdf(x1_discrete_conditional-1) ...
                                          distBEst.cdf(xiContinuous_val)];
                                C_partial_X1X2 = empcopulaval(C_actual_discrete_integrate, uuGenerative1,1/K)-empcopulaval(C_actual_discrete_integrate, uuGenerative2,1/K);
                                C_partial_hat_X1X2 = empcopulaval(C_est_discrete_integrate, uuEst1,1/K) - empcopulaval(C_est_discrete_integrate, uuEst2,1/K);
                                C_partial_hcbn = empcopulaval(hcbnObj.copulaFamilies{2}.C_discrete_integrate, fliplr(uuEst1),1/K) - empcopulaval(hcbnObj.copulaFamilies{2}.C_discrete_integrate, fliplr(uuEst2),1/K);

                                fX2 = continuousDistInfo.pdf(xiContinuous_val);
                                fX2_hat = distBEst.pdf(xiContinuous_val);                                                                            % was estimated w/ [u2 u1]
                                f_x2_hcbn = hcbnObj.empInfo{2}.pdf(xiContinuous_val);

                                fx2_givenx1_generative(ii) = C_partial_X1X2*fX2/fX1;
                                fx2_givenx1_copulaestf2est(ii) = C_partial_hat_X1X2*fX2_hat/fX1_hat;
                                fx2_givenx1_copulaestf2Actual(ii) = C_partial_hat_X1X2*fX2/fX1;
                                fx2_givenx1_copulaActualf2est(ii) = C_partial_X1X2*fX2_hat/fX1_hat;
                                fx2_givenx1_copulahcbnf2hcbn(ii) = hcbnObj.computeMixedConditionalProbability_(...
                                    [x1_discrete_conditional xiContinuous_val], [bb aa], bb);
                                fx2_givenx1_copulahcbnf2Actual(ii) = C_partial_hcbn*fX2/fX1;

                                fx2_givenx1_clg(ii) = normpdf(xiContinuous_val, clgbnObj.bnParams{2}{x1_discrete_conditional}.Mean, clgbnObj.bnParams{2}{x1_discrete_conditional}.Covariance);
                                fx2_givenx1_mte(ii) = mtebnObj.bnParams{2}{x1_discrete_conditional}.mte_info.pdf(xiContinuous_val);
                                fx2_givenx1_conditionalKDE(ii) = conditionalKDE.pdf(xiContinuous_val);

                                copulaActual(ii) = C_partial_X1X2;
                                copulaEst(ii) = C_partial_hat_X1X2;
                                copulaHcbn(ii) = C_partial_hcbn;
                                f2Actual(ii) = fX2;
                                f2Est(ii) = fX2_hat;
                                f2Hcbn(ii) = f_x2_hcbn;
                                u2Val(ii) = uuGenerative1(2);
                            end

                            % plot the actual vs the copula version and compare the differences
                            fig1 = figure(1); subplot(2,2,1);
                            plot(xiContinuous, fx2_givenx1_generative, 'b*-', ...
                                 xiContinuous, fx2_givenx1_copulaestf2est, ...
                                 xiContinuous, fx2_givenx1_copulaestf2Actual, ...
                                 xiContinuous, fx2_givenx1_copulaActualf2est, ...
                                 xiContinuous, fx2_givenx1_copulahcbnf2hcbn, 'o-', ...
                                 xiContinuous, fx2_givenx1_copulahcbnf2Actual); 
                            grid on; title(sprintf('X_1=%d',x1_discrete_conditional));
                            h_legend1 = legend('$c*f(x_2)$', ...
                                '$\hat{c}_{ECDF}*\hat{f}(x_2)$', ...
                                '$\hat{c}_{ECDF}*f(x_2)$', ...
                                '$c*\hat{f}(x_2)$', ...
                                '$\hat{c}_{HCBN-RANK}*\hat{f}(x_2)_{HCBN}$', ...
                                '$\hat{c}_{HCBN-RANK}*f(x_2)$');
                            set(h_legend1,'FontSize',12);
                            set(h_legend1,'Interpreter','latex')

                            subplot(2,2,2);
                            plot(xiContinuous, fx2_givenx1_generative, 'b*-', ...
                                 xiContinuous, fx2_givenx1_conditionalKDE, ...
                                 xiContinuous, fx2_givenx1_mte, ...
                                 xiContinuous, fx2_givenx1_clg); 
                            grid on; title(sprintf('X_1=%d EstimationSize=%d',x1_discrete_conditional, length(X_continuous_subset)));
                            h_legend2 = legend('$c*f(x_2)$', 'KDE', 'MTE', 'CLG');
                            set(h_legend2,'FontSize',12);
                            set(h_legend2,'Interpreter','latex')

                            subplot(2,2,3);
                            plot(u2Val, copulaActual, ...
                                 u2Val, copulaEst, ...
                                 u2Val, copulaHcbn);
                            grid on;
                            if(strcmpi(copulaType,'Gaussian'))
                                alphaDisp = alpha(1,2);
                            else
                                alphaDisp = alpha;
                            end
                            title(sprintf('%s(%0.02f) Marginal Copula u_1=%0.02f', copulaType, alphaDisp, uuGenerative1(1)));
                            h_legend3 = legend('$c$', '$\hat{c}_{ECDF}$', '$\hat{c}_{HCBN-RANK}$');
                            xlabel('u_2');
                            set(h_legend3,'FontSize',12);
                            set(h_legend3,'Interpreter','latex')

                            subplot(2,2,4);
                            plot(xiContinuous, f2Actual, ...
                                 xiContinuous, f2Est, 'k',...
                                 xiContinuous, f2Hcbn, 'rp');
                            grid on;
                            h_legend4 = legend('$f(x_2)$', '$\hat{f}(x_2)$', '$\hat{f}(x_2)_{HCBN}$');
                            set(h_legend4,'FontSize',12);
                            set(h_legend4,'Interpreter','latex')
                            xlabel('x_2');
                            title(sprintf('%s M=%d\n', continuousDistType, M));

                            pause;
                            clf(fig1);
                        end
                    end
                    
                    % calculate the reference LL
                    refLL = 0;
                    for ii=1:numTest
                        xx = X_hybrid_test(ii,:);
                        uu_continuous = continuousDistInfo.cdf(xx(2));
                        uu1 = [a_dist.cdf(xx(1)) uu_continuous];
                        uu2 = [a_dist.cdf(xx(1)-1) uu_continuous];
                        totalProb = continuousDistInfo.pdf(xx(2)) * ...
                            (empcopulaval(C_actual_discrete_integrate, uu1,1/K) - empcopulaval(C_actual_discrete_integrate, uu2,1/K));
                        if(totalProb<1e-5)
                            totalProb = 1e-5;   % PUT BREAK POINT HERE IF YOU WANT TO DEBUG
                        end
                        refLL = refLL + log(totalProb);
                    end
                    
                    % calculate LL values and assign to llDivMCMat
                    hcbnLL = hcbnObj.dataLogLikelihood(X_hybrid_test);
                    mteLL = mtebnObj.dataLogLikelihood(X_hybrid_test);
                    clgLL = clgbnObj.dataLogLikelihood(X_hybrid_test);
                    multinomialLL = multinomialbnObj.dataLogLikelihood(X_hybrid_test);
                    cbnLL = cbnObj.dataLogLikelihood(X_hybrid_test);
                    
                    % assign LL values to matrix
                    llMCMat(HCBN_LL_MAT_IDX,mcSimNum) = hcbnLL;
                    llMCMat(MTE_LL_MAT_IDX,mcSimNum) = mteLL;
                    llMCMat(CLG_LL_MAT_IDX,mcSimNum) = clgLL;
                    llMCMat(MULTINOMIAL_LL_MAT_IDX,mcSimNum) = multinomialLL;
                    llMCMat(REF_LL_MAT_IDX,mcSimNum) = refLL;
                    llMCMat(CBN_LL_MAT_IDX,mcSimNum) = cbnLL;
                    
                    progressIdx = progressIdx + 1;
                end
                meanLLDivMCMat = mean(llMCMat,2);
                varLLDivMCMat = mean(llMCMat.^2,2)-meanLLDivMCMat.^2;
                
                progressStr = sprintf('MEAN{refLL}=%f VAR{refLL}=%f', ...
                    meanLLDivMCMat(REF_LL_MAT_IDX), varLLDivMCMat(REF_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{hcbnLL}=%f VAR{hcbnLL}=%f', ...
                    meanLLDivMCMat(HCBN_LL_MAT_IDX), varLLDivMCMat(HCBN_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{cbnLL}=%f VAR{cbnLL}=%f', ...
                    meanLLDivMCMat(CBN_LL_MAT_IDX), varLLDivMCMat(CBN_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{mteLL}=%f VAR{mteLL}=%f', ...
                    meanLLDivMCMat(MTE_LL_MAT_IDX), varLLDivMCMat(MTE_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{clgLL}=%f VAR{clgLL}=%f', ...
                    meanLLDivMCMat(CLG_LL_MAT_IDX), varLLDivMCMat(CLG_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{multinomialLL}=%f VAR{multinomialLL}=%f\n', ...
                    meanLLDivMCMat(MULTINOMIAL_LL_MAT_IDX), varLLDivMCMat(MULTINOMIAL_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                
                llMat(copulaTypeVecIdx, ...
                        continuousDistTypeVecIdx,...
                        alphaVecIdx,...
                        mVecIdx,:) = meanLLDivMCMat(:);
                     
                llVarMat(copulaTypeVecIdx, ...
                         continuousDistTypeVecIdx,...
                         alphaVecIdx,...
                         mVecIdx,:) = varLLDivMCMat(:);
                %%%%%%%%%%% END OF MAIN SIMULATION CODE %%%%%%%%%%
            end
        end
    end
end

dispstat('Finished.','keepprev');
fclose(fid);

end

function [llMat, llVarMat] = runD3CFG1()
% runD2CFG1 - the multinomial probabilities are evenly distributed
probsA = [0.25 0.25 0.25 0.25];
probsB = [0.25 0.25 0.25 0.25];
[llMat, llVarMat] = runD3(probsA, probsB);
end

function [llMat, llVarMat] = runD3CFG2()
% runD2CFG2 - the multinomial probabilities are skewed left
probsA = [0.5 0.3 0.1 0.1];
probsB = [0.5 0.3 0.1 0.1];
[llMat, llVarMat] = runD3(probsA, probsB);
end

function [llMat, llVarMat] = runD3CFG3()
% runD2CFG2 - the multinomial probabilities are skewed right
probsA = [0.3 0.7];
probsB = [0.3 0.7];
[llMat, llVarMat] = runD3(probsA, probsB);
end

function [llMat, llVarMat] = runD3CFG4()
% runD2CFG2 - the multinomial probabilities are skewed left and right
% oppositely
probsA = [0.5 0.3 0.1 0.1];
probsB = fliplr([0.5 0.3 0.1 0.1]);
[llMat, llVarMat] = runD3(probsA, probsB);
end

function [llMat, llVarMat] = runD3CFG5()
% runD2CFG2 - the multinomial probabilities are skewed right and left
% oppositely
probsA = [0.3 0.7];
probsB = fliplr([0.3 0.7]);
[llMat, llVarMat] = runD3(probsA, probsB);
end


function [llMat, llVarMat] = runD3(a_probs, b_probs)
global mVec copulaTypeVec alphaVec RhoVecs_3D continuousDistTypeVec 
global numModelsCompared numMC bntPath logFile K h plotFlag numTest
global HCBN_LL_MAT_IDX MTE_LL_MAT_IDX CLG_LL_MAT_IDX REF_LL_MAT_IDX
global MULTINOMIAL_LL_MAT_IDX NUM_DISCRETE_INTERVALS CBN_LL_MAT_IDX

a_dist = makedist('Multinomial','Probabilities', a_probs);
b_dist = makedist('Multinomial','Probabilities', b_probs);

% setup the graphical model
aa = 1; bb = 2; cc = 3;
D = 3;
dag = zeros(D,D);
dag(aa,cc) = 1;
dag(bb,cc) = 1;
discreteNodes = [aa bb];
nodeNames = {'A', 'B', 'C'};
discreteNodeNames = {'A','B'};

llMCMat = zeros(numModelsCompared,numMC);
llMat = zeros(length(copulaTypeVec),...
              length(continuousDistTypeVec),...
              length(alphaVec),...
              length(mVec),...
              numModelsCompared);
llVarMat = zeros(length(copulaTypeVec),...
              length(continuousDistTypeVec),...
              length(alphaVec),...
              length(mVec),...
              numModelsCompared);
          
fid = fopen(logFile, 'a');
dispstat('','init'); % One time only initialization
dispstat(sprintf('Begining the simulation...'),'keepthis','timestamp');
numTotalLoops = length(copulaTypeVec)*length(continuousDistTypeVec)*length(alphaVec)*length(mVec)*numMC;
progressIdx = 1;
for copulaTypeVecIdx=1:length(copulaTypeVec)
    for continuousDistTypeVecIdx=1:length(continuousDistTypeVec)
        for alphaVecIdx=1:length(alphaVec)
            for mVecIdx=1:length(mVec)
                copulaType = copulaTypeVec{copulaTypeVecIdx};
                continuousDistType = continuousDistTypeVec{continuousDistTypeVecIdx};
                if(strcmp(copulaType, 'Gaussian'))
                    Rho = RhoVecs_3D{alphaVecIdx};        % alpha is Rho here
                else
                    alpha = alphaVec(alphaVecIdx);
                end
                M = mVec(mVecIdx);
                
                %%%%%%%%%%% MAIN SIMULATION CODE %%%%%%%%%%
                for mcSimNum=1:numMC
                    progressAmt = progressIdx/numTotalLoops*100;
                    if(strcmp(copulaType,'Gaussian'))
                        progressStr = sprintf('copulaType=%s x3DistType=%s rho=%f M=%d MC Sim# = %d || Progress=%0.04f', ...
                                        copulaType, continuousDistType, Rho(1,2), M, mcSimNum, progressAmt);
                    else
                        progressStr = sprintf('copulaType=%s x3DistType=%s alpha=%d M=%d MC Sim# = %d || Progress=%0.04f', ...
                                        copulaType, continuousDistType, alpha, M, mcSimNum, progressAmt);
                    end
                    dispstat(progressStr,'keepthis','timestamp');
                    fprintf(fid, progressStr);
                    
                    % generate the copula random variates
                    if(strcmp(copulaType, 'Frank'))
                        u_X1X2X3 = frankcopularnd(M+numTest, D, alpha);
                    elseif(strcmp(copulaType, 'Gumbel'))
                        u_X1X2X3 = gumbelcopularnd(M+numTest, D, alpha);
                    elseif(strcmp(copulaType, 'Clayton'))
                        u_X1X2X3 = claytoncopularnd(M+numTest, D, alpha);
                    elseif(strcmp(copulaType, 'Gaussian'))
                        u_X1X2X3 = copularnd('Gaussian', Rho, M+numTest);
                    else
                        error('Copula Type not recognized!\n');
                    end
                    X_hybrid = zeros(M+numTest,D);
                    
                    if(strcmp(continuousDistType, 'Multimodal'))
                        xContinuous = [normrnd(-2,0.3,1000,1); normrnd(2,0.8,1000,1)];
                    elseif(strcmp(continuousDistType, 'Uniform'))
                        xContinuous = unifrnd(-2,2,2000,1);
                    elseif(strcmp(continuousDistType, 'UnimodalSkewed'))
                        xContinuous = betarnd(2,5,2000,1);
                    elseif(strcmp(continuousDistType, 'Gaussian'))
                        xContinuous = normrnd(2,0.5,2000,1);
                    elseif(strcmp(continuousDistType, 'ThickTailed'))
                        xContinuous = trnd(1, 2000, 1);
                    else
                        error('Unknown X3 Dist Type!');
                    end
                    xContinuous = xContinuous(randperm(2000),:);     % permute for evenness of samples
                    
                    [fContinous,xiContinuous] = emppdf(xContinuous,0);
                    FContinuous = empcdf(xContinuous,0);
                    continuousDistInfo = rvEmpiricalInfo(xiContinuous,fContinous,FContinuous);
                    X_hybrid(:,1) = a_dist.icdf(u_X1X2X3(:,1));
                    X_hybrid(:,2) = b_dist.icdf(u_X1X2X3(:,2));
                    for ii=1:M+numTest
                        X_hybrid(ii,3) = continuousDistInfo.icdf(u_X1X2X3(ii,3));
                    end
                    % generate train and test datasets
                    X_hybrid_test = X_hybrid(M+1:end,:);
                    X_hybrid = X_hybrid(1:M,:);
                    
                    isdiscrete = 1;
                    [fAest,xAest] = emppdf(X_hybrid(:,1),isdiscrete);
                    FAest = empcdf(X_hybrid(:,1),isdiscrete);
                    distAEst = rvEmpiricalInfo(xAest,fAest,FAest);
                    
                    [fBest,xBest] = emppdf(X_hybrid(:,2),isdiscrete);
                    FBest = empcdf(X_hybrid(:,2),isdiscrete);
                    distBEst = rvEmpiricalInfo(xBest,fBest,FBest);
                    
                    isdiscrete = 0;
                    [fCest,xCest] = emppdf(X_hybrid(:,3),isdiscrete); 
                    FCest = empcdf(X_hybrid(:,3),isdiscrete);
                    distCEst = rvEmpiricalInfo(xCest,fCest,FCest);
                    
                    hcbnObj = hcbn(bntPath, X_hybrid, nodeNames, discreteNodeNames, K, h, dag); 
                    mtebnObj = mtebn(X_hybrid, discreteNodes, dag);
                    clgbnObj = clgbn(X_hybrid, discreteNodes, dag);
                    multinomialbnObj = multinomialbn(X_hybrid, discreteNodes, dag, NUM_DISCRETE_INTERVALS);
                    cbnObj = cbn(bntPath, X_hybrid, discreteNodes, dag);
                    
                    X_hybrid_continued = X_hybrid;
                    X_hybrid_continued(:,1) = continueRv(X_hybrid(:,1));
                    X_hybrid_continued(:,2) = continueRv(X_hybrid(:,2));
                    
                    U_hybrid_continued = pseudoobs(X_hybrid_continued);
                    
                    % setup all the copula calculations for querying after
                    u = linspace(0,1,K); [U1_3,U2_3,U3_3] = ndgrid(u); [U1_2,U2_2] = ndgrid(u);
                    c_est_X1X2X3 = empcopulapdf(U_hybrid_continued, h, K, 'betak');
                    C_est_X1X2X3 = cumtrapz(u,cumtrapz(u,cumtrapz(u,c_est_X1X2X3,1),2),3);
                    C_est_X1X2X3_discrete_integrate = cumtrapz(u,cumtrapz(u,c_est_X1X2X3,1),2);
                    c_est_X1X2 = empcopulapdf(U_hybrid_continued(:,1:2), h, K, 'betak');
                    C_est_X1X2 = cumtrapz(u,cumtrapz(u,c_est_X1X2,1),2);
                    C_est_X1X2_discrete_integrate = C_est_X1X2;

                    if(strcmp(copulaType, 'Frank'))
                        c_actual_X1X2X3 = reshape(frankcopulapdf([U1_3(:) U2_3(:) U3_3(:)], alpha),K,K,K);
                        c_actual_X1X2 = reshape(frankcopulapdf([U1_2(:) U2_2(:)], alpha),K,K);
                    elseif(strcmp(copulaType, 'Gumbel'))
                        c_actual_X1X2X3 = reshape(gumbelcopulapdf([U1_3(:) U2_3(:) U3_3(:)], alpha),K,K,K);
                        c_actual_X1X2 = reshape(gumbelcopulapdf([U1_2(:) U2_2(:)], alpha),K,K);
                    elseif(strcmp(copulaType, 'Clayton'))
                        c_actual_X1X2X3 = reshape(claytoncopulapdf([U1_3(:) U2_3(:) U3_3(:)], alpha),K,K,K);
                        c_actual_X1X2 = reshape(claytoncopulapdf([U1_2(:) U2_2(:)], alpha),K,K);
                    elseif(strcmp(copulaType, 'Gaussian'))
                        c_actual_X1X2X3 = reshape(copulapdf('Gaussian', [U1_3(:) U2_3(:) U3_3(:)], Rho),K,K,K);
                        c_actual_X1X2 = reshape(copulapdf('Gaussian', [U1_2(:) U2_2(:)], Rho(1:2,1:2)),K,K);
                    else
                        error('Copula Type not recognized!\n');
                    end
                    C_actual_X1X2X3_discrete_integrate = cumtrapz(u,cumtrapz(u, c_actual_X1X2X3, 1),2);
                    C_actual_X1X2_discrete_integrate = cumtrapz(u,cumtrapz(u, c_actual_X1X2, 1),2);
                    %%%%%%%%%%%%%%%%%%%%%%%
                    
                    if(plotFlag)
                        x1_discrete_conditional_vec = 1:1:length(a_probs);
                        x2_discrete_conditional_vec = 1:1:length(b_probs);
                        for x1_discrete_conditional=x1_discrete_conditional_vec
                            for x2_discrete_conditional=x2_discrete_conditional_vec

                                % generate the continuous subset
                                X_continuous_subset = [];
                                for jj=1:M
                                    if(X_hybrid(jj,1)==x1_discrete_conditional && X_hybrid(jj,2)==x2_discrete_conditional)
                                        X_continuous_subset = [X_continuous_subset; X_hybrid(jj,3)];
                                    end
                                end

                                % estimate the empirical PDF/CDF for this
                                isdiscrete = 0;
                                [f_kde,xi_kde] = emppdf(X_continuous_subset, isdiscrete);
                                F_kde = empcdf(X_continuous_subset, isdiscrete);
                                conditionalKDE = rvEmpiricalInfo(xi_kde, f_kde, F_kde);

                                fx3_givenx1x2_copula = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_copulaestf3est = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_copulaestf3Actual = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_copulaActualf3est = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_hcbn = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_clg = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_mte = zeros(1,length(xiContinuous));
                                fx3_givenx1x2_conditionalKDE = zeros(1,length(xiContinuous));

                                % compute the conditional density w/ the formula
                                % given by Eq.9 in Joint Regression 
                                % Analysis of Correlated Data Using Gaussian 
                                % Copulas -- Biometrics 2009
                                % Authors: Song, Li, Yuan
                                for ii=1:length(xiContinuous)
                                    xiContinuous_val = xiContinuous(ii);
                                    uuGenerativeX1X2X3_1 = [a_dist.cdf(x1_discrete_conditional) ...
                                                            b_dist.cdf(x2_discrete_conditional) ...
                                                            continuousDistInfo.cdf(xiContinuous_val)];
                                    uuGenerativeX1X2X3_2 = [a_dist.cdf(x1_discrete_conditional-1) ...
                                                            b_dist.cdf(x2_discrete_conditional) ...
                                                            continuousDistInfo.cdf(xiContinuous_val)];
                                    uuGenerativeX1X2X3_3 = [a_dist.cdf(x1_discrete_conditional) ...
                                                            b_dist.cdf(x2_discrete_conditional-1) ...
                                                            continuousDistInfo.cdf(xiContinuous_val)];
                                    uuGenerativeX1X2X3_4 = [a_dist.cdf(x1_discrete_conditional-1) ...
                                                            b_dist.cdf(x2_discrete_conditional-1) ...
                                                            continuousDistInfo.cdf(xiContinuous_val)];
                                    uuGenerativeX1X2_1 = uuGenerativeX1X2X3_1(1:2);
                                    uuGenerativeX1X2_2 = uuGenerativeX1X2X3_2(1:2);
                                    uuGenerativeX1X2_3 = uuGenerativeX1X2X3_3(1:2);
                                    uuGenerativeX1X2_4 = uuGenerativeX1X2X3_4(1:2);

                                    uuEstX1X2X3_1 = [distAEst.cdf(x1_discrete_conditional) ...
                                                     distBEst.cdf(x2_discrete_conditional) ...
                                                     distCEst.cdf(xiContinuous_val)];
                                    uuEstX1X2X3_2 = [distAEst.cdf(x1_discrete_conditional-1) ...
                                                     distBEst.cdf(x2_discrete_conditional) ...
                                                     distCEst.cdf(xiContinuous_val)];
                                    uuEstX1X2X3_3 = [distAEst.cdf(x1_discrete_conditional) ...
                                                     distBEst.cdf(x2_discrete_conditional-1) ...
                                                     distCEst.cdf(xiContinuous_val)];
                                    uuEstX1X2X3_4 = [distAEst.cdf(x1_discrete_conditional-1) ...
                                                     distBEst.cdf(x2_discrete_conditional-1) ...
                                                     distCEst.cdf(xiContinuous_val)];
                                    uuEstX1X2_1 = uuEstX1X2X3_1(1:2);
                                    uuEstX1X2_2 = uuEstX1X2X3_2(1:2);
                                    uuEstX1X2_3 = uuEstX1X2X3_3(1:2);
                                    uuEstX1X2_4 = uuEstX1X2X3_4(1:2);

    % % %                                 uuHcbnX1X2X3 = [hcbnObj.empInfo{1}.distribution(x1_discrete_conditional) ...
    % % %                                                 hcbnObj.empInfo{2}.distribution(x2_discrete_conditional) ...
    % % %                                                 hcbnObj.empInfo{3}.cdf(xiContinuous_val)];
    % % %                                 uuHcbnX1X2X3 = uuHcbnX1X2X3;
    % % %                                 uuHcbnX1X2 = uuHcbnX1X2X3(1:2);

                                    C_actual_partial_X1X2X3 = empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_1,1/K) - ...
                                                       empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_2,1/K) - ...
                                                       empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_3,1/K) + ...
                                                       empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_4,1/K);
                                    C_est_partial_hat_X1X2X3 = empcopulaval(C_est_X1X2X3_discrete_integrate, uuEstX1X2X3_1,1/K) - ...
                                                           empcopulaval(C_est_X1X2X3_discrete_integrate, uuEstX1X2X3_2,1/K) - ...
                                                           empcopulaval(C_est_X1X2X3_discrete_integrate, uuEstX1X2X3_3,1/K) + ...
                                                           empcopulaval(C_est_X1X2X3_discrete_integrate, uuEstX1X2X3_4,1/K);
                                    C_actual_partial_X1X2 = empcopulaval(C_actual_X1X2_discrete_integrate, uuGenerativeX1X2_1,1/K) - ...
                                                     empcopulaval(C_actual_X1X2_discrete_integrate, uuGenerativeX1X2_2,1/K) - ...
                                                     empcopulaval(C_actual_X1X2_discrete_integrate, uuGenerativeX1X2_3,1/K) + ...
                                                     empcopulaval(C_actual_X1X2_discrete_integrate, uuGenerativeX1X2_4,1/K);
                                    C_est_partial_hat_X1X2 = empcopulaval(C_est_X1X2_discrete_integrate, uuEstX1X2_1,1/K) - ...
                                                         empcopulaval(C_est_X1X2_discrete_integrate, uuEstX1X2_2,1/K) - ...
                                                         empcopulaval(C_est_X1X2_discrete_integrate, uuEstX1X2_3,1/K) + ...
                                                         empcopulaval(C_est_X1X2_discrete_integrate, uuEstX1X2_4,1/K);

    % % %                                 c_hcbn_X1X2X3 = empcopulaval(hcbnObj.copulaFamilies{3}.c, [uuHcbnX1X2X3(3) uuHcbnX1X2X3(1:2)]);   % reverse ordering of uuHcbn to be consistent                                                                                      % w/ how hcbn code estimates copula
    % % %                                 c_hcbn_X1X2 = empcopulaval(hcbnObj.copulaFamilies{3}.c_parents, uuHcbnX1X2);       % I don't think any ordering needs to be reversed here

                                    fX3 = continuousDistInfo.pdf(xiContinuous_val);
                                    fX3_hat = distCEst.pdf(xiContinuous_val);
    % % %                                 fX3_hcbn = hcbnObj.empInfo{3}.pdf(xiContinuous_val);

                                    % assign all copula based valued
                                    fx3_givenx1x2_copula(ii) = C_actual_partial_X1X2X3*fX3/C_actual_partial_X1X2;
                                    fx3_givenx1x2_copulaestf3est(ii) = C_est_partial_hat_X1X2X3*fX3_hat/C_est_partial_hat_X1X2;
                                    fx3_givenx1x2_copulaestf3Actual(ii) = C_est_partial_hat_X1X2X3*fX3/C_est_partial_hat_X1X2;
                                    fx3_givenx1x2_copulaActualf3est(ii) = C_actual_partial_X1X2X3*fX3_hat/C_actual_partial_X1X2;
                                    fx3_givenx1x2_hcbn(ii) = hcbnObj.computeMixedConditionalProbability_( ...
                                        [x1_discrete_conditional x2_discrete_conditional xiContinuous_val], [cc aa bb], cc);

                                    % assign KDE
                                    fx3_givenx1x2_conditionalKDE(ii) = conditionalKDE.pdf(xiContinuous_val);

                                    % assign CLG
                                    % iterate through the CLG nodeBnParams var
                                    % and find the combo of interest
                                    combo = [x1_discrete_conditional x2_discrete_conditional];
                                    nodeBnParams = clgbnObj.bnParams{3};
                                    for clgIdx=1:length(nodeBnParams)
                                        nodeBnParam = nodeBnParams{clgIdx};
                                        if(isequal(nodeBnParam.parentCombination,combo))
                                            % Get the Mean and Covariance
                                            % parameters and break out of loop
                                            Mean = nodeBnParam.Mean;
                                            Covariance = nodeBnParam.Covariance;
                                            break;
                                        end
                                    end
                                    fx3_givenx1x2_clg(ii) = normpdf(xiContinuous_val, Mean, Covariance);

                                    % assign MTE
                                    nodeBnParams = mtebnObj.bnParams{3};
                                    for mteIdx=1:length(nodeBnParams)
                                        nodeBnParam = nodeBnParams{mteIdx};
                                        if(isequal(nodeBnParam.parentCombination,combo))
                                            mteInfo = nodeBnParam.mte_info;
                                            break;
                                        end
                                    end
                                    fx3_givenx1x2_mte(ii) = mteInfo.pdf(xiContinuous_val);

                                end

                                % plot the actual vs the copula version and compare the differences
                                fig1 = figure(1);
                                subplot(1,2,1);
                                plot(xiContinuous, fx3_givenx1x2_copula, 'b*-', ...
                                     xiContinuous, fx3_givenx1x2_copulaestf3est, ...
                                     xiContinuous, fx3_givenx1x2_copulaestf3Actual, ...
                                     xiContinuous, fx3_givenx1x2_copulaActualf3est, ...
                                     xiContinuous, fx3_givenx1x2_hcbn, 'o-'); 
                                grid on; title(sprintf('X_1=%d X_2=%d',x1_discrete_conditional, x2_discrete_conditional));
                                h_legend = legend('$c*f(x_3)$', ...
                                    '$\hat{c}_{RANK}*\hat{f}(x_3)$', ...
                                    '$\hat{c}_{RANK}*f(x_3)$', ...
                                    '$c*\hat{f}(x_3)$', ...
                                    '$\hat{c}_{HCBN-ECDF}$' );
                                set(h_legend,'FontSize',10);
                                set(h_legend,'Interpreter','latex')

                                subplot(1,2,2);
                                plot(xiContinuous, fx3_givenx1x2_copula, 'b*-', ...
                                     xiContinuous, fx3_givenx1x2_conditionalKDE, ...
                                     xiContinuous, fx3_givenx1x2_mte, ...
                                     xiContinuous, fx3_givenx1x2_clg); 
                                grid on; title(sprintf('X_1=%d X_2=%d',x1_discrete_conditional, x2_discrete_conditional));
                                h_legend = legend('$c*f(x_3)$', 'KDE', 'MTE','CLG');
                                set(h_legend,'FontSize',10);
                                set(h_legend,'Interpreter','latex')

                                pause;
                                clf(fig1);
                            end
                        end
                    end
                    
                    % calculate the reference LL
                    refLL = 0;
                    for ii=1:numTest
                        xx = X_hybrid_test(ii,:);
                        uuGenerativeX1X2X3_1 = [a_dist.cdf(xx(1)) ...
                                                b_dist.cdf(xx(2)) ...
                                                continuousDistInfo.cdf(xx(3))];
                        uuGenerativeX1X2X3_2 = [a_dist.cdf(xx(1)-1) ...
                                                b_dist.cdf(xx(2)) ...
                                                continuousDistInfo.cdf(xx(3))];
                        uuGenerativeX1X2X3_3 = [a_dist.cdf(xx(1)) ...
                                                b_dist.cdf(xx(2)-1) ...
                                                continuousDistInfo.cdf(xx(3))];
                        uuGenerativeX1X2X3_4 = [a_dist.cdf(xx(1)-1) ...
                                                b_dist.cdf(xx(2)-1) ...
                                                continuousDistInfo.cdf(xx(3))];
                        
                        fX3 = continuousDistInfo.pdf(xx(3));
                        C_actual_partial_X1X2X3 = empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_1,1/K) - ...
                                                       empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_2,1/K) - ...
                                                       empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_3,1/K) + ...
                                                       empcopulaval(C_actual_X1X2X3_discrete_integrate, uuGenerativeX1X2X3_4,1/K);
                        totalProb = C_actual_partial_X1X2X3*fX3;
                        if(totalProb<1e-5)
                            totalProb = 1e-5;   % PUT BREAK POINT HERE IF YOU WANT TO DEBUG
                        end
                        refLL = refLL + log(totalProb);
                    end

                    
                    % calculate LL values and assign to llDivMCMat
                    hcbnLL = hcbnObj.dataLogLikelihood(X_hybrid_test);
                    mteLL = mtebnObj.dataLogLikelihood(X_hybrid_test);
                    clgLL = clgbnObj.dataLogLikelihood(X_hybrid_test);
                    multinomialLL = multinomialbnObj.dataLogLikelihood(X_hybrid_test);
                    cbnLL = cbnObj.dataLogLikelihood(X_hybrid_test);
                    
                    % assign LL values to matrix
                    llMCMat(HCBN_LL_MAT_IDX,mcSimNum) = hcbnLL;
                    llMCMat(MTE_LL_MAT_IDX,mcSimNum) = mteLL;
                    llMCMat(CLG_LL_MAT_IDX,mcSimNum) = clgLL;
                    llMCMat(MULTINOMIAL_LL_MAT_IDX,mcSimNum) = multinomialLL;
                    llMCMat(CBN_LL_MAT_IDX,mcSimNum) = cbnLL;
                    llMCMat(REF_LL_MAT_IDX,mcSimNum) = refLL;
                    
                    progressIdx = progressIdx + 1;
                end
                % average the results from the MC simulation and store
                meanLLDivMCMat = mean(llMCMat,2);
                varLLDivMCMat = mean(llMCMat.^2,2)-meanLLDivMCMat.^2;
                                    
                progressStr = sprintf('MEAN{refLL}=%f VAR{refLL}=%f', ...
                    meanLLDivMCMat(REF_LL_MAT_IDX), varLLDivMCMat(REF_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{hcbnLL}=%f VAR{hcbnLL}=%f', ...
                    meanLLDivMCMat(HCBN_LL_MAT_IDX), varLLDivMCMat(HCBN_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{cbnLL}=%f VAR{cbnLL}=%f', ...
                    meanLLDivMCMat(CBN_LL_MAT_IDX), varLLDivMCMat(CBN_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{mteLL}=%f VAR{mteLL}=%f', ...
                    meanLLDivMCMat(MTE_LL_MAT_IDX), varLLDivMCMat(MTE_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{clgLL}=%f VAR{clgLL}=%f', ...
                    meanLLDivMCMat(CLG_LL_MAT_IDX), varLLDivMCMat(CLG_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{multinomialLL}=%f VAR{multinomialLL}=%f\n', ...
                    meanLLDivMCMat(MULTINOMIAL_LL_MAT_IDX), varLLDivMCMat(MULTINOMIAL_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');

                llMat(copulaTypeVecIdx, ...
                         continuousDistTypeVecIdx,...
                         alphaVecIdx,...
                         mVecIdx,:) = meanLLDivMCMat(:);
                     
                llVarMat(copulaTypeVecIdx, ...
                         continuousDistTypeVecIdx,...
                         alphaVecIdx,...
                         mVecIdx,:) = varLLDivMCMat(:);
            end
        end
    end
end

end

function [llMat, llVarMat] = runD5CFG1()
% runD2CFG1 - the multinomial probabilities are evenly distributed
probsA = [0.25 0.25 0.25 0.25];
probsB = [0.25 0.25 0.25 0.25];
[llMat, llVarMat] = runD5(probsA, probsB);
end

function [llMat, llVarMat] = runD5CFG2()
% runD2CFG2 - the multinomial probabilities are skewed left
probsA = [0.5 0.3 0.1 0.1];
probsB = [0.5 0.3 0.1 0.1];
[llMat, llVarMat] = runD5(probsA, probsB);
end

function [llMat, llVarMat] = runD5CFG3()
% runD2CFG2 - the multinomial probabilities are skewed right
probsA = [0.3 0.7];
probsB = [0.3 0.7];
[llMat, llVarMat] = runD5(probsA, probsB);
end

function [llMat, llVarMat] = runD5CFG4()
% runD2CFG2 - the multinomial probabilities are skewed left and right
% oppositely
probsA = [0.5 0.3 0.1 0.1];
probsB = fliplr([0.5 0.3 0.1 0.1]);
[llMat, llVarMat] = runD5(probsA, probsB);
end

function [llMat, llVarMat] = runD5CFG5()
% runD2CFG2 - the multinomial probabilities are skewed right and left
% oppositely
probsA = [0.3 0.7];
probsB = fliplr([0.3 0.7]);
[llMat, llVarMat] = runD5(probsA, probsB);
end

function [llMat, llVarMat] = runD5(a_probs, b_probs)
global mVec
global numModelsCompared numMC bntPath logFile K h numTest
global HCBN_LL_MAT_IDX MTE_LL_MAT_IDX CLG_LL_MAT_IDX REF_LL_MAT_IDX
global MULTINOMIAL_LL_MAT_IDX NUM_DISCRETE_INTERVALS CBN_LL_MAT_IDX
global CDE_combinations C1C2C3_combinations dependency_combinations

a_dist = makedist('Multinomial','Probabilities', a_probs);
b_dist = makedist('Multinomial','Probabilities', b_probs);

% setup the graphical model
aa = 1; bb = 2; cc = 3; dd = 4; ee = 5;
D = 5;
dag = zeros(D,D);
dag(aa,cc) = 1; dag(aa,dd) = 1;
dag(bb,dd) = 1; dag(bb,ee) = 1;
discreteNodes = [aa bb];
nodeNames = {'A', 'B', 'C', 'D', 'E'};
discreteNodeNames = {'A','B'};

llMCMat = zeros(numModelsCompared,numMC);
llMat = zeros(length(CDE_combinations),...
              length(C1C2C3_combinations),...
              length(dependency_combinations),...
              length(mVec),...
              numModelsCompared);
llVarMat = zeros(length(CDE_combinations),...
              length(C1C2C3_combinations),...
              length(dependency_combinations),...
              length(mVec),...
              numModelsCompared);
          
fid = fopen(logFile, 'a');
dispstat('','init'); % One time only initialization
dispstat(sprintf('Begining the simulation...'),'keepthis','timestamp');
numTotalLoops = length(CDE_combinations)*length(C1C2C3_combinations)*length(dependency_combinations)*length(mVec)*numMC;
progressIdx = 1;
for cdeCombinationsVecIdx=1:length(CDE_combinations)
    for c1c2c3CombinationsVecIdx=1:length(C1C2C3_combinations)
        for dependencyCombinationsVecIdx=1:length(dependency_combinations)
            for mVecIdx=1:length(mVec)
                
                marginalDistributionCombinations = CDE_combinations{c1c2c3CombinationsVecIdx};
                dependencyCombinations = dependency_combinations{dependencyCombinationsVecIdx};
                
                % setup the empirical marginal distribution definitions
                empiricalDistSamples = 2000;
                continuousEmpiricalDists = cell(1,3);
                for ii=1:3
                    if(strcmpi(marginalDistributionCombinations{ii},'Gaussian'))
                        xx = normrnd(2,0.5,empiricalDistSamples,1);
                    elseif(strcmpi(marginalDistributionCombinations{ii},'Uniform'))
                        xx = unifrnd(-2,2,empiricalDistSamples,1);
                    elseif(strcmpi(marginalDistributionCombinations{ii},'Multimodal'))
                        xx = [normrnd(-2,0.3,empiricalDistSamples/2,1); normrnd(2,0.8,empiricalDistSamples/2,1)];
                    elseif(strcmpi(marginalDistributionCombinations{ii},'ThickTailed'))
                        xx = trnd(1, empiricalDistSamples, 1);
                    end
                    xx = xx(randperm(empiricalDistSamples),:);     % permute for evenness of samples
                    
                    isdiscrete = 0;
                    [fContinous,xiContinuous] = emppdf(xx,isdiscrete);
                    FContinuous = empcdf(xx,isdiscrete);
                    tmp = rvEmpiricalInfo(xiContinuous,fContinous,FContinuous);
                    continuousEmpiricalDists{ii} = tmp;
                end
                
                % setup dependency amounts
                copulaDepParams = cell(1,3);
                for ii=1:3
                    if(strcmpi(dependencyCombinations{ii},'Strong'))
                        if(ii==2)
                            % deal w/ gaussian case separately b/c we have
                            % to create a correlation matrix
                            Rho = [1 .75 .85; .75 1 .9; .85 .9 1];
                        else
                            copulaDepParams{ii} = 10;       % alpha = 10
                        end
                    elseif(strcmpi(dependencyCombinations{ii}, 'Weak'))
                        if(ii==2)
                            % deal w/ gaussian case separately b/c we have
                            % to create a correlation matrix
                            Rho = [1 .1 .2; .1 1 -.1; .2 -.1 1];
                        else
                            copulaDepParams{ii} = 1;        % alpha = 1
                        end
                    end
                end
                c1c2c3Types = C1C2C3_combinations{c1c2c3CombinationsVecIdx};
                
                M = mVec(mVecIdx);
                
                %%%%%%%%%%% MAIN SIMULATION CODE %%%%%%%%%%
                for mcSimNum=1:numMC
                    progressAmt = progressIdx/numTotalLoops*100;
                    if(strcmp(copulaType,'Gaussian'))
                        progressStr = sprintf('copulaType=%s x3DistType=%s rho=%f M=%d MC Sim# = %d || Progress=%0.04f', ...
                                        copulaType, continuousDistType, Rho(1,2), M, mcSimNum, progressAmt);
                    else
                        progressStr = sprintf('copulaType=%s x3DistType=%s alpha=%d M=%d MC Sim# = %d || Progress=%0.04f', ...
                                        copulaType, continuousDistType, alpha, M, mcSimNum, progressAmt);
                    end
                    dispstat(progressStr,'keepthis','timestamp');
                    fprintf(fid, progressStr);
                    
                    % Generate the data from the reference BN structure
                    alpha_C1 = copulaDepParams{1};
                    Rho_C2 = copulaDepParams{2};
                    alpha_C3 = copulaDepParams{3};
                    U_C2 = copularnd('Gaussian', Rho_C2, M+numTest);        % (:,1)=A
                                                                            % (:,2)=B
                                                                            % (:,3)=D
                    % generate U_C1
                    u1 = U_C2(:,1);
                    p = rand(M+numTest,1);
                    if(strcmpi(c1c2c3Types{1},'Frank'))
                        U_C1_2 = -log((exp(-alpha_C1.*u1).*(1-p)./p + exp(-alpha_C1))./(1 + exp(-alpha_C1.*u1).*(1-p)./p))./alpha_C1;
                    elseif(strcmpi(c1c2c3Types{1},'Clayton'))    
                        U_C1_2 = u1.*(p.^(-alpha_C1./(1+alpha_C1)) - 1 + u1.^alpha_C1).^(-1./alpha_C1);
                    else
                        error('Unsupported Copula Type!');
                    end
                    
                    % generate U_C3
                    u1 = U_C2(:,2);
                    p = rand(M+numTest,1);
                    if(strcmpi(c1c2c3Types{3},'Frank'))
                        U_C3_2 = -log((exp(-alpha_C3.*u1).*(1-p)./p + exp(-alpha_C3))./(1 + exp(-alpha_C3.*u1).*(1-p)./p))./alpha_C3;
                    elseif(strcmpi(c1c2c3Types{3},'Clayton'))
                        U_C3_2 = u1.*(p.^(-alpha_C3./(1+alpha_C3)) - 1 + u1.^alpha_C3).^(-1./alpha_C3);
                    else
                        error('Unsupported Copula Type!');
                    end
                    
                    % Combine all copula samples
                    U = [U_C2(:,1:2) U_C1_2 U_C2(:,3) U_C3_2];  % order the data as A,B,C,D,E
                                                                % U(:,1)=A
                                                                % U(:,2)=B
                                                                % U(:,3)=C
                                                                % U(:,4)=D
                                                                % U(:,5)=E
                                                                
                    % use probability integral transform to create the hybrid data
                    X_hybrid = zeros(size(U));
                    X_hybrid(:,1) = a_dist.icdf(U(:,1));
                    X_hybrid(:,2) = b_dist.icdf(U(:,2));
                    for ii=1:M+numTest
                        X_hybrid(ii,3) = continuousEmpiricalDists.icdf(U(ii,3));
                        X_hybrid(ii,4) = continuousEmpiricalDists.icdf(U(ii,4));
                        X_hybrid(ii,5) = continuousEmpiricalDists.icdf(U(ii,5));
                    end
                    % generate train and test datasets
                    X_hybrid_test = X_hybrid(M+1:end,:);
                    X_hybrid = X_hybrid(1:M,:);
                    
                    % create models of the data
                    hcbnObj = hcbn(bntPath, X_hybrid, nodeNames, discreteNodeNames, K, h, dag); 
                    mtebnObj = mtebn(X_hybrid, discreteNodes, dag);
                    clgbnObj = clgbn(X_hybrid, discreteNodes, dag);
                    multinomialbnObj = multinomialbn(X_hybrid, discreteNodes, dag, NUM_DISCRETE_INTERVALS);
                    cbnObj = cbn(bntPath, X_hybrid, discreteNodes, dag);
                    
                    % TODO: compute the reference likelihood
                    refLL = 0;
                    
                    % compute likelihood for each of the models
                    hcbnLL = hcbnObj.dataLogLikelihood(X_hybrid_test);
                    mteLL = mtebnObj.dataLogLikelihood(X_hybrid_test);
                    clgLL = clgbnObj.dataLogLikelihood(X_hybrid_test);
                    multinomialLL = multinomialbnObj.dataLogLikelihood(X_hybrid_test);
                    cbnLL = cbnObj.dataLogLikelihood(X_hybrid_test);
                    
                    % assign LL values to matrix
                    llMCMat(HCBN_LL_MAT_IDX,mcSimNum) = hcbnLL;
                    llMCMat(MTE_LL_MAT_IDX,mcSimNum) = mteLL;
                    llMCMat(CLG_LL_MAT_IDX,mcSimNum) = clgLL;
                    llMCMat(MULTINOMIAL_LL_MAT_IDX,mcSimNum) = multinomialLL;
                    llMCMat(CBN_LL_MAT_IDX,mcSimNum) = cbnLL;
                    llMCMat(REF_LL_MAT_IDX,mcSimNum) = refLL;
                    
                    progressIdx = progressIdx + 1;
                end
                
                % average the results from the MC simulation and store
                meanLLDivMCMat = mean(llMCMat,2);
                varLLDivMCMat = mean(llMCMat.^2,2)-meanLLDivMCMat.^2;
                                    
                progressStr = sprintf('MEAN{refLL}=%f VAR{refLL}=%f', ...
                    meanLLDivMCMat(REF_LL_MAT_IDX), varLLDivMCMat(REF_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{hcbnLL}=%f VAR{hcbnLL}=%f', ...
                    meanLLDivMCMat(HCBN_LL_MAT_IDX), varLLDivMCMat(HCBN_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{cbnLL}=%f VAR{cbnLL}=%f', ...
                    meanLLDivMCMat(CBN_LL_MAT_IDX), varLLDivMCMat(CBN_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{mteLL}=%f VAR{mteLL}=%f', ...
                    meanLLDivMCMat(MTE_LL_MAT_IDX), varLLDivMCMat(MTE_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{clgLL}=%f VAR{clgLL}=%f', ...
                    meanLLDivMCMat(CLG_LL_MAT_IDX), varLLDivMCMat(CLG_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');
                progressStr = sprintf('MEAN{multinomialLL}=%f VAR{multinomialLL}=%f\n', ...
                    meanLLDivMCMat(MULTINOMIAL_LL_MAT_IDX), varLLDivMCMat(MULTINOMIAL_LL_MAT_IDX));
                dispstat(progressStr,'timestamp','keepthis','timestamp');

                llMat(cdeCombinationsVecIdx, ...
                     c1c2c3CombinationsVecIdx,...
                     dependencyCombinationsVecIdx,...
                     mVecIdx,:) = meanLLDivMCMat(:);
                     
                llVarMat(cdeCombinationsVecIdx, ...
                     c1c2c3CombinationsVecIdx,...
                     dependencyCombinationsVecIdx,...
                     mVecIdx,:) = varLLDivMCMat(:);
                     
            end
        end
    end
end

end