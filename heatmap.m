
pathImages = ''
ImgName = dir(pathImages)
cd(pathImages)
neuron = {}
for i = 4:length(ImgName)
    realImage = imread(ImgName(i,:).name);
    showImage = uint8(rescale(realImage)*255);
    CropFig = figure
    imshow(showImage*10);
    text(10,30,ImgName(i,:).name,'Color','w','FontSize',20)
    ROI = getrect(CropFig)
    ROI = round(ROI);
    Cropped_Image = realImage(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3));
    neuron{i} = Cropped_Image;
    close all
end

AvgPixel = []
for i = 4:size(neuron,2)
    Img = neuron{i};
    AvgPixel(i-3,1) = max(max(Img));
end
%%
for x = 4:length(ImgName)
NormFactor = 255/max(AvgPixel);
realImage = imread(ImgName(x,:).name);
cdata = realImage;
Black = 10;
Black2 = linspace(Black,255,6)';
Colors = nan(size(d));
Colors(:,1) = [1;Black2];
Colors(:,2:4) = d(:,2:4);
ColPal = []
for i = 1:3
ColPal(:,i) = (interp1(Colors(:,1),Colors(:,i+1),1:255,'linear'))';
end

normPic = uint8(rescale(cdata*NormFactor)*255);
Kmedian = medfilt2(normPic*3);
%imshow(Kmedian)
%imshowpair(normPic*3,Kmedian,'montage')

% Image = figure
% Im2Save = imshow(Kmedian)
% cmap = colormap(uint8(ColPal));
% colorbar

output_img = nan(1024,1024,3);
R= nan(size(Kmedian));
G= nan(size(Kmedian));
B = nan(size(Kmedian));

for i = 1:255
    isval = Kmedian == i;
    R(isval) = ColPal(i,1);
    G(isval) = ColPal(i,2);
    B(isval) = ColPal(i,3);
end

output_img(:,:,1) = R;
output_img(:,:,2) = G;
output_img(:,:,3) = B;

output_img = uint8(output_img);
%imshow(output_img);
SaveName = strcat('normImg','-',ImgName(x,:).name,'.jpg')
imwrite(output_img,SaveName)
end
