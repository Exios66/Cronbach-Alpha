function results = cronbach(data, varargin)
    % CRONBACH Compute comprehensive Cronbach's Alpha analysis
    %   results = CRONBACH(data) performs reliability analysis on input data
    %   results = CRONBACH(data, 'bootstrap', true) includes bootstrap CI
    %   results = CRONBACH(data, 'alpha', 0.05) sets confidence level (default 0.05)
    %
    % Input:
    %   data - numeric matrix where columns are items and rows are observations
    %   Name-Value pairs:
    %       'bootstrap' - logical, whether to compute bootstrap CI (default: false)
    %       'alpha' - numeric, significance level (default: 0.05)
    %       'nboot' - integer, number of bootstrap samples (default: 1000)
    %
    % Output:
    %   results - struct containing all reliability metrics and analysis
    
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data', @isnumeric);
    addParameter(p, 'bootstrap', false, @islogical);
    addParameter(p, 'alpha', 0.05, @isnumeric);
    addParameter(p, 'nboot', 1000, @isnumeric);
    parse(p, data, varargin{:});
    
    % Validate data
    validateData(data);
    
    % Initialize results structure
    results = struct();
    
    % Basic sample characteristics
    results.n_observations = size(data, 1);
    results.n_items = size(data, 2);
    results.missing_values = sum(isnan(data(:)));
    
    % Compute Cronbach's Alpha
    [results.alpha_raw, results.alpha_std] = computeAlpha(data);
    
    % Item analysis
    results.item_statistics = computeItemStatistics(data);
    results.alpha_if_deleted = computeAlphaIfDeleted(data);
    results.inter_item_corr = corr(data, 'rows', 'pairwise');
    
    % Normality tests
    results.normality = checkNormality(data);
    
    % Bootstrap if requested
    if p.Results.bootstrap
        results.bootstrap = bootstrapAlpha(data, p.Results.nboot, p.Results.alpha);
    end
    
    % Display results if no output argument
    if nargout == 0
        displayResults(results);
    end
end

function validateData(data)
    % Input validation
    if size(data, 1) < 2
        error('Data must have at least 2 observations');
    end
    if size(data, 2) < 2
        error('Data must have at least 2 items');
    end
    if ~isnumeric(data)
        error('Data must be numeric');
    end
    if any(var(data) == 0)
        warning('Some items have zero variance');
    end
    if any(data(:) < 0, 'omitnan')
        warning('Data contains negative values - verify this is intended');
    end
end

function [alpha_raw, alpha_std] = computeAlpha(data)
    % Compute raw and standardized Cronbach's Alpha
    n_items = size(data, 2);
    
    % Raw alpha
    item_vars = var(data, 0, 'omitnan');
    total_var = var(sum(data, 2, 'omitnan'), 0);
    alpha_raw = (n_items/(n_items-1)) * (1 - sum(item_vars)/total_var);
    
    % Standardized alpha
    R = corr(data, 'rows', 'pairwise');
    mean_r = (sum(R(:)) - n_items) / (n_items^2 - n_items);
    alpha_std = (n_items * mean_r) / (1 + (n_items-1) * mean_r);
end

function stats = computeItemStatistics(data)
    % Compute detailed item statistics
    stats = struct();
    stats.means = mean(data, 'omitnan');
    stats.std = std(data, 0, 'omitnan');
    stats.min = min(data, [], 'omitnan');
    stats.max = max(data, [], 'omitnan');
    stats.skewness = skewness(data, 0);
    stats.kurtosis = kurtosis(data, 0) - 3; % Excess kurtosis
    stats.item_total_corr = computeItemTotalCorr(data);
end

function item_total_corr = computeItemTotalCorr(data)
    % Compute corrected item-total correlations
    n_items = size(data, 2);
    item_total_corr = zeros(1, n_items);
    
    for i = 1:n_items
        other_items = data(:, setdiff(1:n_items, i));
        total_score = sum(other_items, 2, 'omitnan');
        item_total_corr(i) = corr(data(:,i), total_score, 'rows', 'pairwise');
    end
end

function alpha_dropped = computeAlphaIfDeleted(data)
    % Compute alpha if item deleted
    n_items = size(data, 2);
    alpha_dropped = zeros(1, n_items);
    
    for i = 1:n_items
        reduced_data = data(:, setdiff(1:n_items, i));
        [alpha_dropped(i), ~] = computeAlpha(reduced_data);
    end
end

