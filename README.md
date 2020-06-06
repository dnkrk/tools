# Tools
Some assorted Bash and Linux tools


## Download.bash
This script divides a download into multiple concurrent chunks and downloads
them all at once, concatenating them at the end. When used correctly, can be
used to get around throttling and rate caps. It will only work on HTTP and FTP
servers which support the "Range" header.

**Normal download**:    13GB file with a server-side cap at 80KB/s, ETA 47h20m.
**This script**:        27m to download and concat 1322 10MB chunks: 105 times faster.

Don't forget to donate or otherwise support the server you're pulling stuff
from, after all, those caps are there for a reason.

### Usage
    ./download.bash url

#### Note
For especially large files, some chunks may fail to download and the separate
wget calls will start to hang after every 10GB or so. Feel free to kill the
script with ^C and run it again - fully downloaded chunks will not be touched,
so very little progress will be lost. A future version should allow resuming
partially downloaded chunks as well.
