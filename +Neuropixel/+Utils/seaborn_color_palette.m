function colors = seaborn_color_palette(name)

    sns.deep=["#4C72B0", "#DD8452", "#55A868", "#C44E52", "#8172B3", ...
              "#937860", "#DA8BC3", "#8C8C8C", "#CCB974", "#64B5CD"];
    sns.deep6=["#4C72B0", "#55A868", "#C44E52", ...
           "#8172B3", "#CCB974", "#64B5CD"];
    sns.muted=["#4878D0", "#EE854A", "#6ACC64", "#D65F5F", "#956CB4", ...
           "#8C613C", "#DC7EC0", "#797979", "#D5BB67", "#82C6E2"];
    sns.muted6=["#4878D0", "#6ACC64", "#D65F5F", ...
            "#956CB4", "#D5BB67", "#82C6E2"];
    sns.pastel=["#A1C9F4", "#FFB482", "#8DE5A1", "#FF9F9B", "#D0BBFF", ...
            "#DEBB9B", "#FAB0E4", "#CFCFCF", "#FFFEA3", "#B9F2F0"];
    sns.pastel6=["#A1C9F4", "#8DE5A1", "#FF9F9B", ...
             "#D0BBFF", "#FFFEA3", "#B9F2F0"];
    sns.bright=["#023EFF", "#FF7C00", "#1AC938", "#E8000B", "#8B2BE2", ...
            "#9F4800", "#F14CC1", "#A3A3A3", "#FFC400", "#00D7FF"];
    sns.bright6=["#023EFF", "#1AC938", "#E8000B",...
             "#8B2BE2", "#FFC400", "#00D7FF"];
    sns.dark=["#001C7F", "#B1400D", "#12711C", "#8C0800", "#591E71",...
          "#592F0D", "#A23582", "#3C3C3C", "#B8850A", "#006374"];
    sns.dark6=["#001C7F", "#12711C", "#8C0800",...
           "#591E71", "#B8850A", "#006374"];
    sns.colorblind=["#0173B2", "#DE8F05", "#029E73", "#D55E00", "#CC78BC",...
                "#CA9161", "#FBAFE4", "#949494", "#ECE133", "#56B4E9"];
    sns.colorblind6=["#0173B2", "#029E73", "#D55E00",...
                 "#CC78BC", "#ECE133", "#56B4E9"];

    colors = hex2rgb(sns.(name));
    
end

function colors = hex2rgb(strs)
    colors = zeros(numel(strs), 3);
    for i = 1:numel(strs)
        colors(i, :) = sscanf(strs{i}(2:end),'%2x') / 255;
    end
end