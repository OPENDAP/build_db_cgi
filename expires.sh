#!/bin/sh

cat <<EOF
Expires: Thu, 01 Dec 1994 16:00:00 GMT
Content-Type: text/html

<html>
<head>
<title>An expired document</title>
</head>

<body>
This is an HTML document served up using the CGI mechanism, which contains
an Expires header set to a date in the past. This is used to test the 
HTTP 1.1 (mostly) compliant cache developed for use with the OPeNDAP 
DAP implementation.
</body>
</html>
EOF

