function bci = draw_thermo(current_fig, grads, color, backcolor,bci)
%function that handles drawing the thermometer
%input args: max number of grads and color
%the sequence of actions: 
%draw_thermo, update_thermo, delete_thermo
%returns ax with the handles too


%global constants
global thermo;
global thermo_ax;
global MAX_GRADUATIONS;
global grad;
global img;
global previous_grads;
%global backcolor;

%assign arguments passed
MAX_GRADUATIONS = grads;
thermo.color = color; 
%backcolor = 'red';

%last graphic objects drawn
% last_gobjects.thermo -  the entire list of thermo objects drawn last
% last_gobjects.update - the update last made, to be deleted before every new update
% last_gobjects.fh - last figure handle; later write a function for deleting figure
global last_gobjects;
last_gobjects.update = 0; %initialization before an update
last_gobjects.thermo = 0;
last_gobjects.image = 0;

%Axes parameters
thermo_ax.l = 0.4; %left
thermo_ax.b = 0.2; %bottom
thermo_ax.w = 0.2; %width
thermo_ax.h = 0.6; %height

%thermo centerline coords
%all these dimensions are with respect (ax.l,ax.b) as the origin (0,0)
f.cx = thermo_ax.w/2;
f.cy = thermo_ax.h/2;
cl.X = [0 thermo_ax.w]; %dotted center line 
cl.Y = [thermo_ax.h/2 thermo_ax.h/2]; 
cl.linestyle = '--'; %dashed line
cl.color = [1 0 0]; %white line on black background

%thermo dimensions
thermo.ho = thermo_ax.h; %thermo outside box height
thermo.wo = thermo_ax.w;
t = thermo_ax.w*0.25; %gap between outer and inner boxes of thermo
thermo.hi = thermo.ho - 2*t; 
thermo.wi = thermo.wo - 2*t;

%set the current fig and axes
figure(current_fig); %set the current figure
thermo_ax.handle = axes('Position', [thermo_ax.l thermo_ax.b thermo_ax.w thermo_ax.h], 'Color', backcolor); %background of the axes
proto = thermo_ax.handle; %this handle is checked in bci_results, but needs to be cleaned up   

%outside outline of thermo
thermo.Xo = [(f.cx-thermo.wo/2) (f.cx+thermo.wo/2) (f.cx+thermo.wo/2) (f.cx-thermo.wo/2)]; %in anticlockwise direction
thermo.Yo = [(f.cy-thermo.ho/2) (f.cy-thermo.ho/2) (f.cy+thermo.ho/2) (f.cy+thermo.ho/2)];

%inside outline of thermo
thermo.Xi = [(f.cx-thermo.wi/2) (f.cx+thermo.wi/2) (f.cx+thermo.wi/2) (f.cx-thermo.wi/2)]; %in anticlockwise direction
thermo.Yi = [(f.cy-thermo.hi/2) (f.cy-thermo.hi/2) (f.cy+thermo.hi/2) (f.cy+thermo.hi/2)];

% %draw the thermometer both outside and inside outlines
last_gobjects.thermo(1) = patch(thermo.Xo, thermo.Yo, thermo.color);
last_gobjects.thermo(2) = patch(thermo.Xi, thermo.Yi, [1 1 1]); 

%draw the centerline
last_gobjects.thermo(3) = line(cl.X, cl.Y, 'LineStyle', cl.linestyle, 'Color',  cl.color);

%compute the coords of the condition image
img.w = 0.08;
img.h = 0.1;
img.x = thermo_ax.l + thermo_ax.w*1.2;
img.y = thermo_ax.b  + thermo_ax.h/2 - img.h/2;
img.axhandle = axes('Position', [img.x img.y img.w img.h], 'Color', backcolor);
axis off; %Modification_RANGA_Mar17_2006
last_gobjects.thermo(4) = thermo_ax.handle; %you should delete the image handle too later on
last_gobjects.thermo(5) = img.axhandle;
if bci.isref_zero
    aa=1;
else
    aa=2;
end
%call the function that computes the coords of all the max grads and stores it
bci =create_grads(current_fig, fix(MAX_GRADUATIONS/aa), 1,bci); %the second argument forces creation for the first time

status = 1;

%thermo_ax = thermo_ax;
set(gcf, 'Color', backcolor); %Modification_RANGA_Mar17_2006
axis off; %Modification_RANGA_Mar17_2006
return;

