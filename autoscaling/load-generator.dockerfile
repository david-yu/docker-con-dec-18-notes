FROM busybox

WORKDIR /app

RUN sh -c "echo -e '#!/bin/sh\n\
while true; do \n\
  wget -q -O- http://php-apache.default.svc.cluster.local \n\
done' >> run.sh"

RUN chmod +x run.sh

CMD ["./run.sh"]
