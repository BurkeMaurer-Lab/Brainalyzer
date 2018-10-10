function writedat(X,fname)

    FF=fopen(fname,'w');
    Y=reshape(X,size(X,1)*size(X,2),1).*10^6;
    fwrite(FF,Y,'int16');
    fclose(FF);

end