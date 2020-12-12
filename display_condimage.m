function display_condimage(cond_image)

global last_gobjects;
global img; %values are already initialized in draw_thermo

%delete the previous image if exists
if(last_gobjects.image ~= 0)
	delete(last_gobjects.image);
end

axes(img.axhandle);
axis off;
last_gobjects.image = image(cond_image);
