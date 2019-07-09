function writedat(X,fname)

    FF=fopen(fname,'w');
    Y=reshape(X,numel(X),1).*10^6;
    fwrite(FF,Y,'int16');
    fclose(FF);

end