function [after_Img, seq] = make_gabor_img(cond_level, contRange, contChange, tt)
    contLevel= logspace(log10(contRange(1)), ...
        log10(contRange(2)), cond_level-1);
    contLevel(1,cond_level) = contLevel(end);
    after_Img =[];
    for i = 1 : cond_level
        c = contLevel(i) ;     % contrast of the Gabor
        f = 1/29;            % spatial frequency in 1/pixels (= 1 cpd)
        t = pi/180;          % tilt of 0 degrees into radians (=vertical)
        s = 20; %24;              % standard deviation of the spatial
        % window of the Gabor
        g_size = 112;        % calculated to be 3 degrees  % It used to be 256.
        [x,  y] = meshgrid(-(g_size*1/2):(g_size*1/2-1), (g_size*1/2):-1:-(g_size*1/2-1));
        M2 = uint8(127*(1+ c*sin(2.0*pi*f*(y*sin(t) + x*cos(t))) ...
            .*exp(-(x.^2 + y.^2)/2/s^2)));

        after_Img{i,1} = M2;
    end
    seq =[];
    for cc= 1:contChange(tt)
        if rem(cc,2) == 1
            seq = [seq 1:1:cond_level];
        else
            seq = [seq cond_level:-1:1];
        end
    end
end