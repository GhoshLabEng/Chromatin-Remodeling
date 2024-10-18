clear all
clc
close all

% these two lines read the two images to be registered. Fixed image is the
% reference image, moving image is the image we are registering
% Fixed image and moving image must be of same size

fixed  = imread('nuc1_01.tif');
moving = imread('nuc1_12.tif');

nn=size(fixed);

% matlab reads the image in a vertically flipped way, so we need to flip the
% image vertically

fixed = flip(fixed, 1);
moving = flip(moving, 1);

% read the size of the image for later colormap plotting

scale = size(fixed);
yscale = scale(1)-1;
xscale = scale(2)-1;

% filtering the data using 3D Gaussian filter
filteredfixed = medfilt2(fixed);
filteredmoving = medfilt2(moving);

% The next block binarizes both images. It means it will get rid of all the
% greyspace around the nucleus and assign a value of 0 to to all those
% regions

BWfixed = imbinarize(filteredfixed);
BWfixed = uint8(BWfixed);
fixednew = BWfixed.*filteredfixed;
imshow(fixednew)

BWmoving = imbinarize(filteredmoving);
BWmoving=uint8(BWmoving);
movingnew=BWmoving.*filteredmoving;
imshow(movingnew)

% This step changes intensity distribution of the moving image to normalize
% Therefore, takes care of any photobleaching or image enhancement by
% higher laser power etc.

movingnew = imhistmatch(movingnew,fixednew);

% This step does the actual registration and creates the displacement map
[D,moving_reg] = imregdemons(movingnew,fixednew);
Dx=D(:,:,1);Dy=D(:,:,2);
Dabs=sqrt(Dx.^2+Dy.^2);


% registering all the displacement with respect to the initial (fixed) image
% frame: 
BWfixednew=double(BWfixed);
Dabsnew=BWfixednew.*Dabs;

Dabsnewcol=Dabsnew(1,:); % 800 columns
for i=2:length(Dabsnew)-1 % 956 rows
    for j=2:length(Dabsnewcol)-1
        TL=Dabsnew(i-1,j-1);
        TC=Dabsnew(i-1,j);
        TR=Dabsnew(i-1,j+1);
        L=Dabsnew(i,j-1);
        C=Dabsnew(i,j);
        R=Dabsnew(i,j+1);
        BL=Dabsnew(i+1,j-1);
        BC=Dabsnew(i+1,j);
        BR=Dabsnew(i+1,j+1);
        surrounding=[TL,TC,TR,L,R,BL,BC,BR]; % all eight surrounding elements
        nonzeroelements=nnz(surrounding);
        if Dabsnew(i,j)==0 && nonzeroelements>=5
            Dabsnew(i,j)=mean(surrounding);
        end
    end
end

% plotting the colormap of displacement
x = 0:1:xscale;
y = 0:1:yscale;
[X,Y] = meshgrid(x,y);


h = pcolor(X,Y,Dabsnew);
set(h,'LineStyle','none')
colormap(jet)
axis equal


C=zeros(1620, 1620);
for j=1:nn(1)
    for i=1:nn(2)
          nul=Dabsnew(j,i);
          C(j,i)=nul;
    end
end
C1 = zeros(1620*1620, 3);
k = 1;
for j=1:nn(1)
    for i=1:nn(2)
        C1(k, :) = [j, i, C(j,i)];
        k = k + 1;
    end
end

dlmwrite('absdisp.txt',C1)

