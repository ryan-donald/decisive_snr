% Brendan Hertel, Ryan Donald
% if set to true, then the code will not attempt to automatically align the images. Must be set to false for systems hovering
image_is_stationary = false;

% get image files

img_ext_list = {'*.jpg;*.jpeg;*.png;*.bmp;*.tif'};
[ref_filename, ref_path] = uigetfile(img_ext_list, 'Select the reference image');
if ~ref_filename
   disp('No file selected, cannot continue! Exiting.');
   return;
end
[test_filename, test_path] = uigetfile(img_ext_list, 'Select the test image');
if ~test_filename
   disp('No file selected, cannot continue! Exiting.');
   return;
end

% read in images

ref_img = imread([ref_path ref_filename]);
test_img = imread([test_path test_filename]);

img_size = size(ref_img);
test_img = imresize(test_img, [img_size(1), img_size(2)]);

ref_img_crop = imcrop(ref_img, [0.25*img_size(1), 0.25*img_size(2), 0.75*img_size(1), 0.75*img_size(2)]);
test_img_crop = imcrop(test_img, [0.25*img_size(1), 0.25*img_size(2), 0.75*img_size(1), 0.75*img_size(2)]);

% center images

if(image_is_stationary == false)
    [ref_centers, ref_radii, ref_metric] = imfindcircles(ref_img_crop,[10 50]);
    [test_centers, test_radii, test_metric] = imfindcircles(test_img_crop,[10 50]);

    ref_center = [ref_centers(1,1)+ 1000, ref_centers(1,2) + 1000];
    test_center = [test_centers(1,1) + 1000, test_centers(1,2) + 1000];


    x_diff = uint16(abs(ref_center(1) - test_center(1)));
    y_diff = uint16(abs(ref_center(2) - test_center(2)));
    
    %crop edges so images are aligned
    if (ref_center(2) > test_center(2))
        test_img = test_img(1:end-y_diff, :, :);
        ref_img = ref_img(y_diff+1:end, :, :);
    elseif (ref_center(2) < test_center(2))
        test_img = test_img(y_diff+1:end, :, :);
        ref_img = ref_img(1:end-y_diff, :, :);
    end

    if (ref_center(1) > test_center(1))
        test_img = test_img(:, 1:end-x_diff, :);
        ref_img = ref_img(:, x_diff+1:end, :);
    elseif (ref_center(1) < test_center(1))
        test_img = test_img(:, x_diff+1:end, :);
        ref_img = ref_img(:, 1:end-x_diff, :);
    end
end

both_img = imfuse(ref_img, test_img);
imshow(both_img);

ref_img_gray = rgb2gray(ref_img);
test_img_gray = rgb2gray(test_img);
new_img_size = size(ref_img_gray);

% Measure SNR values
%formulae from: http://bigwww.epfl.ch/sage/soft/snr/

numer_SNR = sum(sum(ref_img_gray.^2));
denom_SNR = sum(sum((ref_img_gray - test_img_gray).^2));

SNR = 10 * log10(numer_SNR / denom_SNR);

numer_PSNR = double(max(max(ref_img_gray))).^2;
denom_PSNR = sum(sum((ref_img_gray - test_img_gray).^2)) / (new_img_size(1) * new_img_size(2));

PSNR = 10 * log10(numer_PSNR / denom_PSNR);

RMSE = sqrt(sum(sum((ref_img_gray - test_img_gray).^2)) / (new_img_size(1) * new_img_size(2)));

MAE = sum(sum(abs(ref_img_gray - test_img_gray))) / (new_img_size(1) * new_img_size(2));

% SSIM Method
% https://ece.uwaterloo.ca/~z70wang/research/ssim/

SSIM = ssim(ref_img, test_img);


% display outputs
disp(['SNR: ' num2str(SNR)]);
disp(['PSNR: ' num2str(PSNR)]);
disp(['RMSE: ' num2str(RMSE)]);
disp(['MAE: ' num2str(MAE)]);
disp(['SSIM: ' num2str(SSIM)]);