function normality = checkNormality(data)
    % Perform normality tests
    normality = struct();
    
    % Shapiro-Wilk test for each item
    n_items = size(data, 2);
    normality.shapiro_p = zeros(1, n_items);
    
    for i = 1:n_items
        [~, p] = swtest(data(:,i)); % Requires Statistics Toolbox
        normality.shapiro_p(i) = p;
    end
    
    % Basic multivariate normality indicators
    normality.mardia_skewness = maridia_skewness(data);
    normality.mardia_kurtosis = maridia_kurtosis(data);
end

function boot_results = bootstrapAlpha(data, n_boot, alpha)
    % Bootstrap confidence intervals for Cronbach's Alpha
    n_obs = size(data, 1);
    boot_alphas = zeros(n_boot, 1);
    
    for i = 1:n_boot
        % Sample with replacement
        boot_idx = randi(n_obs, n_obs, 1);
        boot_data = data(boot_idx, :);
        
        % Compute alpha for bootstrap sample
        [boot_alphas(i), ~] = computeAlpha(boot_data);
    end
    
    % Compute confidence intervals
    ci = [(alpha/2) (1-alpha/2)];
    boot_results.ci = quantile(boot_alphas, ci);
    boot_results.mean = mean(boot_alphas);
    boot_results.std = std(boot_alphas);
end

function displayResults(results)
    % Display comprehensive analysis results
    fprintf('\n=================================================\n');
    fprintf('COMPREHENSIVE RELIABILITY ANALYSIS RESULTS\n');
    fprintf('=================================================\n\n');
    
    % Main reliability metrics
    fprintf('RELIABILITY METRICS:\n');
    fprintf('--------------------------------------------------\n');
    fprintf('Cronbach''s Alpha (raw): %.3f\n', results.alpha_raw);
    fprintf('Cronbach''s Alpha (standardized): %.3f\n', results.alpha_std);
    
    if isfield(results, 'bootstrap')
        fprintf('Bootstrap 95%% CI: [%.3f, %.3f]\n', ...
            results.bootstrap.ci(1), results.bootstrap.ci(2));
    end
    
    % Sample characteristics
    fprintf('\nSAMPLE CHARACTERISTICS:\n');
    fprintf('--------------------------------------------------\n');
    fprintf('Sample size: %d observations\n', results.n_observations);
    fprintf('Number of items: %d\n', results.n_items);
    fprintf('Missing values: %d\n', results.missing_values);
    
    % Item statistics
    fprintf('\nITEM STATISTICS:\n');
    fprintf('--------------------------------------------------\n');
    fprintf('Item\tMean\tStd\tItem-Total Corr\tα if deleted\n');
    for i = 1:results.n_items
        fprintf('%d\t%.2f\t%.2f\t%.3f\t\t%.3f\n', ...
            i, ...
            results.item_statistics.means(i), ...
            results.item_statistics.std(i), ...
            results.item_statistics.item_total_corr(i), ...
            results.alpha_if_deleted(i));
    end
    
    % Interpretation guidelines
    fprintf('\nINTERPRETATION GUIDELINES:\n');
    fprintf('--------------------------------------------------\n');
    fprintf('Reliability Coefficient Interpretation:\n');
    fprintf('< 0.50: Unacceptable\n');
    fprintf('0.50 - 0.59: Poor\n');
    fprintf('0.60 - 0.69: Questionable\n');
    fprintf('0.70 - 0.79: Acceptable\n');
    fprintf('0.80 - 0.89: Good\n');
    fprintf('>= 0.90: Excellent\n');
end

function [H, pValue] = swtest(x)
    % Shapiro-Wilk test implementation
    % This is a simplified version - consider using Statistics Toolbox
    x = x(:);
    n = length(x);
    y = sort(x);
    
    % Compute W statistic
    m = norminv((1:n)' / (n+1));
    C = 1/sqrt(m'*m) * m;
    w = (C'*y)^2 / sum((y-mean(y)).^2);
    
    % Approximate p-value
    mu = -1.5861/sqrt(n);
    sigma = exp(0.8989 - 2.8605*n^(-1) + 2.4589*n^(-2));
    z = (log(1-w) - mu)/sigma;
    pValue = 1 - normcdf(z);
    H = (pValue < 0.05);
end

function b1p = maridia_skewness(X)
    % Mardia's multivariate skewness
    n = size(X,1);
    p = size(X,2);
    X = X - repmat(mean(X),n,1);
    S = cov(X);
    Sinv = inv(S);
    b1p = sum(sum((X*Sinv*X').^3))/n^2;
end

function b2p = maridia_kurtosis(X)
    % Mardia's multivariate kurtosis
    n = size(X,1);
    p = size(X,2);
    X = X - repmat(mean(X),n,1);
    S = cov(X);
    Sinv = inv(S);
    b2p = trace((X*Sinv*X').^2)/n;
end 