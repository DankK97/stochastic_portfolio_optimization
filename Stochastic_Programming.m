% clc
clear all
format long

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. read input files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load the stock weekly prices and factors weekly returns
data = readtable('price_data.csv');
data.Properties.RowNames = cellstr(datetime(data.Date));
size_data = size(data);
size_asset = size(data,2)-2;
data = data(:,2:size_data(2)-1);

% identify the tickers and the dates 
tickers = data.Properties.VariableNames';
dates   = datetime(data.Properties.RowNames);

% calculate the stocks' weekly returns
prices  = table2array(data);
returns = (prices(2:end,:) - prices(1:end-1,:)) ./ prices(1:end-1,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. moment estimates 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calibration start data and end data
cal_start = datetime('2012-01-01');
cal_end = cal_start + calmonths(36) - days(1);

% testing period start date and end date
test_start = cal_end + days(1);
test_end = test_start + calmonths(12) - days(1);

cal_returns = returns( cal_start <= dates & dates <= cal_end,:);

% calculate the geometric mean of the returns of all assets
mean = geomean(cal_returns+1)-1;
cov = cov(cal_returns);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. scenario generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the number of randomized scenarios to sample for
N = 10;

% setting the random seed so that our random draws are consistent across
% testing
rng(1);

% generate the random sample for our asset returns, modelled as a
% mutlivariate normal with mean and cov
scenario_returns = mvnrnd(mean, cov, N);

% generate another random sample for our matching liabilities
scenario_liabilities = normrnd(1000000,100000, [N 1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. stochastic optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% take uniform probability of each scenario
p = 1/N;

% budget constraint
B = 900000;

f = [ones(1, size_asset) repmat(p*[-2 12], [1 N])]';

% first stage constraints
A = [ones(1, size_asset) zeros(1,2*N)];
b = B;

% second stage constraints
Aeq = [scenario_returns+1 zeros(N,2*N)];

col = size_asset + 2;

for i=1:N
    Aeq(i, col-1:col) = [-1 1];
    col = col+2;
end

beq = scenario_liabilities;

% lower bound
lb = zeros(size(f));

% optimal
[optimal soln] = linprog(f, A, b, Aeq, beq, lb, [])



