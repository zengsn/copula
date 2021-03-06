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

function [ C, U, c, u_emp ] = empcopula_old( X, K )
%EMPCOPULA Calculates the empiricial copula in a unit hypercube
% Inputs:
%  X - a [M x D] matrix, where M is the number of samples, and D is the
%      dimensionality of the data
%  K - the number of evenly spaced points in the unit hypercube to
%      calculate the empirical copula over.  Should be a minimum of 100 for
%      reasonable accuracy.
%
% Outputs:
%  C - the empirical copula, which is a [n x D] matrix
%  U - the points over which the copula was calculated
%  c - A cell array of the copula density.  The format of the cell array is
%      as follows: c{1} = dC(u_1 ... u_D)/du_1
%                  c{2} = dC(u_1 ... u_D)/(du_1 du_2)
%                  c{3} = dC(u_1 ... u_D)/(du_1 du_2 du_3)
%                           ...
%                  c{D} = dC(u_1 ... u_D)/(du_1 ... du_D)
%      Resultingly, c{D} will be the "copula density."

M = size(X,1);
D = size(X,2);

U = cell(1,D);
ux = linspace(0,1,K);
% UU = ndgrid(ux);
% idxShiftArr = 1:D;
% shiftAmt = 0;
% for ii=1:D
%     U{ii} = permute(UU, circshift(idxShiftArr',shiftAmt)');
%     shiftAmt = shiftAmt + 1;
% end
% TODO: figure out more elegant way of doing this!!
if(D==2)
    [UU1,UU2] = ndgrid(ux);
    U{1} = UU1; U{2} = UU2;
elseif(D==3)
    [UU1,UU2,UU3] = ndgrid(ux);
    U{1} = UU1; U{2} = UU2; U{3} = UU3;
elseif(D==4)
    [UU1,UU2,UU3,UU4] = ndgrid(ux);
    U{1} = UU1; U{2} = UU2; U{3} = UU3; U{4} = UU4;
elseif(D==5)
    [UU1,UU2,UU3,UU4,UU5] = ndgrid(ux);
    U{1} = UU1; U{2} = UU2; U{3} = UU3; U{4} = UU4; U{5} = UU5;
elseif(D==6)
    [UU1,UU2,UU3,UU4,UU5,UU6] = ndgrid(ux);
    U{1} = UU1; U{2} = UU2; U{3} = UU3; U{4} = UU4; U{5} = UU5; U{6}= UU6;
end

X = X';

n_by_K = floor(M/K);
n = n_by_K * K;         %sample size = floor(n_whole_sample/K)*K

% truncate the data to n
X = X(:,1:n);

[~, nU] = empVF_v3(n,D,X); 

j=zeros(1,D);

summand = 1*realpow(K,D)/n;

c = cell(1,D);
c{1} = [];
for ii=2:D
    sz = K*ones(1,ii);
    c{ii} = zeros(sz);
end
    
for jj=1:n
    for d=1:D
        j(d) = ceil( (nU(d,jj)-0.00001)/n_by_K );   % compensate for rounding errors
    end

    for ii=2:D
        access_vec = j(1:ii);
        linear_idx = access_vec(1);
        for kk=2:length(access_vec)
            linear_idx = linear_idx + (access_vec(kk)-1)*(K.^(kk-1));
        end

        c{ii}(linear_idx) = c{ii}(linear_idx) + summand;
    end
end

% scale the copula densities
for dd=2:D
    c{dd} = c{dd}/(K^dd);
end

% Generate C
C = cumsum(c{D},1);
for dd=2:D
    C = cumsum(C, dd);
end

u_emp=nU/n;
u_emp = u_emp';

end
