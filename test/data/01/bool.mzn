% id : 1
% description : Model 1 ~ Simple model with linear terms
% 

set of int: Domain = {0,1};

var Domain: x2;
var Domain: x4;
var Domain: x6;

float: scale = 1.0;
float: offset = 0.0;

var float: objective = 1.3*x2 + -0.7*x6;

solve minimize objective;

output [show(scale*(objective + offset)), " - ", show(objective)];