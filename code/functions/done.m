function done(varargin)

%%
if nargin > 0
    done_str = strjoin(["" varargin{:}]);
else
    done_str = "";
end

fprintf('\nDone%s.\n', done_str)