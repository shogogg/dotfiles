function aiff2aac
  for aiff in (fd -e aiff)
    set -l aac (echo "$aiff" | sed '$s/\.aiff$/.m4a/')
    ffmpeg -i "$aiff" -b:a 256k -aac_coder twoloop "$aac"
  end
end
