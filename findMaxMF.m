function mfIdx = findMaxMF(x, mfs)
    degrees = arrayfun(@(mf) evalmf(mf, x), mfs);
    [~, mfIdx] = max(degrees);
end

