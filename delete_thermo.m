function status = delete_thermo()
global last_gobjects;

%first delete the grads
delete_grads;

%delete the condition image
%delete(last_gobjects.image);
last_gobjects.image = 0;

%then delete the thermo
if(last_gobjects.thermo ~= 0)
	t = size(last_gobjects.thermo,2);
	delete(last_gobjects.thermo(1:t)); 
    last_gobjects.thermo = 0; %to be safe
end

status = 1;
return;