function subs = dlmstr(istring, dlm)

%Function to split an input string into substring 
%based on the dilimter specified.
%Example: substrings = dlmstr(S, '\s'); %the delimiter here is space

dlm_index = regexp(istring, dlm);
num_dlm = length(dlm_index);

first = 1; %first character
last = length(istring); %last character

for i = 1:num_dlm
    subs{i} = istring(first:(dlm_index(i)-1));
    first = dlm_index(i) + 1;
end

subs{num_dlm + 1} = istring(first:last);
