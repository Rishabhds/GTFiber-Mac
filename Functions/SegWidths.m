function ims = SegWidths(ims,settings)

numSamps = settings.fibWidSamps2;

% ORIGIN IS (0,0) AT TOP LEFT CORNER for both pixel and nm space
% X INCREASES DOWN
% Y INCREASES RIGHT

% numSamps = min(settings.fibWidSamps,sum(sum(ims.skelTrim)));
angMap = ims.AngMap;
nmPix = ims.nmPix;
bw = ims.CEDclean;  % Thresholded black and white image
SL = ims.SegLabels;

for i = 1:length(ims.fibSegs)
    
    % Isolate the segments and count the pixels
    skel_i = SL==i;
    numPix = length(ims.fibSegs(i).sortPixInds);
%     minSamps = min(numPix,numSamps);    % Make sure there are enough pixels to take 7 samples
    sl = find(skel_i);
    
    % Sample a few pixel indices to do width sampling
    skelSamp = datasample(sl,numSamps,'Replace',true);
    skelSamp = skelSamp(~isnan(angMap(skelSamp)));  % Remove samples where the skeleton was on a weird artifact
    fibWidSamps = zeros(size(skelSamp,2),1);
    
    for samp = 1:length(skelSamp)
%         disp('____')
%         disp(size(angMap))
        coord = ind2subv(size(bw),skelSamp(samp));
%         disp(coord)
        fibWidSamps(samp) = WidthSample(bw,angMap,coord);
    end
    
    ims.fibSegs(i).width = nanmean(fibWidSamps)*nmPix;
end

end

function out = WidthSample(bw,angMap,coord)

[m,n] = size(bw);
% Set up search vectors and origin
ang_i = angMap(coord(1),coord(2));  % Fiber orientation at this skeletal pixel, 0 = horizontal
wvec = [cosd(ang_i), sind(ang_i)];    % unit vector pointing along width path... the x->y and y->-x axis flip makes this line work.......
orig_pix = coord - [0.5, 0.5];  % center of skeletal pixel in pixel space

% parameterize the width path and list the times where it hits
% gridlines

numPts = 100;
n2 = 2*(1:numPts)'-1;
T = [n2*sign(wvec(1))/(2*wvec(1)), n2*sign(wvec(2))/(2*wvec(2))];   % Somehow I derived this...
Tx = [T(:,1), (1:numPts)', ones(numPts,1)];
Ty = [T(:,2), (1:numPts)', ones(numPts,1)+1];
Tlist = [Tx;Ty];
Tsort = sortrows(Tlist,1);

% go through list of gridline hits and if the pixel beyond that
% gridline is black, stop and record width

for t = 1:length(Tsort)
    gridpt = orig_pix + Tsort(t,1) * wvec;
    xory = Tsort(t,3);      % =1 if x grid, =2 if y grid
    if xory == 1
        next_pt = [round(gridpt(1))+(wvec(1)>0), ceil(gridpt(2))]; % If moving down, check next pixel down, if up, check up
    else
        next_pt = [ceil(gridpt(1)), round(gridpt(2))+(wvec(2)>0)]; % If moving right, check next pixel to right, if left, check left
    end
    
    %         disp(next_pt)
    if next_pt(1)>m || next_pt(1)<1 || next_pt(2)>n || next_pt(2)<1
        check = 1;
    elseif bw(next_pt(1),next_pt(2)) == 0
        check = 1;
    else
        check = 0;
    end
    
    if check
        pos_bound = gridpt;
        w_pos = norm(pos_bound-orig_pix,2);
        break
    end
end

% Now change direction of search and go again
wvec = -wvec;

% parameterize the width path and list the times where it hits
% gridlines

numPts = 100;
n2 = 2*(1:numPts)'-1;
T = [n2*sign(wvec(1))/(2*wvec(1)), n2*sign(wvec(2))/(2*wvec(2))];
Tx = [T(:,1), (1:numPts)', ones(numPts,1)];
Ty = [T(:,2), (1:numPts)', ones(numPts,1)+1];
Tlist = [Tx;Ty];
Tsort = sortrows(Tlist,1);

% go through list of gridline hits and if the pixel beyond that
% gridline is black, stop and record width

for t = 1:length(Tsort)
    gridpt = orig_pix + Tsort(t,1) * wvec;
    xory = Tsort(t,3);      % =1 if x grid, =2 if y grid
    if xory == 1
        next_pt = [round(gridpt(1))+(wvec(1)>0), ceil(gridpt(2))]; % If moving down, check next pixel down, if up, check up
    else
        next_pt = [ceil(gridpt(1)), round(gridpt(2))+(wvec(2)>0)]; % If moving right, check next pixel to right, if left, check left
    end
    
    if next_pt(1)>m || next_pt(1)<1 || next_pt(2)>n || next_pt(2)<1
        check = 1;
    elseif bw(next_pt(1),next_pt(2)) == 0
        check = 1;
    else
        check = 0;
    end
    
    if check
        neg_bound = gridpt;
        w_neg = norm(neg_bound-orig_pix,2);
        break
    end
end

if exist('w_pos','var') && exist('w_neg','var')
    out = w_pos+w_neg;
else
    out=NaN;
end

end