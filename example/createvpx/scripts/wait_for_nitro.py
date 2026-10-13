"""Wait up to ten minutes for both authenticated NITRO APIs."""

import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request


def wait_for_nitro():
    pending = set(json.loads(os.environ["NITRO_ENDPOINTS"]))
    context = ssl.create_default_context()
    if os.environ.get("NITRO_INSECURE") == "true":
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE

    # Do not forward authentication headers through redirects.
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None

    opener = urllib.request.build_opener(
        urllib.request.HTTPSHandler(context=context), NoRedirect()
    )
    deadline = time.monotonic() + 600
    while pending and time.monotonic() < deadline:
        started = time.monotonic()
        for endpoint in sorted(pending):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            request = urllib.request.Request(
                endpoint + "/nitro/v1/config/nsconfig",
                headers={
                    "X-NITRO-USER": os.environ["NITRO_USERNAME"],
                    "X-NITRO-PASS": os.environ["NITRO_PASSWORD"],
                },
            )
            try:
                with opener.open(request, timeout=min(10, remaining)) as response:
                    payload = json.load(response)
                    if response.status == 200 and payload.get("errorcode") == 0 and "nsconfig" in payload:
                        pending.remove(endpoint)
                        print(f"NITRO bereit: {endpoint}", flush=True)
            except (urllib.error.URLError, OSError, ValueError):
                pass
        if pending:
            print("Warte auf NITRO: " + ", ".join(sorted(pending)), flush=True)
            time.sleep(max(0, min(started + 25, deadline) - time.monotonic()))

    if pending:
        print("NITRO nach 600 Sekunden nicht bereit: " + ", ".join(sorted(pending)), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(wait_for_nitro())
