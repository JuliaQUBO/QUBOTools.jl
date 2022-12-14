% id : 1
% description : Model 1 ~ Simple model with linear terms
% 

set of int: Domain = {-1,1};

var Domain: x2;
var Domain: x4;
var Domain: x6;

float: scale = 1.0;
float: offset = 0.3;

var float: objective = 0.65*x2 + -0.35*x6;

solve minimize objective;