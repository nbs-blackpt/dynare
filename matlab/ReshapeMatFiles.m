function ReshapeMatFiles(type, type2)
% function ReshapeMatFiles(type, type2)
% Reshapes and sorts (along the mcmc simulations) the mat files generated by DYNARE.
% 4D-arrays are splitted along the first dimension.
% 3D-arrays are splitted along the second dimension.
%
% INPUTS:
%   type:            statistics type in the repertory:
%                      dgse
%                      irf_bvardsge
%                      smooth
%                      filter
%                      error
%                      innov
%                      forcst
%                      forcst1
%   type2:           analysis type:
%                      posterior
%                      gsa
%                      prior
%    
% OUTPUTS:
%    none              
%
% SPECIAL REQUIREMENTS
%    none

% Copyright (C) 2003-2011 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

global M_ options_

if nargin==1
    MhDirectoryName = [ CheckPath('metropolis',M_.dname) filesep ];
else
    if strcmpi(type2,'posterior')
        MhDirectoryName = [CheckPath('metropolis',M_.dname) filesep ];
    elseif strcmpi(type2,'gsa')
        if options_.opt_gsa.morris==1
            MhDirectoryName = [CheckPath('gsa/screen',M_.dname) filesep ];
        elseif options_.opt_gsa.morris==2
            MhDirectoryName = [CheckPath('gsa/identif',M_.dname) filesep ];
        elseif options_.opt_gsa.pprior
            MhDirectoryName = [CheckPath(['gsa' filesep 'prior'],M_.dname) filesep ];
        else
            MhDirectoryName = [CheckPath(['gsa' filesep 'mc'],M_.dname) filesep ];
        end
    else
        MhDirectoryName = [CheckPath('prior',M_.dname) filesep ];
    end  
end
switch type
  case 'irf_dsge'
    CAPtype  = 'IRF_DSGE';
    TYPEsize = [ options_.irf , size(options_.varlist,1) , M_.exo_nbr ];
    TYPEarray = 4;    
  case 'irf_bvardsge'
    CAPtype  = 'IRF_BVARDSGE';
    TYPEsize = [ options_.irf , length(options_.varobs) , M_.exo_nbr ];
    TYPEarray = 4;      
  case 'smooth'
    CAPtype  = 'SMOOTH';
    TYPEsize = [ M_.endo_nbr , options_.nobs ];
    TYPEarray = 3;
  case 'filter'
    CAPtype = 'FILTER';
    TYPEsize = [ M_.endo_nbr , options_.nobs + 1 ];% TO BE CHECKED!
    TYPEarray = 3;
  case 'error'
    CAPtype = 'ERROR';
    TYPEsize = [ length(options_.varobs) , options_.nobs ];
    TYPEarray = 3;
  case 'innov'
    CAPtype = 'INNOV';
    TYPEsize = [ M_.exo_nbr , options_.nobs ];
    TYPEarray = 3;
  case 'forcst'
    CAPtype = 'FORCST';
    TYPEsize = [ M_.endo_nbr , options_.forecast ];
    TYPEarray = 3;
  case 'forcst1'
    CAPtype = 'FORCST1';
    TYPEsize = [ M_.endo_nbr , options_.forecast ];
    TYPEarray = 3;
  otherwise
    disp('ReshapeMatFiles :: Unknown argument!')
    return
end

TYPEfiles = dir([MhDirectoryName M_.fname '_' type '*.mat']);
NumberOfTYPEfiles = length(TYPEfiles);
B = options_.B;

