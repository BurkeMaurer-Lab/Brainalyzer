function outMsg = printPercentage(done, toDo, prevMsg)

    pctDone = round(done/toDo*1000) / 10;
    md = (mod(pctDone, 1)) * 10;
    pctDone = floor(pctDone);
    outMsg = strcat(sprintf('%g', pctDone), '.', sprintf('%g', md), '%% Complete');
    cprintf('text', [repmat('\b', 1, (length(prevMsg) - (1 * ~isempty(prevMsg)))), outMsg]);

end