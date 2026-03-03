function outputCfgAsJson(fn, outDir, cfg)
jsonStr = jsonencode(cfg);

fid = fopen(fullfile(outDir, fn), 'w');
fwrite(fid, jsonStr, 'char');
fclose(fid);

end