switch TYPEarray
  case 4
    if NumberOfTYPEfiles > 1
        NumberOfPeriodsPerTYPEfiles = ceil(TYPEsize(1)/NumberOfTYPEfiles);
        foffset = NumberOfTYPEfiles-floor(TYPEsize(1)/NumberOfPeriodsPerTYPEfiles);
        reste = TYPEsize(1)-NumberOfPeriodsPerTYPEfiles*(NumberOfTYPEfiles-foffset);
        idx = 0;
        jdx = 0;
        for f1=1:NumberOfTYPEfiles-foffset
            eval(['STOCK_' CAPtype ' = zeros(NumberOfPeriodsPerTYPEfiles,TYPEsize(2),TYPEsize(3),B);'])
            for f2 = 1:NumberOfTYPEfiles
                load([MhDirectoryName M_.fname '_' type int2str(f2) '.mat']);
                eval(['STOCK_' CAPtype '(:,:,1:+size(stock_' type ',3),idx+1:idx+size(stock_' type ',4))=stock_' ...
                      type '(jdx+1:jdx+NumberOfPeriodsPerTYPEfiles,:,:,:);'])
                eval(['idx = idx + size(stock_' type ',4);'])
            end
            %eval(['STOCK_' CAPtype ' = sort(STOCK_' CAPtype ',4);'])
            save([MhDirectoryName M_.fname '_' CAPtype 's' int2str(f1) '.mat'],['STOCK_' CAPtype]);
            jdx = jdx + NumberOfPeriodsPerTYPEfiles;
            idx = 0;
        end
        if reste
            eval(['STOCK_' CAPtype ' = zeros(reste,TYPEsize(2),TYPEsize(3),B);'])
            for f2 = 1:NumberOfTYPEfiles
                load([MhDirectoryName M_.fname '_' type int2str(f2) '.mat']);
                eval(['STOCK_' CAPtype '(:,:,:,idx+1:idx+size(stock_' type ',4))=stock_' type '(jdx+1:jdx+reste,:,:,:);'])
                eval(['idx = idx + size(stock_' type ',4);'])
            end
            %eval(['STOCK_' CAPtype ' = sort(STOCK_' CAPtype ',4);'])
            save([MhDirectoryName M_.fname '_' CAPtype 's' int2str(NumberOfTYPEfiles-foffset+1) '.mat'],['STOCK_' CAPtype]);  
        end
    else
        load([MhDirectoryName M_.fname '_' type '1.mat']);
        %eval(['STOCK_' CAPtype ' = sort(stock_' type ',4);'])
        eval(['STOCK_' CAPtype ' = stock_' type ';'])
        save([MhDirectoryName M_.fname '_' CAPtype 's' int2str(1) '.mat'],['STOCK_' CAPtype ]);
    end
    % Original file format may be useful in some cases...
    % for file = 1:NumberOfTYPEfiles
    %  delete([MhDirectoryName M_.fname '_' type int2str(file) '.mat'])
    % end
  case 3
    if NumberOfTYPEfiles>1
        NumberOfPeriodsPerTYPEfiles = ceil( TYPEsize(2)/NumberOfTYPEfiles );
        reste = TYPEsize(2)-NumberOfPeriodsPerTYPEfiles*(NumberOfTYPEfiles-1);
        idx = 0;
        jdx = 0;
        for f1=1:NumberOfTYPEfiles-1
            eval(['STOCK_' CAPtype ' = zeros(TYPEsize(1),NumberOfPeriodsPerTYPEfiles,B);'])
            for f2 = 1:NumberOfTYPEfiles
                load([MhDirectoryName M_.fname '_' type int2str(f2) '.mat']);
                eval(['STOCK_' CAPtype '(:,:,idx+1:idx+size(stock_ ' type ',3))=stock_' type '(:,jdx+1:jdx+NumberOfPeriodsPerTYPEfiles,:);'])
                eval(['idx = idx + size(stock_' type ',3);'])
            end
            %eval(['STOCK_' CAPtype ' = sort(STOCK_' CAPtype ',3);'])
            save([MhDirectoryName M_.fname '_' CAPtype 's' int2str(f1) '.mat'],['STOCK_' CAPtype]);
            jdx = jdx + NumberOfPeriodsPerTYPEfiles;
            idx = 0;
        end
        eval(['STOCK_' CAPtype ' = zeros(TYPEsize(1),reste,B);'])
        for f2 = 1:NumberOfTYPEfiles
            load([MhDirectoryName M_.fname '_' type int2str(f2) '.mat']);
            eval(['STOCK_' CAPtype '(:,:,idx+1:idx+size(stock_' type ',3))=stock_' type '(:,jdx+1:jdx+reste,:);'])
            eval(['idx = idx + size(stock_' type ',3);'])
        end
        %eval(['STOCK_' CAPtype ' = sort(STOCK_' CAPtype ',3);'])
        save([MhDirectoryName M_.fname '_' CAPtype 's' int2str(NumberOfTYPEfiles) '.mat'],['STOCK_' CAPtype]);
    else
        load([MhDirectoryName M_.fname '_' type '1.mat']);
        %eval(['STOCK_' CAPtype ' = sort(stock_' type ',3);'])
        eval(['STOCK_' CAPtype ' = stock_' type ';'])
        save([MhDirectoryName M_.fname '_' CAPtype 's' int2str(1) '.mat'],['STOCK_' CAPtype ]);      
    end
    % Original file format may be useful in some cases...
    % for file = 1:NumberOfTYPEfiles
    %   delete([MhDirectoryName M_.fname '_' type  int2str(file) '.mat'])
    % end
end