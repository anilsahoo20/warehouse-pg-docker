# WHPG: on Docker Desktop's "Exec" tab (docker exec -it <c> /bin/sh), bash
# runs under the name "sh" -- an interactive sh-named bash does not read
# ~/.bashrc, it reads the file named by $ENV instead (POSIX sh-compat
# startup rules), which is how this file is reached (see `ENV ENV=...`
# in the Dockerfile). $ENV applies to every user's sh session in the
# container -- not just root's -- so the id-check below is essential:
# without it, gpadmin's own sh session would try to `su - gpadmin` into
# itself and hang the session waiting on a password prompt.
if [ "$(id -u)" = "0" ] && [ -z "$GPADMIN_AUTOHOP" ] && [ -z "$SUDO_USER" ]; then
    case "$-" in
        *i*) GPADMIN_AUTOHOP=1 exec su - gpadmin ;;
    esac
fi
