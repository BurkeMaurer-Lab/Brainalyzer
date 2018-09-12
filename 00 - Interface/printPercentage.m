function printPercentage(done, toDo)

    pctDone = round(done/toDo*1000) / 10;
    md = (mod(pctDone, 1)) * 10;
    pctDone = floor(pctDone);
    outMsg = strcat(sprintf('%g', pctDone), '.', sprintf('%g', md), '%% Complete');
    
    if pctDone >= 100
        cprintf('text', ['\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b', outMsg]);
    elseif pctDone >= 10
        cprintf('text', ['\b\b\b\b\b\b\b\b\b\b\b\b\b\b', outMsg]);
    else
        cprintf('text', ['\b\b\b\b\b\b\b\b\b\b\b\b\b', outMsg]);
    end
end