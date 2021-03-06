function [alpha,optvalue,info] = Dual_augmented_lagrange_least_square(alpha_0,HSIC_target,A,b,lambda,maxInteration,tol,stop_criteria,dual_mode)
%Function for least square with non-negative lasso 
%Dual Augmented Lagrange Method
%Good property of least square: The dual form of the l-2 norm is also l-2
%Author: Chen Wang
%Input args: 
%       alpha_0: initial value of target variable alpha_0
%       HSIC_target: target optimization function
%       A: The A matrix for least square
%       b: The b vector for least square
%       lambda: pernalization factor
%       maxInteration: maximum iteration times
%       tol: tolerance for stopping
%       stop_criteria: 
%           'norm': Using the difference between the norm of two iteration
%           to determing the stop criteria
%           'fz': Using proximal judging criteria f(z)<f(z,x)
%       dual_mode:
%           'Gradient': Using Gradient Decent to compute dual
%           'inv': Using maxtrix inverse to solve this

%Define a information structual object and return useful informations
info.steps = 1;
info.alpha_value = zeros(size(alpha_0,1),maxInteration);  %Dim * Iteration
info.alpha_value(:,1) = alpha_0;
info.converge = false;
%start with gamma_0
gamma_0 = 1;
%Discounted with 0.5
beta = 1.5;
%calculate dual Dim and initialize dual_alpha
dual_dim = size(A,1);
dual_alpha = ones(size(dual_dim,1));
%Pre-compute matrix to save computational time
AA = A.'*A;
Ab = A.'*b;
%define the function handle
%Dual function
dual_alpha_object = @(dual_alpha,gamma_k,alpha_k)(norm(-dual_alpha-b)+(1/2*gamma_k)*norm(proximal_l1_non_negative(alpha_k+gamma_k*A.'*dual_alpha))^2);
%Dual Gradient if use Gradient descent
switch lower(dual_mode)
    case'gradient'
        % Difine the hyper-parameter eta
        d_dual_alpha_object = @(dual_alpha,gamma_k,alpha_k)(norm(-dual_alpha-b)+(1/2*gamma_k)*norm(proximal_l1_non_negative(alpha_k+gamma_k*A.'*dual_alpha))^2);
    case 'inv'
        %dfine the handle to update the dual alpha
        dual_alpha_update = @(dual_alpha,gamma_k,alpha_k,A)mldivide((eye(size(A*A.'))-gamma_k*A*A.'),(A*alpha_k-b-gamma_k*ones(size(b,1),1)));
end
%non-negative lasso input arguments
alpha_update_input = @(alpha_k,gamma_k,dual_alpha) (alpha_k+gamma_k*A.'*dual_alpha);
%proximal stopping cretiria function
f_gamma = @(x,y,gamma_k)(((1/2)*(A*y-b).'*(A*y-b))+(AA*y-Ab).'*(x-y)+(1/2*gamma_k)*(x-y).'*(x-y));
%compute alpha at the fisrt interation
switch lower(dual_mode)
    case'gradient'
        % Difine the hyper-parameter eta
%         d_dual_alpha_object = @(dual_alpha,gamma_k,alpha_k)(norm(-dual_alpha-b)+(1/2*gamma_k)*norm(proximal_l1_non_negative(alpha_k+gamma_k*A.'*dual_alpha))^2);
    case 'inv'
        %dfine the handle to update the dual alpha
        dual_alpha = dual_alpha_update(dual_alpha,gamma_0,alpha_0,A);
end      
alpha = proximal_l1_non_negative(alpha_update_input(alpha_0,gamma_0,dual_alpha),gamma_0*lambda);
gamma = gamma_0 * beta;
%iterately update alpha
for k = 2:1:maxInteration
    alpha_k_1 = alpha;
    %find active index
    active_vector = alpha_update_input(alpha,gamma,dual_alpha);
    active_index = find(abs(active_vector)>gamma*lambda);
    A_active = A(:,active_index);
    alpha_active = alpha(active_index);
    %update dual_alpha
    dual_alpha = dual_alpha_update(dual_alpha,gamma,alpha_active,A_active);
    %update primal alpha
    alpha = proximal_l1_non_negative(alpha_update_input(alpha,gamma,dual_alpha),gamma*lambda);
    %Updata gamma
    gamma = gamma * beta;
    info.alpha_value(:,k) = alpha;
    info.steps = k;
    %Determin to use which kind of stop condition
    switch lower(stop_criteria)
        case 'norm'
            stop_condition = (norm(alpha-alpha_k_1)<=tol);
        case 'fz'
            stop_condition = ((1/2)*(A*alpha-b).'*(A*alpha-b)<=f_gamma(alpha,alpha_k_1,gamma));
    end
    if stop_condition == 1
        info.converge = true;
        break
    end
end

optvalue = HSIC_target(alpha);
end
