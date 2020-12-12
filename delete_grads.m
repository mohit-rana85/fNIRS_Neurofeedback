function status = delete_grads()

global last_gobjects;

if (last_gobjects.update ~= 0)
	u = size(last_gobjects.update,2);
    delete(last_gobjects.update(1:u));
    last_gobjects.update = 0; %to be safe
end

status = 1;
return;