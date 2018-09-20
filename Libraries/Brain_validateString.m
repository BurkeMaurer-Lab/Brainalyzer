%Altered version of "validatestring" that catches the error if the user
%inputs something that isn't allowed and keeps asking them until they enter
%an allowed input.

function userAns = Brain_validateString(prompt, posStr)

    prompt = char(prompt);
    posStr = string(posStr);
    while 1
        userAns = input(prompt, 's');
        try 
            userAns = validatestring(userAns, posStr);
            break;
        catch
            cprintf('*err', '\nERROR: INVALID INPUT.\nACCEPTABLE INPUTS ARE:');
            for strIdx = 1:length(posStr)
                cprintf('*err', ['\n\t', num2str(strIdx), ') ', posStr{strIdx}]);
            end
            cprintf('*err', '\nPLEASE TRY AGAIN\n');
        end
    end
end